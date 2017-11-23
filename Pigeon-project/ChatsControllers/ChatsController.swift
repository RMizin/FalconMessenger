//
//  ChatsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage


fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


private let userCellID = "userCellID"

protocol ManageAppearance: class {
  func manageAppearance(_ chatsController: ChatsController, didFinishLoadingWith state: Bool )
}


class ChatsController: UITableViewController {
  
  var searchBar: UISearchBar?
  var searchChatsController: UISearchController?
  
  weak var delegate: ManageAppearance?
  
  var messagesDictionary = [String: (Message, User, ChatMetaData?)]()
  var filteredMessagesDictionary = [String: (Message, User, ChatMetaData?)]()
  var finalUserCellData = Array<(Message, User, ChatMetaData?)>()
  var filteredFinalUserCellData = Array<(Message, User, ChatMetaData?)>()
  
  fileprivate var connectedRef: DatabaseReference!
  fileprivate var currentUserConversationsReference: DatabaseReference!
  fileprivate var lastMessageForConverstaionRef: DatabaseReference!
  fileprivate var messagesReference: DatabaseReference!
  fileprivate var metadataRef: DatabaseReference!
  fileprivate var usersRef: DatabaseReference!

  private let group = DispatchGroup()
  private var isAppLoaded = false
  private var isGroupAlreadyFinished = false

  
  override func viewDidLoad() {
      super.viewDidLoad()
    
    configureTableView()
    managePresense()
    setupSearchController()
    fetchConversations()
    
    NotificationCenter.default.addObserver(self, selector:#selector(fetchConversations),name:NSNotification.Name(rawValue: "reloadUserConversations"), object: nil)
    NotificationCenter.default.addObserver(self, selector:#selector(clearConversations),name:NSNotification.Name(rawValue: "clearConversations"), object: nil)
  }
  
  
  override func viewDidAppear(_ animated: Bool) {
    if let testSelected = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: testSelected, animated: true)
    }
    super.viewDidAppear(animated)
  }
  
  
  fileprivate func configureTableView() {
    
    tableView.register(UserCell.self, forCellReuseIdentifier: userCellID)
    tableView.allowsMultipleSelectionDuringEditing = false
    tableView.backgroundColor = UIColor.white
    navigationItem.leftBarButtonItem = editButtonItem
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    tableView.separatorStyle = .none
  }
  
