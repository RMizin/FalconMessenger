//
//  ChatsTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
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


protocol ManageAppearance: class {
  func manageAppearance(_ chatsController: ChatsTableViewController, didFinishLoadingWith state: Bool )
}

public var shouldReloadChatsControllerAfterChangingTheme = false


class ChatsTableViewController: UITableViewController {
  
  let noChatsYetContainer:NoChatsYetContainer! = NoChatsYetContainer()
  
  let navigationItemActivityIndicator = NavigationItemActivityIndicator()
  
  let userCellID = "userCellID"
  
  fileprivate let group = DispatchGroup()
  
  weak var delegate: ManageAppearance?
  
  var searchBar: UISearchBar?
  
  var searchChatsController: UISearchController?

  var conversations = [Conversation]()
  
  var filtededConversations = [Conversation]()
  
  var pinnedConversations = [Conversation]()
  
  var filteredPinnedConversations = [Conversation]()
  
  fileprivate var isAppLoaded = false
  
  fileprivate var isGroupAlreadyFinished = false
  
  fileprivate var userReference: DatabaseReference!
  
  fileprivate var currentUserConversationsReference: DatabaseReference!
  
  fileprivate var lastMessageForConverstaionRef: DatabaseReference!
  
  fileprivate var conversationReference: DatabaseReference!
  
