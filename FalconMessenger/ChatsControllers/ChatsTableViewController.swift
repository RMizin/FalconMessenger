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
import RealmSwift

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
	let viewPlaceholder = ViewPlaceholder()
	let navigationItemActivityIndicator = NavigationItemActivityIndicator()

  let conversationsFetcher = ConversationsFetcher()
  let notificationsManager = InAppNotificationManager()
	let realmManager = ChatsRealmManager()

	var pinnedConversationsNotificationToken: NotificationToken?
	var unpinnedConversationsNotificationToken: NotificationToken?

	var realmPinnedConversations: Results<Conversation>!
		//= try! Realm().objects(Conversation.self).filter("pinned == true").sorted(byKeyPath: "lastMessageTimestamp", ascending: false)
	var realmUnpinnedConversations: Results<Conversation>!
		//= try! Realm().objects(Conversation.self).filter("pinned != true").sorted(byKeyPath: "lastMessageTimestamp", ascending: false)
	var realmAllConversations: Results<Conversation>!
		//= try! Realm().objects(Conversation.self)


  override func viewDidLoad() {
    super.viewDidLoad()

		setupDataSource()
    configureTableView()
    setupSearchController()
    addObservers()
  }

	fileprivate func setupDataSource() {
		let objects = realmManager.realm.objects(Conversation.self)
		let pinnedObjects = objects.filter("pinned == true").sorted(byKeyPath: "lastMessageTimestamp", ascending: false)
		let unpinnedObjects = objects.filter("pinned != true").sorted(byKeyPath: "lastMessageTimestamp", ascending: false)

		realmPinnedConversations = pinnedObjects
		realmUnpinnedConversations = unpinnedObjects
		realmAllConversations = objects
	}

	fileprivate func observeDataSourceChanges() {

		pinnedConversationsNotificationToken = realmPinnedConversations.observe { (changes: RealmCollectionChange) in
			switch changes {
			case .initial:
				break
			case .update(_, let deletions, let insertions, let modifications):
				if self.isAppLoaded {
					UIView.performWithoutAnimation {
						print("xxx in pinned update", deletions.count, insertions.count, modifications.count)
						self.tableView.beginUpdates()
						self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 1) }, with: .none)
						self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 1) }, with: .left)
						UIView.performWithoutAnimation { self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 1) }, with: .none) }
						self.tableView.endUpdates()
					}
				}

				break
			case .error(let err):
				// An error occurred while opening the Realm file on the background worker thread
				fatalError("\(err)")
				break
			}
		}

		unpinnedConversationsNotificationToken = realmUnpinnedConversations.observe { (changes: RealmCollectionChange) in
			switch changes {
			case .initial:

				UIView.performWithoutAnimation {
					self.tableView.reloadData()
				}

				break
			case .update(_, let deletions, let insertions, let modifications):

				if self.isAppLoaded {
					print("xxx in update", deletions.count, insertions.count, modifications.count)
					UIView.performWithoutAnimation {
						self.tableView.beginUpdates()
						self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 1) }, with: .none)
						self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 1) }, with: .left)
						UIView.performWithoutAnimation { self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 1) }, with: .none) }
						self.tableView.endUpdates()
					}
				}

				break
			case .error(let err):
				// An error occurred while opening the Realm file on the background worker thread
				fatalError("\(err)")
				break
			}
		}
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
    NotificationCenter.default.addObserver(self, selector: #selector(cleanUpController), name: NSNotification.Name(rawValue: "clearUserData"), object: nil)
  }
  
  @objc fileprivate func changeTheme() {
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.isOpaque = true
    tableView.reloadData()
    navigationItemActivityIndicator.activityIndicatorView.color = ThemeManager.currentTheme().generalTitleColor
    navigationItemActivityIndicator.titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
  }

  fileprivate func initAllTabs() {
    guard let appDelegate = tabBarController as? GeneralTabBarController else { return }
    _ = appDelegate.contactsController.view
    _ = appDelegate.settingsController.view
  }
  
  @objc public func cleanUpController() {
//    pinnedConversations.removeAll()
//    conversations.removeAll()
//    filtededConversations.removeAll()
//    filteredPinnedConversations.removeAll()
		realmManager.deleteAll()
    tableView.reloadData()
    isAppLoaded = false
    notificationsManager.removeAllObservers()
    conversationsFetcher.removeAllObservers()
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
    let newChatBarButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newChat))
    navigationItem.rightBarButtonItem = newChatBarButton
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    tableView.separatorStyle = .none
    definesPresentationContext = true
    typingIndicatorManager.delegate = self
    conversationsFetcher.delegate = self
  }
  
  @objc fileprivate func newChat() {
    let destination = SelectChatTableViewController()
    destination.hidesBottomBarWhenPushed = true
    let isContactsAccessGranted = destination.checkContactsAuthorizationStatus()
    if isContactsAccessGranted {
      destination.users = globalDataStorage.falconUsers
      destination.filteredUsers = globalDataStorage.falconUsers
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


//	func pinnedConversations() {
//		let pinned  = realmConversations.map({$0.map({$0.pinned == true})})
//
//		realmConversations.
//
//	}
//	func pinnedConversations() {
//		realmConversations.filter { (conversation) -> Bool in
//			return conversation.filter("pinned = '\(true)'")
//		}

	//	let badges = realmConversations.map({$0.map({ $0.badge.value + $1.badge.value})})

//		let badge:Array<Int> = realmConversations.map({$0.map({ (conversation) -> Int in
//			return conversation.badge.value ?? 0
//		})})

//		let badge = realmConversations.flatMap { (conversations) -> [Int] in
//			return conversations.map({ (conversation) -> Int in
//				return conversation.badge.value ?? 0
//			})
//		}.reduce(0, +)
//

	//	let gg = badge1.flatMap({$0.map({$0})})



	//	badges.red


//let sub = badges.reduce(0, +)

//		for conversationsArray in realmConversations {
//		//	conve
//		}
//		guard let realmConversations.index { (conversation) -> Bool in
//			return conversation.filter("pinned = '\(true)'")
//		} else {
//
//		}
	//}
  func configureTabBarBadge() {
  //  guard let uid = Auth.auth().currentUser?.uid else { return }
    guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
    guard let tabItem = tabItems[Tabs.chats.rawValue] as? UITabBarItem else { return }
   // var badge = 0
    
//    for conversation in filtededConversations {
//      guard let lastMessage = conversation.lastMessage, let conversationBadge = conversation.badge.value, lastMessage.fromId != uid  else { continue }
//      badge += conversationBadge
//    }
//
//    for conversation in filteredPinnedConversations {
//      guard let lastMessage = conversation.lastMessage, let conversationBadge = conversation.badge.value, lastMessage.fromId != uid  else { continue }
//      badge += conversationBadge
//    }

//let allConversations = try! Realm().objects(Conversation.self)

	//	let badge = realmConversations.flatMap { (conversations) -> [Int] in
			let badge = realmAllConversations.map({ (conversation) -> Int in
				return conversation.badge.value ?? 0
			}).reduce(0, +)


		//	}


    guard badge > 0 else {
      tabItem.badgeValue = nil
      UIApplication.shared.applicationIconBadgeNumber = 0
      return
    }
    
    tabItem.badgeValue = badge.toString()
    UIApplication.shared.applicationIconBadgeNumber = badge
  }
  
//  fileprivate func updateCell(at indexPath: IndexPath) {
//    tableView.beginUpdates()
//    tableView.reloadRows(at: [indexPath], with: .none)
//    tableView.endUpdates()
//  }

  func handleReloadTable(isSearching: Bool = false) {
    
//    conversations.sort { (conversation1, conversation2) -> Bool in
//      return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
//    }
//
//    pinnedConversations.sort { (conversation1, conversation2) -> Bool in
//      return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
//    }
//
//    filteredPinnedConversations = pinnedConversations
//    filtededConversations = conversations

    if !isAppLoaded {
   //   UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()}, completion: { (_) in
        self.initAllTabs()
        
				for conversation in self.realmAllConversations {
          guard let chatID = conversation.chatID else { return }

          if let isGroupChat = conversation.isGroupChat.value, isGroupChat {
						//without realm
//            if let members = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, members.contains(uid) {
//              typingIndicatorManager.observeChangesForGroupTypingIndicator(with: chatID)
//            }

						//with realm
						if let uid = Auth.auth().currentUser?.uid, conversation.chatParticipantsIDs.contains(uid) {
							typingIndicatorManager.observeChangesForGroupTypingIndicator(with: chatID)
						}
          } else {
            typingIndicatorManager.observeChangesForDefaultTypingIndicator(with: chatID)
          }
        }
        
//        for conversation in self.filteredPinnedConversations {
//          guard let chatID = conversation.chatID else { return }
//
//          if let isGroupChat = conversation.isGroupChat.value, isGroupChat {
////without realm
////            if let members = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, members.contains(uid) {
////              typingIndicatorManager.observeChangesForGroupTypingIndicator(with: chatID)
////            }
////with realm
//						if let uid = Auth.auth().currentUser?.uid, conversation.chatParticipantsIDs.contains(uid) {
//							typingIndicatorManager.observeChangesForGroupTypingIndicator(with: chatID)
//						}
//          } else {
//            typingIndicatorManager.observeChangesForDefaultTypingIndicator(with: chatID)
//          }
//        }
				self.observeDataSourceChanges()
   //  })
      
      configureTabBarBadge()
    } else {
      configureTabBarBadge()
//      if isSearching {
//        UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData() }, completion: nil)
////      } else {
//			DispatchQueue.main.async {
//				self.tableView.reloadData()
//			}

//      }
    }
    
    if realmAllConversations.count == 0 {
      checkIfThereAnyActiveChats(isEmpty: true)
    } else {
      checkIfThereAnyActiveChats(isEmpty: false)
    }
    
    guard !isAppLoaded else { return }
    delegate?.manageAppearance(self, didFinishLoadingWith: true)

    isAppLoaded = true
  }
  
  func handleReloadTableAfterSearch() {
//    filtededConversations.sort { (conversation1, conversation2) -> Bool in
//      return conversation1.lastMessage?.timestamp?.int64Value > conversation2.lastMessage?.timestamp?.int64Value
//    }
  //  UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData() }, completion: nil)
  }

    // MARK: - Table view data source
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      if realmPinnedConversations.count == 0 {
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
      if self.realmPinnedConversations.count == 0 {
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

		if let cell = tableView.cellForRow(at: indexPath) as? UserCell  {
			guard cell.nameLabel.text != NameConstants.personalStorage else { return [delete, pin] }
			return [delete, pin, mute]
		}
 
   return [delete, pin, mute]
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 76
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return realmPinnedConversations.count
    } else {
      return realmUnpinnedConversations.count
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as? UserCell ?? UserCell()
    
    if indexPath.section == 0 {
      cell.configureCell(for: indexPath, conversations: Array(realmPinnedConversations))
    } else {
      cell.configureCell(for: indexPath, conversations: Array(realmUnpinnedConversations))
    }

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var conversation: Conversation!

    if indexPath.section == 0 {
      let pinnedConversation = realmPinnedConversations[indexPath.row]
      conversation = pinnedConversation
    } else {
      let unpinnedConversation = realmUnpinnedConversations[indexPath.row]
      conversation = unpinnedConversation
    }
    chatLogPresenter.open(conversation)
  }
}

extension ChatsTableViewController: DeleteAndExitDelegate {
  func deleteAndExit(from conversationID: String) {
    
    let pinnedIDs = realmPinnedConversations.map({$0.chatID ?? ""})
    let section = pinnedIDs.contains(conversationID) ? 0 : 1
    guard let row = conversationIndex(for: conversationID, at: section) else { return }
  
    let indexPath = IndexPath(row: row, section: section)
    deleteConversation(at: indexPath)
  }
  
  func conversationIndex(for conversationID: String, at section: Int) -> Int? {
    let conversationsArray = section == 0 ? realmPinnedConversations : realmUnpinnedConversations
		guard let index = conversationsArray?.index(where: { (conversation) -> Bool in
      guard let chatID = conversation.chatID else { return false }
      return chatID == conversationID
    }) else { return nil }
    return index
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
    
//    let (pinned, unpinned) = conversations.stablePartition { (element) -> Bool in
//      let isPinned = element.pinned.value ?? false
//      return isPinned == true
//    }

   // self.conversations = unpinned
    //self.pinnedConversations = pinned

//guard let token1 = pinnedConversationsNotificationToken, let token2 = unpinnedConversationsNotificationToken else { return }

//		DispatchQueue.global(qos: .userInitiated).async {
//			autoreleasepool {
//				let realm = try! Realm()
//
//				realm.beginWrite()
//				for conversation in conversations {
//					realm.create(Conversation.self, value: conversation, update: true)
//				}
//				try! realm.commitWrite(withoutNotifying: [self.pinnedConversationsNotificationToken!, self.unpinnedConversationsNotificationToken!])
//
//			}
//		}

		realmManager.update(conversations: conversations)
		self.handleReloadTable()
		self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .mediumHigh)
	//	realmUpdate(conversations: unpinned)
	//	realmUpdate(conversations: pinned)
		
    

  }




  func conversations(update conversation: Conversation, reloadNeeded: Bool) {
   //let chatID = conversation.chatID ?? ""
    
//    if let index = conversations.index(where: {$0.chatID == chatID}) {
//      conversations[index] = conversation
//			realmUpdate(conversation: conversation)
//    }



//	realmManager.update(conversation: conversation)



//	guard let token1 = pinnedConversationsNotificationToken, let token2 = unpinnedConversationsNotificationToken else { return }

//    if let index = realmPinnedConversations.index(where: {$0.chatID == chatID}) {
//     // pinnedConversations[index] = conversation
//		//	realmUpdate(conversation: conversation)
//
////    if let index = filtededConversations.index(where: {$0.chatID == chatID}) {
////      filtededConversations[index] = conversation
////			realmUpdate(conversation: conversation)
//
//
////			realmManager.realm.beginWrite()
////			realmManager.realm.create(Conversation.self, value: conversation, update: true)
////			try! realmManager.realm.commitWrite(withoutNotifying: [token1, token2])
////
//			realmManager.update(conversation: conversation)
//      let indexPath = IndexPath(row: index, section: 1)
//      if reloadNeeded { updateCell(at: indexPath) }
////
//   }


  //  if let index = realmUnpinnedConversations.index(where: {$0.chatID == chatID}) {
    //  filteredPinnedConversations[index] = conversation
		//	realmUpdate(conversation: conversation)

//			realmManager.realm.beginWrite()
//			realmManager.realm.create(Conversation.self, value: conversation, update: true)
//			try! realmManager.realm.commitWrite()//(withoutNotifying: [token1, token2])

			realmManager.update(conversation: conversation)
    //  let indexPath = IndexPath(row: index, section: 0)
     // if reloadNeeded { updateCell(at: indexPath) }
  //  }

   // let allConversations = conversations + pinnedConversations
    notificationsManager.updateConversations(to: Array(realmAllConversations))
    navigationItemActivityIndicator.hideActivityIndicator(for: navigationItem, activityPriority: .lowMedium)
  }
  
  func conversations(didRemove: Bool, chatID: String) {
    typingIndicatorManager.removeTypingIndicator(for: chatID)
  }
  
  func conversations(addedNewConversation: Bool, chatID: String) {
    guard isAppLoaded else { return }
    typingIndicatorManager.observeChangesForDefaultTypingIndicator(with: chatID)
    typingIndicatorManager.observeChangesForGroupTypingIndicator(with: chatID)
  }
}
