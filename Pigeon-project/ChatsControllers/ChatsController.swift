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

public var shouldReloadChatsControllerAfterChangingTheme = false


class ChatsController: UITableViewController {
  
  var searchBar: UISearchBar?
  
  var searchChatsController: UISearchController?
  
  weak var delegate: ManageAppearance?
  
  var conversations = [Conversation]()
  
  var filtededConversations = [Conversation]()
  
  var pinnedConversations = [Conversation]()
  
  var filteredPinnedConversations = [Conversation]()
  
  fileprivate var connectedRef: DatabaseReference!
  fileprivate var currentUserConversationsReference: DatabaseReference!
  fileprivate var lastMessageForConverstaionRef: DatabaseReference!
  fileprivate var messagesReference: DatabaseReference!
  fileprivate var metadataRef: DatabaseReference!
  fileprivate var usersRef: DatabaseReference!

  private let group = DispatchGroup()
  private var isGroupAlreadyFinished = false
  var isAppLoaded = false
  var isAppJustDidBecomeActive = false
  var unhandledNewMessages = 0
  
  let noChatsYetContainer:NoChatsYetContainer! = NoChatsYetContainer()

  
  override func viewDidLoad() {
      super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
    configureTableView()
    setupSearchController()
  }
  
  @objc func applicationDidBecomeActive() {
    if isAppLoaded {
      self.isAppJustDidBecomeActive = true
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    if let testSelected = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: testSelected, animated: true)
    }
    super.viewDidAppear(animated)
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
     noChatsYetContainer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
     noChatsYetContainer.layoutIfNeeded()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if !isAppLoaded {
      fetchConversations()
    }
  
