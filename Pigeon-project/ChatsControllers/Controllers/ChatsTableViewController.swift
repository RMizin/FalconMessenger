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

class ChatsTableViewController: UITableViewController {
  
  fileprivate let userCellID = "userCellID"
  fileprivate var isAppLoaded = false
  
  weak var delegate: ManageAppearance?
  
  var searchBar: UISearchBar?
  var searchChatsController: UISearchController?

  var conversations = [Conversation]()
  var filtededConversations = [Conversation]()
  var pinnedConversations = [Conversation]()
  var filteredPinnedConversations = [Conversation]()
  
  let conversationsFetcher = ConversationsFetcher()
  let notificationsManager = InAppNotificationManager()

  let viewPlaceholder = ViewPlaceholder()
  let navigationItemActivityIndicator = NavigationItemActivityIndicator()
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    configureTableView()
    setupSearchController()
    addObservers()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if !isAppLoaded {
      managePresense()
      conversationsFetcher.fetchConversations()
    }
  }
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  fileprivate func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
  }
  
  @objc fileprivate func changeTheme() {
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.reloadData()
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    guard tableView.isEditing else { return }
    tableView.endEditing(true)
    tableView.reloadData()
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
    conversationsFetcher.delegate = self
  }
  
  @objc fileprivate func newChat() {
    let destination = SelectChatTableViewController()
    destination.hidesBottomBarWhenPushed = true
    let isContactsAccessGranted = destination.checkContactsAuthorizationStatus()
    if isContactsAccessGranted {
      destination.users = globalUsers
      destination.filteredUsers = globalUsers
      destination.setUpCollation()
      destination.checkNumberOfContacts()
    }
    navigationController?.pushViewController(destination, animated: true)
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
      navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .connecting,
                                                            activityPriority: .high,
                                                            color: ThemeManager.currentTheme().generalTitleColor)
    }
    
    let connectedReference = Database.database().reference(withPath: ".info/connected")
    connectedReference.observe(.value, with: { (snapshot) in
      
      if self.currentReachabilityStatus != .notReachable {
        self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .crazy)
      } else {
        self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .noInternet, activityPriority: .crazy, color: ThemeManager.currentTheme().generalTitleColor)
      }
    })
  }
  
  func checkIfThereAnyActiveChats(isEmpty: Bool) {
    guard isEmpty else {
      viewPlaceholder.remove(from: view, priority: .medium)
      return
    }
    viewPlaceholder.add(for: view, title: .emptyChat, subtitle: .emptyChat, priority: .medium, position: .top)
  }
  
  func configureTabBarBadge() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    
    guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
    guard let tabItem = tabItems[Tabs.chats.rawValue] as? UITabBarItem else { return }
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
  
  fileprivate func updateCell(at indexPath: IndexPath) {
    tableView.beginUpdates()
    tableView.reloadRows(at: [indexPath], with: .none)
    tableView.endUpdates()
  }
  
  func handleReloadTable() {
    
    conversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
    }
    
    pinnedConversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
    }
    
    filteredPinnedConversations = pinnedConversations
    filtededConversations = conversations
    
    if !isAppLoaded {
      UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()}, completion: nil)
      
      configureTabBarBadge()
    } else {
      configureTabBarBadge()
      tableView.reloadData()
    }
    
    if filtededConversations.count == 0 && filteredPinnedConversations.count == 0 {
      checkIfThereAnyActiveChats(isEmpty: true)
    } else {
      checkIfThereAnyActiveChats(isEmpty: false)
    }
    
    guard !isAppLoaded else { return }
    delegate?.manageAppearance(self, didFinishLoadingWith: true)
    isAppLoaded = true
  }
  
  func handleReloadTableAfterSearch() {
    filtededConversations.sort { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
    }
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
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
    
    let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as? UserCell ?? UserCell()
    
    if indexPath.section == 0 {
      cell.configureCell(for: indexPath, conversations: filteredPinnedConversations)
    } else {
      cell.configureCell(for: indexPath, conversations: filtededConversations)
    }
    
    return cell
  }
  
  var chatLogController: ChatLogController? = nil
  var messagesFetcher: MessagesFetcher? = nil

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var conversation: Conversation!

    if indexPath.section == 0 {
      let pinnedConversation = filteredPinnedConversations[indexPath.row]
      conversation = pinnedConversation
    } else {
      let unpinnedConversation = filtededConversations[indexPath.row]
      conversation = unpinnedConversation
    }
  
    chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
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
		guard let index = conversationsArray.firstIndex(where: { (conversation) -> Bool in
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
    
    chatLogController?.messagesFetcher.collectionDelegate = chatLogController
    guard let destination = chatLogController else { return }
    
    if #available(iOS 11.0, *) {
    } else {
      self.chatLogController?.startCollectionViewAtBottom()
    }
    
    navigationController?.pushViewController(destination, animated: true)
    chatLogController = nil
    messagesFetcher?.delegate = nil
    messagesFetcher = nil
  }
}

extension ChatsTableViewController: ConversationUpdatesDelegate {
  
  func conversations(didStartFetching: Bool) {
    guard !isAppLoaded else { return }
    navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .updating,
                                                          activityPriority: .mediumHigh, color: ThemeManager.currentTheme().generalTitleColor)
  }
  
  func conversations(didStartUpdatingData: Bool) {
    navigationItemActivityIndicator.showActivityIndicator(for: navigationItem, with: .updating,
                                                          activityPriority: .lowMedium, color: ThemeManager.currentTheme().generalTitleColor)
  }
  
  func conversations(didFinishFetching: Bool, conversations: [Conversation]) {
    notificationsManager.observersForNotifications(conversations: conversations)
    
    let (pinned, unpinned) = conversations.stablePartition { (element) -> Bool in
      let isPinned = element.pinned ?? false
      return isPinned == true
    }
    
    self.conversations = unpinned
    self.pinnedConversations = pinned
    
    handleReloadTable()
    navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .mediumHigh)
  }
  
  func conversations(update conversation: Conversation, reloadNeeded: Bool) {
    let chatID = conversation.chatID ?? ""
    
		if let index = conversations.firstIndex(where: {$0.chatID == chatID}) {
      conversations[index] = conversation
    }
		if let index = pinnedConversations.firstIndex(where: {$0.chatID == chatID}) {
      pinnedConversations[index] = conversation
    }
		if let index = filtededConversations.firstIndex(where: {$0.chatID == chatID}) {
      filtededConversations[index] = conversation
      let indexPath = IndexPath(row: index, section: 1)
      if reloadNeeded { updateCell(at: indexPath) }
    }
		if let index = filteredPinnedConversations.firstIndex(where: {$0.chatID == chatID}) {
      filteredPinnedConversations[index] = conversation
      let indexPath = IndexPath(row: index, section: 0)
      if reloadNeeded { updateCell(at: indexPath) }
    }
    
    let allConversations = conversations + pinnedConversations
    notificationsManager.updateConversations(to: allConversations)
    navigationItemActivityIndicator.hideActivityIndicator(for: navigationItem, activityPriority: .lowMedium)
  }
}