  fileprivate var connectedReference: DatabaseReference!

  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    configureTableView()
    setupSearchController()
    managePresense()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    if let testSelected = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: testSelected, animated: true)
    }
    super.viewDidAppear(animated)
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
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    if tableView.isEditing {
      tableView.endEditing(true)
      tableView.reloadData()
    }
  }
  
  fileprivate func configureTableView() {
    
    tableView.register(UserCell.self, forCellReuseIdentifier: userCellID)
    tableView.allowsMultipleSelectionDuringEditing = false
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.backgroundColor = view.backgroundColor
    navigationItem.leftBarButtonItem = editButtonItem
    let newChatBarButton =  UIBarButtonItem(image: UIImage(named: "composeButton"), style: .done, target: self, action: #selector(newChat))
    navigationItem.rightBarButtonItem = newChatBarButton
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    tableView.separatorStyle = .none
    definesPresentationContext = true
  }
  
  @objc fileprivate func newChat() {
    let destination = SelectChatTableViewController()
    destination.hidesBottomBarWhenPushed = true
    destination.users = globalUsers
    destination.filteredUsers = globalUsers
    navigationController?.pushViewController(destination, animated: true)
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
      searchBar?.placeholder = "Search"
      searchBar?.searchBarStyle = .minimal
      searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
      tableView.tableHeaderView = searchBar
    }
  }
  
 fileprivate func managePresense() {
    
    if currentReachabilityStatus == .notReachable {
      navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting, activityPriority: .high, color: ThemeManager.currentTheme().generalTitleColor)
    }
    
    connectedReference = Database.database().reference(withPath: ".info/connected")
    connectedReference.observe(.value, with: { (snapshot) in
      
      if self.currentReachabilityStatus != .notReachable {
       self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
      } else {
        self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: ThemeManager.currentTheme().generalTitleColor)
      }
    }) { (error) in
      print(error.localizedDescription)
    }
  }
  
  func checkIfThereAnyActiveChats(isEmpty: Bool) {
    
    guard !isEmpty else {
      self.view.addSubview(noChatsYetContainer)
      noChatsYetContainer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
      return
    }
    
    for subview in self.view.subviews {
      if subview is NoChatsYetContainer {
        subview.removeFromSuperview()
      }
    }
  }
  
  var notificationReference: DatabaseReference!
  var notificationHandle = [DatabaseHandle]()
  fileprivate var inAppNotificationsObserverHandler: DatabaseHandle!
  
  func observersForNotifications() {
    
    if notificationReference != nil {
      for handle in notificationHandle {
        notificationReference.removeObserver(withHandle: handle)
      }
    }
    
    var allConversations = [Conversation]()
    
    allConversations.insert(contentsOf: conversations, at: 0)
    allConversations.insert(contentsOf: pinnedConversations, at: 0)
    
    for conversation in allConversations {
    
      guard let currentUserID = Auth.auth().currentUser?.uid, let chatID = conversation.chatID else { continue }
      
      notificationReference = Database.database().reference().child("user-messages").child(currentUserID).child(chatID).child(messageMetaDataFirebaseFolder)
      let handle = DatabaseHandle()
      notificationHandle.insert(handle, at: 0)
      notificationHandle[0] = notificationReference.observe(.childChanged, with: { (snapshot) in
        guard snapshot.key == "lastMessageID" else { return }
        guard let messageID = snapshot.value as? String else { return }
        self.lastMessageForConverstaionRef = Database.database().reference().child("messages").child(messageID)
        
        self.lastMessageForConverstaionRef.observeSingleEvent(of: .value, with: { (snapshot) in
          
          guard var dictionary = snapshot.value as? [String: AnyObject] else { print("returnun2"); return }
          dictionary.updateValue(messageID as AnyObject, forKey: "messageUID")
          let message = Message(dictionary: dictionary)
          guard let uid = Auth.auth().currentUser?.uid, message.fromId != uid else { print("returnun3"); return }
          self.handleInAppSoundPlaying(message: message, conversation: conversation)
        })
      })
    }
  }
  
  fileprivate var shouldDisableUpdatingIndicator = true
  var groupChatReference: DatabaseReference!
  var groupChatHandle:DatabaseHandle!
  fileprivate typealias GroupChatMetaInfoCompletionHandler = (_ success: Bool, _ dictionary: [String:AnyObject]) -> Void
  
  fileprivate func groupChatMetaInfo( dictionary: [String:AnyObject], completion: @escaping GroupChatMetaInfoCompletionHandler) {

    let conversation = Conversation(dictionary: dictionary)
    guard let chatID = conversation.chatID else { return }
    groupChatReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    if groupChatHandle != nil {
      groupChatReference.removeObserver(withHandle: groupChatHandle)
    }
    groupChatHandle = groupChatReference.observe(.value) { (snapshot) in
      guard var chatDictionary = snapshot.value as? [String: AnyObject] else {completion(true, dictionary); return }
      chatDictionary.updateValue(conversation.pinned as AnyObject, forKey: "pinned")
      chatDictionary.updateValue(conversation.muted as AnyObject, forKey: "muted")
      chatDictionary.updateValue(conversation.badge as AnyObject, forKey: "badge")
      chatDictionary.updateValue(conversation.lastMessageID as AnyObject, forKey: "lastMessageID")
      if let membersIDs = chatDictionary["chatParticipantsIDs"] as? [String:AnyObject] {
        chatDictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "chatParticipantsIDs")
      }
      completion(true, chatDictionary)
    }
  }
  
 fileprivate func fetchConversations() {
  
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    if !isAppLoaded {
      navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .loadingFromCache, activityPriority: .mediumHigh, color: ThemeManager.currentTheme().generalTitleColor)
    }
  
    currentUserConversationsReference = Database.database().reference().child("user-messages").child(currentUserID)
    currentUserConversationsReference.observeSingleEvent(of: .value) { (snapshot) in
      
      for _ in 0 ..< snapshot.childrenCount { self.group.enter() }
      
      self.group.notify(queue: DispatchQueue.main, execute: {
        self.handleReloadTable()
        self.isGroupAlreadyFinished = true
        self.observersForNotifications()
        self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .mediumHigh)
        self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .updating, activityPriority: .lowMedium, color: ThemeManager.currentTheme().generalTitleColor)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
          if self.shouldDisableUpdatingIndicator {
            print("disabling")
            self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .lowMedium)
          }
        }
      })
      
      if !snapshot.exists() {
        self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .lowMedium)
        self.handleReloadTable()
        print("\ncurrentUserConversationsReference snap not exists\n")
        return
      }
    }
  
    currentUserConversationsReference.observe(.childAdded, with: { (snapshot) in
      print("child added")
      let chatID = snapshot.key
      
      self.conversationReference = Database.database().reference().child("user-messages").child(currentUserID).child(chatID).child(messageMetaDataFirebaseFolder)
      self.conversationReference.observe(.value, with: { (snapshot) in
        
        guard var conversationDictionary = snapshot.value as? [String: AnyObject], snapshot.exists() else { return }
         conversationDictionary.updateValue(chatID as AnyObject, forKey: "chatID")
    
        if self.isGroupAlreadyFinished { self.shouldDisableUpdatingIndicator = false }
        self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .updating, activityPriority: .lowMedium, color: ThemeManager.currentTheme().generalTitleColor)
    
          self.groupChatMetaInfo(dictionary: conversationDictionary, completion: { (_, dictionary) in

            let conversation = Conversation(dictionary: dictionary)
            
            guard let lastMessageID = conversation.lastMessageID else { //if no messages in chat yet
              guard conversation.isGroupChat != nil, conversation.isGroupChat! else {
                self.updateConversations(with: conversation, isGroupChat: false, notificationAtTheEnd: false)
                return
              }
              self.updateConversations(with: conversation, isGroupChat: true, notificationAtTheEnd: false)
              return
            }
            
            self.lastMessageForConverstaionRef = Database.database().reference().child("messages").child(lastMessageID)
            self.lastMessageForConverstaionRef.observeSingleEvent(of: .value, with: { (snapshot) in
              guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
              dictionary.updateValue(lastMessageID as AnyObject, forKey: "messageUID")
              
              let message = Message(dictionary: dictionary)
              conversation.lastMessage = message
              
              guard conversation.isGroupChat != nil, conversation.isGroupChat! else {
                self.updateConversations(with: conversation, isGroupChat: false, notificationAtTheEnd: true)
                return
              }
              
              self.updateConversations(with: conversation, isGroupChat: true, notificationAtTheEnd: true)
            })
          })
      }, withCancel: { (error) in
        print(error.localizedDescription)
      })
    })
  }
  
  
  fileprivate func updateConversations(with conversation: Conversation, isGroupChat: Bool, notificationAtTheEnd: Bool) {
    
    guard isGroupChat else {
      self.updateDefaultChat(with: conversation)
      return
    }
    self.updateGroupChat(with: conversation)
  }
  
  fileprivate func updateGroupChat(with conversation: Conversation ) {
    updateConversationArrays(with: conversation)
  }
  
  fileprivate func updateDefaultChat(with conversation: Conversation ) {
    
    guard let userID = conversation.chatID, let currentUserID = Auth.auth().currentUser?.uid else {print("default chat returning from chat id "); return }
    print(userID)
    userReference = Database.database().reference().child("users").child(userID)
    userReference.observeSingleEvent(of: .value, with: { (snapshot) in
      
      guard var dictionary = snapshot.value as? [String: AnyObject] else { print("default chat returning from dictionary"); return }
      dictionary.updateValue(userID as AnyObject, forKey: "id")
      
      let user = User(dictionary: dictionary)
      
      conversation.chatName = user.name
      conversation.chatPhotoURL = user.photoURL
      conversation.chatThumbnailPhotoURL = user.thumbnailPhotoURL
      conversation.chatParticipantsIDs = [userID, currentUserID]
      print("up conv arrays from default chat")
      self.updateConversationArrays(with: conversation)
    })
    
    userReference.observe(.childChanged) { (snapshot) in
      print("child changed")
      if let unpinnedIndex = self.filtededConversations.index(where: { (unpinnedConversation) -> Bool in
        return unpinnedConversation.chatID == userID }) {
        
        if snapshot.key == "name" {
          self.filtededConversations[unpinnedIndex].chatName = snapshot.value as? String
          self.handleGroupOrReloadTable()
        } else if snapshot.key == "thumbnailPhotoURL" {
          self.filtededConversations[unpinnedIndex].chatThumbnailPhotoURL = snapshot.value as? String
          self.handleGroupOrReloadTable()
        } else {
          return
        }
      } else if let pinnedIndex = self.filteredPinnedConversations.index(where: { (pinnedConversation) -> Bool in
        return pinnedConversation.chatID == userID }) {
        
        if snapshot.key == "name" {
          self.filteredPinnedConversations[pinnedIndex].chatName = snapshot.value as? String
          self.handleGroupOrReloadTable()
        } else if snapshot.key == "thumbnailPhotoURL" {
          self.filteredPinnedConversations[pinnedIndex].chatThumbnailPhotoURL = snapshot.value as? String
          self.handleGroupOrReloadTable()
        } else { return }
      } else { return }
    }
  }

 fileprivate func updateConversationArrays(with conversation: Conversation) {
  
  guard let userID = conversation.chatID else { print("id nil returning"); return }
    if let unpinnedIndex = self.conversations.index(where: { (unpinnedConversation) -> Bool in
      return unpinnedConversation.chatID == userID }) {
      
      self.conversations[unpinnedIndex] = conversation
      self.handleGroupOrReloadTable()
      
    } else if let pinnedIndex = self.pinnedConversations.index(where: { (pinnedConversation) -> Bool in
      return pinnedConversation.chatID == userID }) {
      
      self.pinnedConversations[pinnedIndex] = conversation
      self.handleGroupOrReloadTable()
      
    } else {
      if conversation.pinned != nil && conversation.pinned! {
        self.pinnedConversations.append(conversation)
      } else {
        self.conversations.append(conversation)
      }
      if isGroupAlreadyFinished {
        self.observersForNotifications()
      }
     
      self.handleGroupOrReloadTable()
    }
  }
  
  func configureTabBarBadge() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
    guard let tabItem = tabItems[tabs.chats.rawValue] as? UITabBarItem else { return }
    var badge = 0
    
    for conversation in filtededConversations {
      guard let lastMessage = conversation.lastMessage, let conversationBadge = conversation.badge, lastMessage.fromId != uid  else { continue }
      badge += conversationBadge
    }
    
    for conversation in filteredPinnedConversations {
      guard let lastMessage = conversation.lastMessage, let conversationBadge = conversation.badge, lastMessage.fromId != uid  else { continue }
      badge += conversationBadge
    }
    
    guard badge > 0 else {
      tabItem.badgeValue = nil
      UIApplication.shared.applicationIconBadgeNumber = 0
      return
    }
    
    tabItem.badgeValue = badge.toString()
    UIApplication.shared.applicationIconBadgeNumber = badge
  }
  
  fileprivate func handleGroupOrReloadTable() {
    print("in handle reload")
    if self.isGroupAlreadyFinished {
      handleReloadTable()
    } else {
      group.leave()
      print("leaving group")
    }
  }
  
  func handleReloadTable() {
    
    conversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
    }
    
    pinnedConversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
    }
    
    filteredPinnedConversations = pinnedConversations
    filtededConversations = conversations
    
    if !isAppLoaded {
      UIView.transition(with: tableView, duration: 0.25, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
    } else {
      self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .lowMedium)
      self.tableView.reloadData()
    }
    
    if filtededConversations.count == 0 && filteredPinnedConversations.count == 0 {
      checkIfThereAnyActiveChats(isEmpty: true)
    } else {
      checkIfThereAnyActiveChats(isEmpty: false)
    }
    
    configureTabBarBadge()
    
    if !isAppLoaded {
      delegate?.manageAppearance(self, didFinishLoadingWith: true)
      isAppLoaded = true
    }
  }
  
  func handleReloadTableAfterSearch() {
    filtededConversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
    }
    tableView.reloadData()
  }

    // MARK: - Table view data source
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
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
  
  fileprivate func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
      completion()
    }
  }
  
  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    if section == 0 {
      view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
    } else {
      view.tintColor = ThemeManager.currentTheme().inputTextViewColor
    }
    
    if let headerTitle = view as? UITableViewHeaderFooterView {
      headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 10)
    }
  }
  
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
    let delete = setupDeleteAction(at: indexPath)
    let pin = setupPinAction(at: indexPath)
    let mute = setupMuteAction(at: indexPath)
 
    return [delete, pin, mute]
  }
  
  func setupMuteAction(at indexPath: IndexPath) -> UITableViewRowAction {
    let mute = UITableViewRowAction(style: .default, title: "Mute") { _, _ in
      if indexPath.section == 0 {
        if #available(iOS 11.0, *) {} else {
          self.tableView.setEditing(false, animated: true)
        }
        self.delayWithSeconds(1, completion: {
          self.handleMuteConversation(section: indexPath.section, for: self.filteredPinnedConversations[indexPath.row])
        })
      } else if indexPath.section == 1 {
        if #available(iOS 11.0, *) {} else {
          self.tableView.setEditing(false, animated: true)
        }
        self.delayWithSeconds(1, completion: {
          self.handleMuteConversation(section: indexPath.section, for: self.filtededConversations[indexPath.row])
        })
      }
    }
    
    if indexPath.section == 0 {
      let isPinnedConversationMuted = filteredPinnedConversations[indexPath.row].muted == true
      let muteTitle = isPinnedConversationMuted ? "Unmute" : "Mute"
      mute.title = muteTitle
    } else if indexPath.section == 1 {
      let isConversationMuted = filtededConversations[indexPath.row].muted == true
      let muteTitle = isConversationMuted ? "Unmute" : "Mute"
      mute.title = muteTitle
    }
    mute.backgroundColor = UIColor(red:0.56, green:0.64, blue:0.68, alpha:1.0)
    return mute
  }
  
  func setupPinAction(at indexPath: IndexPath) -> UITableViewRowAction {
    let pin = UITableViewRowAction(style: .default, title: "Pin") { _, _ in
      if indexPath.section == 0 {
        self.unpinConversation(at: indexPath)
      } else if indexPath.section == 1 {
        self.pinConversation(at: indexPath)
      }
    }
    
    let pinTitle = indexPath.section == 0 ? "Unpin" : "Pin"
    pin.title = pinTitle
    pin.backgroundColor = UIColor(red:0.96, green:0.49, blue:0.00, alpha:1.0)
    return pin
  }
  
  func setupDeleteAction(at indexPath: IndexPath) -> UITableViewRowAction {
    
    let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
      if self.currentReachabilityStatus == .notReachable {
        basicErrorAlertWith(title: "Error deleting message", message: noInternetError, controller: self)
        return
      }
      if indexPath.section == 0 {
        self.deletePinnedConversation(at: indexPath)
      } else if indexPath.section == 1 {
        self.deleteUnPinnedConversation(at: indexPath)
      }
    }
    
    delete.backgroundColor = UIColor(red:0.90, green:0.22, blue:0.21, alpha:1.0)
    return delete
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
    
    let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as! UserCell
    
    if indexPath.section == 0 {
      cell.configureCell(for: indexPath, conversations: filteredPinnedConversations)
    } else {
      cell.configureCell(for: indexPath, conversations: filtededConversations)
    }
    
    return cell
  }
  
  var chatLogController:ChatLogController? = nil
  var messagesFetcher:MessagesFetcher? = nil
  var destinationLayout:AutoSizingCollectionViewFlowLayout? = nil

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var conversation:Conversation!

    if indexPath.section == 0 {
      let pinnedConversation = filteredPinnedConversations[indexPath.row]
      conversation = pinnedConversation
    } else {
      let unpinnedConversation = filtededConversations[indexPath.row]
      conversation = unpinnedConversation
    }
    
    destinationLayout = AutoSizingCollectionViewFlowLayout()
    destinationLayout?.minimumLineSpacing = 3
    chatLogController = ChatLogController(collectionViewLayout: destinationLayout!)
    
    messagesFetcher = MessagesFetcher()
    messagesFetcher?.delegate = self
    messagesFetcher?.loadMessagesData(for: conversation)
  }
}