    setUpColorsAccordingToTheme()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }
  
  fileprivate func setUpColorsAccordingToTheme() {
    if shouldReloadChatsControllerAfterChangingTheme {
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
      tableView.sectionIndexBackgroundColor = view.backgroundColor
      tableView.backgroundColor = view.backgroundColor
      tableView.reloadData()
      shouldReloadChatsControllerAfterChangingTheme = false
    }
  }
  
  fileprivate func configureTableView() {
    
    tableView.register(UserCell.self, forCellReuseIdentifier: userCellID)
    tableView.allowsMultipleSelectionDuringEditing = false
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.backgroundColor = view.backgroundColor
    navigationItem.leftBarButtonItem = editButtonItem
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    tableView.separatorStyle = .none
    definesPresentationContext = true
  }
  
  fileprivate func setupSearchController() {
        
      if #available(iOS 11.0, *) {
        searchChatsController = UISearchController(searchResultsController: nil)
        searchChatsController?.searchResultsUpdater = self
        searchChatsController?.obscuresBackgroundDuringPresentation = false
        searchChatsController?.searchBar.delegate = self
        searchChatsController?.definesPresentationContext = true
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
      self.view.addSubview(noChatsYetContainer)
      noChatsYetContainer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
      
    } else {
      for subview in self.view.subviews {
        if subview is NoChatsYetContainer {
          subview.removeFromSuperview()
        }
      }
    }
  }
  
  fileprivate func configureTabBarBadge() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    let tabItems = self.tabBarController?.tabBar.items as NSArray!
    let tabItem = tabItems?[tabs.chats.rawValue] as! UITabBarItem
    var badge = 0
    
    for meta in filtededConversations {
      if meta.message?.seen != nil && !meta.message!.seen! &&  meta.message!.fromId != uid {
        badge += 1
        tabItem.badgeValue = badge.toString()
        UIApplication.shared.applicationIconBadgeNumber = badge
      }
    }
    
    for meta in filteredPinnedConversations {
      if meta.message?.seen != nil && !meta.message!.seen! &&  meta.message!.fromId != uid {
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
  
  private var isFirstRemoteUpdateRequested = false
  fileprivate func handleActivityIndicatorAppearance() {
    if self.isAppLoaded {
      if !self.isFirstRemoteUpdateRequested {
        self.showActivityIndicator(title: ChatsController.updatingMessage)
        self.isFirstRemoteUpdateRequested = true
      }
    } else {
      self.showActivityIndicator(title: ChatsController.updatingMessage)
    }
  }
  
@objc func fetchConversations() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
  
    currentUserConversationsReference = Database.database().reference().child("user-messages").child(uid)
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
        self.hideActivityIndicator()
        return
      }
    }

    currentUserConversationsReference.observe(.childAdded, with: { (snapshot) in
     
        let otherUserID = snapshot.key
        self.lastMessageForConverstaionRef = Database.database().reference().child("user-messages").child(uid).child(otherUserID).child(userMessagesFirebaseFolder)
        self.lastMessageForConverstaionRef.queryLimited(toLast: 1).observe(.value, with: { (snapshot) in

          guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
          guard let lastMessageID = dictionary.keys.first else { return }
          self.handleActivityIndicatorAppearance()
          self.unhandledNewMessages += 1
          self.fetchMessageWith(lastMessageID)
        })
    })
  
    currentUserConversationsReference.observe(.childRemoved) { (snapshot) in
      self.hideActivityIndicator()
    }
  }
  
  func fetchMessageWith(_ messageID: String) {
    
    messagesReference = Database.database().reference().child("messages").child(messageID)
    messagesReference.observe( .value, with: { (snapshot) in
      
      guard var dictionary = snapshot.value as? [String: AnyObject], let uid = Auth.auth().currentUser?.uid else { return }
      dictionary.updateValue(messageID as AnyObject, forKey: "messageUID")
    
      let message = Message(dictionary: dictionary)
      guard let chatPartnerID = message.chatPartnerId() else { return }
      
      self.unhandledNewMessages -= 1
      self.handleInAppSoundPlaying(message, for: self.unhandledNewMessages)
      
      self.metadataRef = Database.database().reference().child("user-messages").child(uid).child(chatPartnerID).child(messageMetaDataFirebaseFolder)
      self.metadataRef.removeAllObservers()
      self.metadataRef.observe( .value, with: { (snapshot) in
        
        guard let metaDictionary = snapshot.value as? [String: AnyObject] else { return }
        let meta = ChatMetaData(dictionary: metaDictionary)
        self.fetchUserData(for: message, with: meta)
      })
    })
  }
  
  func fetchUserData(for message: Message, with metaData: ChatMetaData?) {
    
    guard let chatPartnerID = message.chatPartnerId() else { return }
    
    usersRef = Database.database().reference().child("users").child(chatPartnerID)
    usersRef.observeSingleEvent(of: .value, with: { (snapshot) in
      
      guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
      dictionary.updateValue(chatPartnerID as AnyObject, forKey: "id")
      
      let user = User(dictionary: dictionary)
      let conv = Conversation(message: message, user: user, chatMetaData: metaData)
      
      if let unpinnedIndex = self.conversations.index(where: { (conversation) -> Bool in
        return conversation.user?.id == chatPartnerID }) {
        
        self.conversations[unpinnedIndex] = conv
        self.handleGroupOrReloadTable()
        
      } else if let pinnedIndex = self.pinnedConversations.index(where: { (conversation) -> Bool in
        return conversation.user?.id == chatPartnerID }) {
        
        self.pinnedConversations[pinnedIndex] = conv
        self.handleGroupOrReloadTable()
        
      } else {
        if metaData?.pinned != nil && metaData!.pinned! {
          self.pinnedConversations.append(conv)
        } else {
          self.conversations.append(conv)
        }
        self.handleGroupOrReloadTable()
      }
    })
  
    usersRef.observe(.childChanged) { (snapshot) in
      
      if let unpinnedIndex = self.filtededConversations.index(where: { (conversation) -> Bool in
        return conversation.user?.id == chatPartnerID }) {
        
        if snapshot.key == "name" {
          self.filtededConversations[unpinnedIndex].user?.name = snapshot.value as? String
          self.handleGroupOrReloadTable()
        } else if snapshot.key == "thumbnailPhotoURL" {
          self.filtededConversations[unpinnedIndex].user?.thumbnailPhotoURL = snapshot.value as? String
          self.handleGroupOrReloadTable()
        } else {
          return
        }
      } else if let pinnedIndex = self.filteredPinnedConversations.index(where: { (conversation) -> Bool in
        return conversation.user?.id == chatPartnerID }) {
        
        if snapshot.key == "name" {
          self.filteredPinnedConversations[pinnedIndex].user?.name = snapshot.value as? String
          self.handleGroupOrReloadTable()
        } else if snapshot.key == "thumbnailPhotoURL" {
          self.filteredPinnedConversations[pinnedIndex].user?.thumbnailPhotoURL = snapshot.value as? String
          self.handleGroupOrReloadTable()
        } else {
          return
        }
      } else {
        return
      }
    }
  }

  fileprivate func handleGroupOrReloadTable() {
    if self.isGroupAlreadyFinished {
      self.handleReloadTable()
    } else {
      self.group.leave()
    }
  }
  
  func handleReloadTable() {
    
    conversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    }
    
    pinnedConversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    }
    
    filteredPinnedConversations = pinnedConversations
    filtededConversations = conversations
    
    if !isAppLoaded {
      UIView.transition(with: tableView, duration: 0.25, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
    } else {
      self.tableView.reloadData()
    }
    
    if filtededConversations.count == 0 && filteredPinnedConversations.count == 0 {
      checkIfThereAnyActiveChats(isEmpty: true)
    } else {
      checkIfThereAnyActiveChats(isEmpty: false)
    }
    
    self.configureTabBarBadge()

    if !isAppLoaded {
      hideActivityIndicator()
      delegate?.manageAppearance(self, didFinishLoadingWith: true)
      isAppLoaded = true
    } else {
      hideActivityIndicatorWithDelay()
    }
  }
  
  fileprivate func hideActivityIndicatorWithDelay() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      self.hideActivityIndicator()
    }
  }

  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    if self.tableView.isEditing {
      self.tableView.endEditing(true)
      self.tableView.reloadData()
    }
  }
 
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      if filteredPinnedConversations.count == 0 {
        return ""
      }
      return "PINNED"
    } else {
      return " "
    }
  }
  