  fileprivate func setupSearchController() {
        
      if #available(iOS 11.0, *) {
        searchChatsController = UISearchController(searchResultsController: nil)
        searchChatsController?.searchResultsUpdater = self
        searchChatsController?.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchChatsController?.searchBar.delegate = self
        navigationItem.searchController = searchChatsController
      } else {
        searchBar = UISearchBar()
        searchBar?.delegate = self
        searchBar?.searchBarStyle = .minimal
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        tableView.tableHeaderView = searchBar
      }
  }
  
  fileprivate func checkIfThereAnyActiveChats(isEmpty: Bool) {
    
    if isEmpty {
      let noChatsYesContainer:NoChatsYetContainer! = NoChatsYetContainer()
      
      self.view.addSubview(noChatsYesContainer)
      noChatsYesContainer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
      
    } else {
      for subview in self.view.subviews {
        if subview is NoChatsYetContainer {
          subview.removeFromSuperview()
        }
      }
    }
  }
  
  fileprivate func configureTabBarBadge() {
    
    guard let uid = Auth.auth().currentUser?.uid else {
      return
    }
    
    let tabItems = self.tabBarController?.tabBar.items as NSArray!
    let tabItem = tabItems?[tabs.chats.rawValue] as! UITabBarItem
    var badge = 0
    
    for meta in filteredFinalUserCellData {
      if meta.0.seen != nil && !meta.0.seen! &&  meta.0.fromId != uid {
        badge += 1
        tabItem.badgeValue = badge.toString()
        UIApplication.shared.applicationIconBadgeNumber = badge
      }
    }
    
    if badge <= 0 {
      tabItem.badgeValue = nil
      UIApplication.shared.applicationIconBadgeNumber = 0
    }
  }

  
  func managePresense() {
    
    if currentReachabilityStatus == .notReachable {
      showActivityIndicator(title: "Connecting...")
    }
    
    connectedRef = Database.database().reference(withPath: ".info/connected")
    connectedRef.observe(.value, with: { (snapshot) in
   
      if self.currentReachabilityStatus != .notReachable {
         self.hideActivityIndicator()
      } else {
        self.showActivityIndicator(title: "No internet connection...")
      }
      
    }) { (error) in
        print(error.localizedDescription)
    }
  }
  
  @objc func clearConversations() {

    messagesDictionary.removeAll()
    filteredMessagesDictionary.removeAll()
    finalUserCellData.removeAll()
    filteredFinalUserCellData.removeAll()
    
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
  
 @objc func fetchConversations() {
    
    guard let uid = Auth.auth().currentUser?.uid else {
      return
    }
  
    currentUserConversationsReference = Database.database().reference().child("user-messages").child(uid)
    currentUserConversationsReference.keepSynced(true)
    currentUserConversationsReference.observeSingleEvent(of: .value) { (snapshot) in
      
      for _ in 0 ..< snapshot.childrenCount {
        self.group.enter()
      }
      
      self.group.notify(queue: DispatchQueue.main, execute: {
        self.handleReloadTable()
        self.isGroupAlreadyFinished = true
       
      })
      
      if !snapshot.exists() {
        self.handleReloadTable()
        return
      }
    }
    
    currentUserConversationsReference.observe(.childAdded, with: { (snapshot) in
  
        let otherUserID = snapshot.key
        
        self.lastMessageForConverstaionRef = Database.database().reference().child("user-messages").child(uid).child(otherUserID).child(userMessagesFirebaseFolder)
        self.lastMessageForConverstaionRef.keepSynced(true)
        self.lastMessageForConverstaionRef.queryLimited(toLast: 1).observe(.childAdded, with: { (snapshot) in
          
          let lastMessageID = snapshot.key
          self.fetchMessageWithMessageId(lastMessageID)
        })
    })
    
    currentUserConversationsReference.observe(.childRemoved, with: { (snapshot) in
      
      self.messagesDictionary.removeValue(forKey: snapshot.key)
      self.handleReloadTable()
    })
  }
  
  func fetchMessageWithMessageId(_ messageId: String) {
    
    messagesReference = Database.database().reference().child("messages").child(messageId)
    messagesReference.keepSynced(true)
    messagesReference.observe( .value, with: { (snapshot) in
      
      guard let dictionary = snapshot.value as? [String: AnyObject] else {
        return
      }

      let message = Message(dictionary: dictionary)
      
      guard let chatPartnerId = message.chatPartnerId(), let uid = Auth.auth().currentUser?.uid else  {
        return
      }
      
      self.metadataRef = Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).child(messageMetaDataFirebaseFolder)
      self.metadataRef.keepSynced(true)
      self.metadataRef.removeAllObservers()
      self.metadataRef.observe( .value, with: { (snapshot) in
            
        guard let metaDictionary = snapshot.value as? [String: Int] else {
          return
        }
            
        self.fetchUserDataWithUserID(chatPartnerId, for: message, metaData: metaDictionary)
      })
    })
  }
  
  func fetchUserDataWithUserID(_ userID: String, for message: Message, metaData: [String: Int]) {
    
    usersRef = Database.database().reference().child("users").child(userID)
    usersRef.keepSynced(true)
    usersRef.observe(.value, with: { (snapshot) in
      
      guard var dictionary = snapshot.value as? [String: AnyObject] else {
        return
      }
    
      dictionary.updateValue(userID as AnyObject, forKey: "id")
      
      let user = User(dictionary: dictionary)
      let meta = ChatMetaData(dictionary: metaData)
      self.messagesDictionary[userID] = (message, user, meta)
      
      if self.isGroupAlreadyFinished {
        self.handleReloadTable()
      } else {
        self.group.leave()
      }
    })
  }
  
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
    guard let uid = Auth.auth().currentUser?.uid  else {
      return
    }
    
    if currentReachabilityStatus == .notReachable {
      return
    }
    
    if (editingStyle == UITableViewCellEditingStyle.delete) {
      
      let message = self.filteredFinalUserCellData[indexPath.row]
      
      if let chatPartnerId = message.0.chatPartnerId() {
        
        self.tableView.beginUpdates()
        
        self.filteredMessagesDictionary.removeValue(forKey: chatPartnerId)
        self.filteredFinalUserCellData = Array(self.filteredMessagesDictionary.values)
        
        self.tableView.deleteRows(at: [indexPath], with: .left)
        self.tableView.endUpdates()
        
        Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue()
      }
    }
  }
  
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 85
    }
  
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMessagesDictionary.count
    }
  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as! UserCell
  
      cell.nameLabel.text = filteredFinalUserCellData[indexPath.row].1.name
      if (filteredFinalUserCellData[indexPath.row].0.imageUrl != nil || filteredFinalUserCellData[indexPath.row].0.localImage != nil) && filteredFinalUserCellData[indexPath.row].0.videoUrl == nil  {
        cell.messageLabel.text = "Attachment: Image"
      } else if (filteredFinalUserCellData[indexPath.row].0.imageUrl != nil || filteredFinalUserCellData[indexPath.row].0.localImage != nil) && filteredFinalUserCellData[indexPath.row].0.videoUrl != nil {
        cell.messageLabel.text = "Attachment: Video"
      } else {
         cell.messageLabel.text = filteredFinalUserCellData[indexPath.row].0.text
      }
    
      let date = NSDate(timeIntervalSince1970:  filteredFinalUserCellData[indexPath.row].0.timestamp as! TimeInterval)
      cell.timeLabel.text = timeAgoSinceDate(date: date, timeinterval: filteredFinalUserCellData[indexPath.row].0.timestamp!.doubleValue, numericDates: false)
    
        if let url = self.filteredFinalUserCellData[indexPath.row].1.thumbnailPhotoURL {
          cell.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "UserpicIcon"), options: [.continueInBackground, .progressiveDownload], completed: { (image, error, cacheType, url) in
            if image != nil {
              if (cacheType != SDImageCacheType.memory && cacheType != SDImageCacheType.disk) {
                cell.profileImageView.alpha = 0
                UIView.animate(withDuration: 0.25, animations: {
                  cell.profileImageView.alpha = 1
                })
              } else {
                cell.profileImageView.alpha = 1
              }
            }
          })
        }
      
      if filteredFinalUserCellData[indexPath.row].0.seen != nil {
        
        let seen = filteredFinalUserCellData[indexPath.row].0.seen!
        
        if !seen && filteredFinalUserCellData[indexPath.row].0.fromId != Auth.auth().currentUser?.uid {
          
          cell.newMessageIndicator.isHidden = false
          cell.badgeLabel.text = filteredFinalUserCellData[indexPath.row].2?.badge?.toString()
          
          if Int(cell.badgeLabel.text!)! > 0 {
            cell.badgeLabel.isHidden = false
          } else {
            cell.badgeLabel.text = "1"
            cell.badgeLabel.isHidden = false
          }
          
        } else {
          
          cell.newMessageIndicator.isHidden = true
          cell.badgeLabel.isHidden = true
          cell.badgeLabel.text = filteredFinalUserCellData[indexPath.row].2?.badge?.toString()
        }
        
      } else {
        
         cell.newMessageIndicator.isHidden = true
         cell.badgeLabel.isHidden = true
         cell.badgeLabel.text = filteredFinalUserCellData[indexPath.row].2?.badge?.toString()
      }
    
        return cell
    }
  
  
  var chatLogController: ChatLogController? = nil
  
  var autoSizingCollectionViewFlowLayout: AutoSizingCollectionViewFlowLayout? = nil
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
    let user = filteredFinalUserCellData[indexPath.row].1
    autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
    autoSizingCollectionViewFlowLayout?.minimumLineSpacing = 5
    chatLogController = ChatLogController(collectionViewLayout: autoSizingCollectionViewFlowLayout!)
    chatLogController?.delegate = self
    chatLogController?.user = user
    chatLogController?.hidesBottomBarWhenPushed = true
  }
  
  
  func handleReloadTable() {

    filteredMessagesDictionary = messagesDictionary
    finalUserCellData = Array(self.filteredMessagesDictionary.values)
    finalUserCellData.sort { (dic1: (Message, User, ChatMetaData?), dic2: (Message, User, ChatMetaData?)) -> Bool in
      return dic1.0.timestamp?.int32Value > dic2.0.timestamp?.int32Value
    }
  
    filteredFinalUserCellData = finalUserCellData
    tableView.reloadData()
   
    if self.filteredFinalUserCellData.count == 0 {
      self.checkIfThereAnyActiveChats(isEmpty: true)
    } else {
      self.checkIfThereAnyActiveChats(isEmpty: false)
    }
    
    configureTabBarBadge()
    
    if !isAppLoaded {
      self.delegate?.manageAppearance(self, didFinishLoadingWith: true)
      isAppLoaded = true
    }
  }
  
  func handleReloadTableAfterSearch() {
    
    finalUserCellData = Array(self.filteredMessagesDictionary.values)
    finalUserCellData.sort { (dic1: (Message, User, ChatMetaData?), dic2: (Message, User, ChatMetaData?)) -> Bool in
      return dic1.0.timestamp?.int32Value > dic2.0.timestamp?.int32Value
    }
    
    filteredFinalUserCellData = finalUserCellData
    tableView.reloadData()
  }
  
}