extension ChatsTableViewController: DeleteAndExitDelegate {
  
  func deleteAndExit(from conversationID: String) {
    
    let pinnedIDs = pinnedConversations.map({$0.chatID ?? ""})
    let section = pinnedIDs.contains(conversationID) ? 0 : 1
    guard let row = conversationIndex(for: conversationID, at: section) else { return }
  
    let indexPath = IndexPath(row: row, section: section)
    section == 0 ? deletePinnedConversation(at: indexPath) : deleteUnPinnedConversation(at: indexPath)
  }
  
  func conversationIndex(for conversationID: String, at section: Int) -> Int? {
    let conversationsArray = section == 0 ? filteredPinnedConversations : filtededConversations
    guard let index = conversationsArray.index(where: { (conversation) -> Bool in
      guard let chatID = conversation.chatID else { return false }
      return chatID == conversationID
    }) else { return nil }
    return index
  }
}

extension ChatsTableViewController: MessagesDelegate {
  
  func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
    chatLogController?.updateMessageStatus(messageRef: reference)
  }
  
  func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
   
    chatLogController?.hidesBottomBarWhenPushed = true
    chatLogController?.messagesFetcher = messagesFetcher
    chatLogController?.messages = messages
    chatLogController?.conversation = conversation
    chatLogController?.deleteAndExitDelegate = self
 
    if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
      chatLogController?.observeTypingIndicator()
      chatLogController?.configureTitleViewWithOnlineStatus()
    }
    
    chatLogController?.observeMembersChanges()
    
    chatLogController?.messagesFetcher.collectionDelegate = chatLogController
    guard let destination = chatLogController else { return }
    
    if #available(iOS 11.0, *) {
    } else {
      self.chatLogController?.startCollectionViewAtBottom()
    }
   
    self.visibleNavigationController()?.pushViewController(destination, animated: true)
    chatLogController = nil
    destinationLayout = nil
  }
}