override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
  if section == 0 {
    return 20
  } else {
    if self.filteredPinnedConversations.count == 0 {
      return 0
    }
   return 8
  }
}
  
  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    if section == 0 {
        view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
    } else {
       view.tintColor = ThemeManager.currentTheme().inputTextViewColor
    }
    
    if let headerTitle = view as? UITableViewHeaderFooterView {
      headerTitle.textLabel?.textColor = .lightGray
      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 10)
    }
  }
  
  
  func sortData() {

    self.conversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    }
    
    self.pinnedConversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    }
    
    self.filteredPinnedConversations = self.pinnedConversations
    self.filtededConversations = self.conversations
    self.tableView.reloadData()
  }
  
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
  
    let pin = UITableViewRowAction(style: .default, title: "Pin") { action, index in
      
      if indexPath.section == 0 {
        
        guard let uid = Auth.auth().currentUser?.uid else  { return }
        
        let conversation = self.filteredPinnedConversations[indexPath.row]
        guard let chatPartnerId = conversation.message?.chatPartnerId() else { return }
        
        guard let index = self.pinnedConversations.index(where: { (conversation) -> Bool in
          return conversation.user?.id == self.filteredPinnedConversations[indexPath.row].user?.id
        }) else { return }
        
        self.tableView.beginUpdates()
        self.filtededConversations.insert(self.filteredPinnedConversations[indexPath.row], at: 0)
        self.conversations.insert(self.filteredPinnedConversations[indexPath.row], at: 0)
        self.filteredPinnedConversations.remove(at: indexPath.row)
        self.pinnedConversations.remove(at: index)
        self.tableView.deleteRows(at: [indexPath], with: .left)
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
        self.sortData()
        self.tableView.endUpdates()
        
        let metadataRef = Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).child(messageMetaDataFirebaseFolder)
        metadataRef.updateChildValues(["pinned": false], withCompletionBlock: { (error, reference) in
          if error != nil {
            basicErrorAlertWith(title: "Error pinning/unpinning", message: "Changes won't be saved across app restarts. Check your internet connection, re-launch the app, and try again.", controller: self)
            print(error?.localizedDescription ?? "")
            return
          }
        })
      } else if indexPath.section == 1 {
        guard let uid = Auth.auth().currentUser?.uid else  { return }
       
        let conversation = self.filtededConversations[indexPath.row]
        guard let chatPartnerId = conversation.message?.chatPartnerId() else { return }
        
        guard let index = self.conversations.index(where: { (conversation) -> Bool in
          return conversation.user?.id == self.filtededConversations[indexPath.row].user?.id
        }) else { return }
        
        
        self.tableView.beginUpdates()
        self.filteredPinnedConversations.insert(self.filtededConversations[indexPath.row], at: 0)
        self.pinnedConversations.insert(self.filtededConversations[indexPath.row], at: 0)
        self.filtededConversations.remove(at: indexPath.row)
        self.conversations.remove(at: index)
        self.tableView.deleteRows(at: [indexPath], with: .left)
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        self.sortData()
        self.tableView.endUpdates()
        
        let metadataRef = Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).child(messageMetaDataFirebaseFolder)
        metadataRef.updateChildValues(["pinned": true], withCompletionBlock: { (error, reference) in
          if error != nil {
            basicErrorAlertWith(title: "Error pinning/unpinning", message: "Changes won't be saved across app restarts. Check your internet connection, re-launch the app, and try again.", controller: self)
            print(error?.localizedDescription ?? "")
            return
          }
          
        })        
      }
    }
    
    if indexPath.section == 0 {
      pin.title = "Unpin"
    } else if indexPath.section == 1 {
      pin.title = "Pin"
    }

    pin.backgroundColor = .orange
    
    let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
      guard let uid = Auth.auth().currentUser?.uid else { return }
      
      if self.currentReachabilityStatus == .notReachable {
        basicErrorAlertWith(title: "Error deleting message", message: noInternetError, controller: self)
        return
      }
      if indexPath.section == 0 {
        
        let conversation = self.filteredPinnedConversations[indexPath.row]
        guard let chatPartnerId = conversation.message?.chatPartnerId() else { return }
        guard let index = self.pinnedConversations.index(where: { (conversation) -> Bool in
          return conversation.user?.id == self.filteredPinnedConversations[indexPath.row].user?.id
        }) else { return }
        
        self.tableView.beginUpdates()
        self.filteredPinnedConversations.remove(at: indexPath.row)
        self.pinnedConversations.remove(at: index)
        self.tableView.deleteRows(at: [indexPath], with: .left)
        self.tableView.endUpdates()
        
        Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue()
        self.configureTabBarBadge()
        
      } else if indexPath.section == 1 {
        
        let conversation = self.filtededConversations[indexPath.row]
        guard let chatPartnerId = conversation.message?.chatPartnerId() else { return }
        guard let index = self.conversations.index(where: { (conversation) -> Bool in
          return conversation.user?.id == self.filtededConversations[indexPath.row].user?.id
        }) else { return }
        
        self.tableView.beginUpdates()
        self.filtededConversations.remove(at: indexPath.row)
        self.conversations.remove(at: index)
        self.tableView.deleteRows(at: [indexPath], with: .left)
        self.tableView.endUpdates()
        
        Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue()
        self.configureTabBarBadge()
      }
    }
  
    delete.backgroundColor = .red
    
    return [delete, pin]
  }
  
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 85
    }
  
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == 0 {
        return filteredPinnedConversations.count
      } else {
        return filtededConversations.count
      }
    }
  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if indexPath.section == 0 {
          return configurePinnedCell(for: indexPath)
        } else {
        return configuredCell(for: indexPath)
      }
    }
  
  
  var chatLogController: ChatLogController? = nil
  
  var autoSizingCollectionViewFlowLayout: AutoSizingCollectionViewFlowLayout? = nil
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var user: User!
    if indexPath.section == 0 {
      user = filteredPinnedConversations[indexPath.row].user
    } else {
      user = filtededConversations[indexPath.row].user
    }
  
    autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
    autoSizingCollectionViewFlowLayout?.minimumLineSpacing = 4
    chatLogController = ChatLogController(collectionViewLayout: autoSizingCollectionViewFlowLayout!)
    chatLogController?.delegate = self
    chatLogController?.allMessagesRemovedDelegate = self
    chatLogController?.user = user
    chatLogController?.hidesBottomBarWhenPushed = true
  }
  
  func handleReloadTableAfterSearch() {
    filtededConversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    }
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
      self.visibleNavigationController()?.pushViewController(destination, animated: true)
      self.chatLogController = nil
      self.autoSizingCollectionViewFlowLayout = nil
    }
  }
}

