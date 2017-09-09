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
  
  weak var delegate: ManageAppearance?
  
  var messagesDictionary = [String: (Message, User, ChatMetaData)]()
  
  var userIDs = [String]()
  
  var finalUserCellData = Array<(Message, User, ChatMetaData)>()
  
  fileprivate var connectedRef: DatabaseReference!
  fileprivate var currentUserConversationsReference: DatabaseReference!
  fileprivate var lastMessageForConverstaionRef: DatabaseReference!
  fileprivate var messagesReference: DatabaseReference!
  fileprivate var metadataRef: DatabaseReference!
  fileprivate var usersRef: DatabaseReference!

  
  override func viewDidLoad() {
      super.viewDidLoad()
    
    configureTableView()
    managePresense()
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    print("\n chatsController will appear \n")
    self.fetchConversations()
  }
  
  
  override func viewDidAppear(_ animated: Bool) {
    
    if let testSelected = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: testSelected, animated: true)
    }
    super.viewDidAppear(animated)
  }
  
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    print("\n chatsController did dissapear \n")
    
//    if currentUserConversationsReference != nil {
//      currentUserConversationsReference.removeAllObservers()
//    }
//    
//    if lastMessageForConverstaionRef != nil {
//      lastMessageForConverstaionRef.removeAllObservers()
//    }
//    
//    if messagesReference != nil {
//      messagesReference.removeAllObservers()
//    }
//    
//    if metadataRef != nil {
//      metadataRef.removeAllObservers()
//    }
//    
//    if usersRef != nil {
//      usersRef.removeAllObservers()
//    }
  }
  
  
  fileprivate func configureTableView() {
    
    tableView.register(UserCell.self, forCellReuseIdentifier: userCellID)
    tableView.allowsMultipleSelectionDuringEditing = false
    tableView.backgroundColor = UIColor.white
    navigationItem.leftBarButtonItem = editButtonItem
  }

  
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
  
  
  func convigureTabBarBadge() {
    
    guard let uid = Auth.auth().currentUser?.uid else {
      return
    }
    
    let tabItems = self.tabBarController?.tabBar.items as NSArray!
    
    var badge = 0

    for meta in finalUserCellData {
   
      let tabItem = tabItems?[tabs.chats.rawValue] as! UITabBarItem
      
      if meta.0.fromId != uid {
        
        badge += meta.2.badge!
        
        if badge <= 0 {
          tabItem.badgeValue = nil
        } else {
          tabItem.badgeValue = badge.toString()
        }
      }
    }
  }
  
  
  fileprivate var userConversations = 0
  
  func fetchConversations() {
    
    userConversations = 0
  
    guard let uid = Auth.auth().currentUser?.uid else {
      return
    }
    
    currentUserConversationsReference = Database.database().reference().child("user-messages").child(uid)
    currentUserConversationsReference.keepSynced(true)
    currentUserConversationsReference.observe(.childAdded, with: { (snapshot) in
      
      let otherUserID = snapshot.key
      
      for snap in snapshot.children.allObjects as! [DataSnapshot] {
        if snap.key == userMessagesFirebaseFolder {
         
           self.userConversations += 1
        }
      }

      self.lastMessageForConverstaionRef = Database.database().reference().child("user-messages").child(uid).child(otherUserID).child(userMessagesFirebaseFolder)
      self.lastMessageForConverstaionRef.keepSynced(true)
      self.lastMessageForConverstaionRef.queryLimited(toLast: 1).observe(.childAdded, with: { (snapshot) in
        
        let lastMessageID = snapshot.key
        self.fetchMessageWithMessageId(lastMessageID)
      })
    })
    
    currentUserConversationsReference.observe(.childRemoved, with: { (snapshot) in
      print(snapshot.key)
      print(self.messagesDictionary)
      
      self.messagesDictionary.removeValue(forKey: snapshot.key)
      self.handleReloadTable()
      
    }, withCancel: nil)
  }
  
  
  func fetchMessageWithMessageId(_ messageId: String) {
    
    messagesReference = Database.database().reference().child("messages").child(messageId)
    messagesReference.keepSynced(true)
    messagesReference.observe( .value, with: { (snapshot) in
      
      if let dictionary = snapshot.value as? [String: AnyObject] {
        
        let message = Message(dictionary: dictionary)
        
        if let chatPartnerId = message.chatPartnerId() {
          
          guard let uid = Auth.auth().currentUser?.uid else {
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
        }
      }
    }, withCancel: nil)
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
        
      self.messagesDictionary[userID]  = (message, user, meta)
        
      self.userIDs = self.messagesDictionary.keys.sorted()
        
      if self.userIDs.count == self.userConversations {
          
        self.handleReloadTable()
      }
     
    }, withCancel: { (error) in
      print("\n", error.localizedDescription, "error\n")
    })
  }
  
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
    guard let uid = Auth.auth().currentUser?.uid  else {
      return
    }
      
      let message = self.finalUserCellData[indexPath.row]
      
      if let chatPartnerId = message.0.chatPartnerId() {
        Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).child(userMessagesFirebaseFolder).removeValue(completionBlock: { (error, ref) in
          
          if error != nil {
            print("Failed to delete message:", error as Any)
            return
          }
          
          self.messagesDictionary.removeValue(forKey: chatPartnerId)
          self.handleReloadTable()
          
        })
      }
  }
  
 
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 80
    }

  
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userIDs.count
    }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as! UserCell

      cell.nameLabel.text = finalUserCellData[indexPath.row].1.name
      if (finalUserCellData[indexPath.row].0.imageUrl != nil || finalUserCellData[indexPath.row].0.localImage != nil) && finalUserCellData[indexPath.row].0.videoUrl == nil  {
        cell.messageLabel.text = "Attachment: Image"
      } else if (finalUserCellData[indexPath.row].0.imageUrl != nil || finalUserCellData[indexPath.row].0.localImage != nil) && finalUserCellData[indexPath.row].0.videoUrl != nil {
        cell.messageLabel.text = "Attachment: Video"
      } else {
         cell.messageLabel.text = finalUserCellData[indexPath.row].0.text
      }
    
      cell.timeLabel.text = finalUserCellData[indexPath.row].0.timestamp?.doubleValue.getShortDateStringFromUTC()
      
        if let url = self.finalUserCellData[indexPath.row].1.thumbnailPhotoURL {
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
      
      
      if finalUserCellData[indexPath.row].0.seen != nil {
        
        let seen = finalUserCellData[indexPath.row].0.seen!
        
        if !seen && finalUserCellData[indexPath.row].0.fromId != Auth.auth().currentUser?.uid {
          
          cell.newMessageIndicator.isHidden = false
          cell.badgeLabel.text = finalUserCellData[indexPath.row].2.badge?.toString()
          
          if Int(cell.badgeLabel.text!)! > 0 {
            cell.badgeLabel.isHidden = false
          } else {
            cell.badgeLabel.text = "1"
            cell.badgeLabel.isHidden = false
          }
          
          
        } else {
          
          cell.newMessageIndicator.isHidden = true
          cell.badgeLabel.isHidden = true
          cell.badgeLabel.text = finalUserCellData[indexPath.row].2.badge?.toString()
        }
        
      } else {
        
         cell.newMessageIndicator.isHidden = true
         cell.badgeLabel.isHidden = true
         cell.badgeLabel.text = finalUserCellData[indexPath.row].2.badge?.toString()
      }
    
        return cell
    }
  
  
  var chatLogController: ChatLogController? = nil
  
  var autoSizingCollectionViewFlowLayout: AutoSizingCollectionViewFlowLayout? = nil
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
    let user = finalUserCellData[indexPath.row].1
    autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
    autoSizingCollectionViewFlowLayout?.minimumLineSpacing = 5
    chatLogController = ChatLogController(collectionViewLayout: autoSizingCollectionViewFlowLayout!)
    chatLogController?.delegate = self
    chatLogController?.user = user
    chatLogController?.hidesBottomBarWhenPushed = true
  }
  
  
  fileprivate var appIsLoaded = false
  
  func handleReloadTable() {
    
    finalUserCellData = Array(self.messagesDictionary.values)
    
    finalUserCellData.sort { (dic1: (Message, User, ChatMetaData), dic2: (Message, User, ChatMetaData)) -> Bool in
      return dic1.0.timestamp?.int32Value > dic2.0.timestamp?.int32Value
    }
    
    DispatchQueue.main.async(execute: {
          self.convigureTabBarBadge()
          self.tableView.reloadData()
    })
    
    if !appIsLoaded {
       self.delegate?.manageAppearance(self, didFinishLoadingWith: true)
       appIsLoaded = true
    }
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
    
    self.chatLogController?.startCollectionViewAtBottom()
  
    if let destination = self.chatLogController {
      navigationController?.pushViewController( destination, animated: true)
      self.chatLogController = nil
      self.autoSizingCollectionViewFlowLayout = nil
    }
  }
}