extension ChatsController: MessagesLoaderDelegate {
  
  func messagesLoader( didFinishLoadingWith messages: [Message]) {
    
    self.chatLogController?.messages = messages
    
    var indexPaths = [IndexPath]()
    
    if messages.count - 1 >= 0 {
      for index in 0...messages.count - 1 {
        
        indexPaths.append(IndexPath(item: index, section: 0))
      }
      
      UIView.performWithoutAnimation {
        DispatchQueue.main.async {
          self.chatLogController?.collectionView?.reloadItems(at:indexPaths)
        }
      }
    }
    
    if #available(iOS 11.0, *) {
    } else {
       self.chatLogController?.startCollectionViewAtBottom()
    }
    if let destination = self.chatLogController {
      navigationController?.pushViewController( destination, animated: true)
      self.chatLogController = nil
      self.autoSizingCollectionViewFlowLayout = nil
    }
  }
}

extension ChatsController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
  
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.text = nil
        filteredMessagesDictionary = messagesDictionary
        handleReloadTable()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filteredMessagesDictionary = searchText.isEmpty ? messagesDictionary : messagesDictionary.filter({ (key, value) -> Bool in
          return  value.1.name!.lowercased().contains(searchText.lowercased())
        })
        
        handleReloadTableAfterSearch()
    }
}