extension ChatsController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
  
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        filtededConversations = conversations
        filteredPinnedConversations = pinnedConversations
        handleReloadTable()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filtededConversations = searchText.isEmpty ? conversations :
          conversations.filter({ (conversation) -> Bool in
            return conversation.user!.name!.lowercased().contains(searchText.lowercased())
          })
      
      filteredPinnedConversations = searchText.isEmpty ? pinnedConversations :
        pinnedConversations.filter({ (conversation) -> Bool in
          return conversation.user!.name!.lowercased().contains(searchText.lowercased())
        })
      
        handleReloadTableAfterSearch()
    }
  
  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    return true
  }
}

extension ChatsController { /* hiding keyboard */

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
           searchChatsController?.searchBar.endEditing(true)
        } else {
          self.searchBar?.endEditing(true)
        }
    }
  
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
         UIApplication.shared.statusBarStyle = ThemeManager.currentTheme().statusBarStyle //fix
        if #available(iOS 11.0, *) {
            searchChatsController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}


extension ChatsController {
  
  fileprivate func configurePinnedCell(for indexPath: IndexPath) -> UserCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as! UserCell
    
    if filteredPinnedConversations[indexPath.row].user?.id == Auth.auth().currentUser?.uid {
      cell.nameLabel.text = NameConstants.personalStorage
    } else {
      cell.nameLabel.text = filteredPinnedConversations[indexPath.row].user?.name
    }
    
    if (filteredPinnedConversations[indexPath.row].message?.imageUrl != nil ||
      filteredPinnedConversations[indexPath.row].message?.localImage != nil) &&
      filteredPinnedConversations[indexPath.row].message?.videoUrl == nil {
      cell.messageLabel.text = MessageSubtitle.image
    } else if (filteredPinnedConversations[indexPath.row].message?.imageUrl != nil ||
      filteredPinnedConversations[indexPath.row].message?.localImage != nil) &&
      filteredPinnedConversations[indexPath.row].message?.videoUrl != nil {
      cell.messageLabel.text =  MessageSubtitle.video
    } else if filteredPinnedConversations[indexPath.row].message?.voiceEncodedString != nil {
      cell.messageLabel.text =  MessageSubtitle.audio
    } else {
      cell.messageLabel.text = filteredPinnedConversations[indexPath.row].message?.text
    }
    
    let date = Date(timeIntervalSince1970: filteredPinnedConversations[indexPath.row].message?.timestamp as! TimeInterval)
    cell.timeLabel.text = timestampOfLastMessage(date)
    
    
    if filteredPinnedConversations[indexPath.row].user?.id == Auth.auth().currentUser?.uid {
      cell.profileImageView.image = UIImage(named: "PersonalStorage")
      
    } else if let url = self.filteredPinnedConversations[indexPath.row].user?.thumbnailPhotoURL {
      cell.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "UserpicIcon"), options: [.continueInBackground, .progressiveDownload,.scaleDownLargeImages ], completed: nil)
    }
    
    if filteredPinnedConversations[indexPath.row].message?.seen != nil {
      let seen = filteredPinnedConversations[indexPath.row].message?.seen!
      if !seen! && filteredPinnedConversations[indexPath.row].message?.fromId != Auth.auth().currentUser?.uid {
        cell.badgeLabel.text = filteredPinnedConversations[indexPath.row].chatMetaData?.badge?.toString()
        
        if Int(cell.badgeLabel.text!)! > 0 {
          cell.badgeLabel.isHidden = false
          cell.newMessageIndicator.isHidden = false
        } else {
          cell.newMessageIndicator.isHidden = true
          cell.badgeLabel.isHidden = true
        }
      } else {
        cell.newMessageIndicator.isHidden = true
        cell.badgeLabel.isHidden = true
        cell.badgeLabel.text = filteredPinnedConversations[indexPath.row].chatMetaData?.badge?.toString()
      }
    } else {
      cell.newMessageIndicator.isHidden = true
      cell.badgeLabel.isHidden = true
      cell.badgeLabel.text = filteredPinnedConversations[indexPath.row].chatMetaData?.badge?.toString()
    }
    
    return cell
  }
  
  fileprivate func configuredCell(for indexPath: IndexPath) -> UserCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as! UserCell
    
    if filtededConversations[indexPath.row].user?.id == Auth.auth().currentUser?.uid {
      cell.nameLabel.text = NameConstants.personalStorage
    } else {
      cell.nameLabel.text = filtededConversations[indexPath.row].user?.name
    }
    
    if (filtededConversations[indexPath.row].message?.imageUrl != nil ||
      filtededConversations[indexPath.row].message?.localImage != nil) &&
      filtededConversations[indexPath.row].message?.videoUrl == nil {
      cell.messageLabel.text = MessageSubtitle.image
    } else if (filtededConversations[indexPath.row].message?.imageUrl != nil ||
      filtededConversations[indexPath.row].message?.localImage != nil) &&
      filtededConversations[indexPath.row].message?.videoUrl != nil {
      cell.messageLabel.text =  MessageSubtitle.video
    } else if filtededConversations[indexPath.row].message?.voiceEncodedString != nil {
      cell.messageLabel.text =  MessageSubtitle.audio
    } else {
      cell.messageLabel.text = filtededConversations[indexPath.row].message?.text
    }
    
     let date = Date(timeIntervalSince1970: filtededConversations[indexPath.row].message?.timestamp as! TimeInterval)
    cell.timeLabel.text = timestampOfLastMessage(date)
    
    
    if filtededConversations[indexPath.row].user?.id == Auth.auth().currentUser?.uid {
      cell.profileImageView.image = UIImage(named: "PersonalStorage")
      
    } else if let url = self.filtededConversations[indexPath.row].user?.thumbnailPhotoURL {
      cell.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "UserpicIcon"), options: [.continueInBackground, .progressiveDownload,.scaleDownLargeImages ], completed: nil)
    }
    
    if filtededConversations[indexPath.row].message?.seen != nil {
      let seen = filtededConversations[indexPath.row].message?.seen!
      if !seen! && filtededConversations[indexPath.row].message?.fromId != Auth.auth().currentUser?.uid {
        cell.badgeLabel.text = filtededConversations[indexPath.row].chatMetaData?.badge?.toString()
        
        if Int(cell.badgeLabel.text!)! > 0 {
          cell.badgeLabel.isHidden = false
          cell.newMessageIndicator.isHidden = false
        } else {
          cell.newMessageIndicator.isHidden = true
          cell.badgeLabel.isHidden = true
        }
      } else {
        cell.newMessageIndicator.isHidden = true
        cell.badgeLabel.isHidden = true
        cell.badgeLabel.text = filtededConversations[indexPath.row].chatMetaData?.badge?.toString()
      }
    } else {
      cell.newMessageIndicator.isHidden = true
      cell.badgeLabel.isHidden = true
      cell.badgeLabel.text = filtededConversations[indexPath.row].chatMetaData?.badge?.toString()
    }
    return cell
  }
}