extension ChatsController { /* hiding keyboard */
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchChatsController?.resignFirstResponder()
            searchChatsController?.searchBar.resignFirstResponder()
        } else {
            searchBar?.resignFirstResponder()
        }
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if #available(iOS 11.0, *) {
            searchChatsController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}

extension ChatsController { /* activity indicator handling */
  func showActivityIndicator(title: String) {
    
    let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    activityIndicatorView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
    activityIndicatorView.color = UIColor.black
    activityIndicatorView.startAnimating()
    
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = UIFont.systemFont(ofSize: 14)
    
    let fittingSize = titleLabel.sizeThatFits(CGSize(width:200.0, height: activityIndicatorView.frame.size.height))
    titleLabel.frame = CGRect(x: activityIndicatorView.frame.origin.x + activityIndicatorView.frame.size.width + 8, y: activityIndicatorView.frame.origin.y, width: fittingSize.width, height: fittingSize.height)
    
    let titleView = UIView(frame: CGRect(  x: (( activityIndicatorView.frame.size.width + 8 + titleLabel.frame.size.width) / 2), y: ((activityIndicatorView.frame.size.height) / 2), width:(activityIndicatorView.frame.size.width + 8 + titleLabel.frame.size.width), height: ( activityIndicatorView.frame.size.height)))
    titleView.addSubview(activityIndicatorView)
    titleView.addSubview(titleLabel)
    
    self.navigationItem.titleView = titleView
  }
  
  func hideActivityIndicator() {
    self.navigationItem.titleView = nil
  }
}