extension ChatsController: AllMessagesRemovedDelegate {
  
  func allMessagesRemoved(for chatPartnerID: String, state: Bool) {
      guard state else { return }
      removeEmptyChat(chatPartnerID: chatPartnerID)
  }
  
  fileprivate func removeEmptyChat(chatPartnerID: String) {
    
    guard let uid = Auth.auth().currentUser?.uid, currentReachabilityStatus != .notReachable else { return }
    
    self.tableView.beginUpdates()
    
    guard let indexForConversations = self.conversations.index(where: { (conversation) -> Bool in
      return conversation.user?.id == chatPartnerID
    }) else {
      self.tableView.endUpdates()
      return
    }
    
    self.conversations.remove(at: indexForConversations)
    
    guard let index = self.filtededConversations.index(where: { (conversation) -> Bool in
      return conversation.user?.id == chatPartnerID
    }) else {
      self.tableView.endUpdates()
      return
    }
    self.filtededConversations.remove(at: index)
    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
    self.tableView.endUpdates()
      
    Database.database().reference().child("user-messages").child(uid).child(chatPartnerID).removeValue()
    self.configureTabBarBadge()
  }
}

extension ChatsController { /* activity indicator handling */
  
  static let noInternetMessage = "No internet connection..."
  static let updatingMessage = "Updating..."
  static let connectingMessage = "Connecting..."
  
  func showActivityIndicator(title: String) {
    
    let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    activityIndicatorView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
    activityIndicatorView.color = ThemeManager.currentTheme().generalTitleColor
    activityIndicatorView.startAnimating()
    
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = UIFont.systemFont(ofSize: 14)
    titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    
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
