//
//  ChatsTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SDWebImage
import RealmSwift

protocol ManageAppearance: class {
  func manageAppearance(_ chatsController: ChatsTableViewController, didFinishLoadingWith state: Bool )
}
 
class ChatsTableViewController: FalconTableViewController {
  
  fileprivate let userCellID = "userCellID"
  fileprivate var isAppLoaded = false
  
  weak var delegate: ManageAppearance?
  
  var searchBar: UISearchBar?
  var searchChatsController: UISearchController?
	let viewPlaceholder = ViewPlaceholder()

  let conversationsFetcher = ConversationsFetcher()
  let notificationsManager = InAppNotificationManager()
	let realmManager = ChatsRealmManager()

	var pinnedConversationsNotificationToken: NotificationToken?
	var unpinnedConversationsNotificationToken: NotificationToken?

	var realmPinnedConversations: Results<Conversation>?
	var realmUnpinnedConversations: Results<Conversation>?
	var realmAllConversations: Results<Conversation>?

	let fnavigationItem = FalconNavigationItem()

  override func viewDidLoad() {
    super.viewDidLoad()

    configureTableView()
    setupSearchController()
    addObservers()
  }

    func setupDataSource() {
        let objects = RealmKeychain.defaultRealm.objects(Conversation.self)
        let pinnedObjects = objects.filter("pinned == true").sorted(byKeyPath: "lastMessageTimestamp", ascending: false)
        let unpinnedObjects = objects.filter("pinned != true").sorted(byKeyPath: "lastMessageTimestamp", ascending: false)
        realmPinnedConversations = pinnedObjects
        realmUnpinnedConversations = unpinnedObjects
        realmAllConversations = objects
    }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    initializeDataSource()

  }

    @objc private func initializeDataSource() {
        guard !isAppLoaded, Auth.auth().currentUser != nil else { return }
        conversationsFetcher.fetchConversations()
        setupDataSource()
        managePresense()
    }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }


  fileprivate func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(initializeDataSource), name: .authenticationSucceeded, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleReloadTable), name: .messageSent, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(cleanUpController), name: NSNotification.Name(rawValue: "clearUserData"), object: nil)
  }
  
  @objc fileprivate func changeTheme() {
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.isOpaque = true
    tableView.reloadData()
  }

  fileprivate func initAllTabs() {
    guard let appDelegate = tabBarController as? GeneralTabBarController else { return }
    _ = appDelegate.contactsController.view
    _ = appDelegate.settingsController.view
  }
  
  @objc public func cleanUpController() {
		notificationsManager.removeAllObservers()
		conversationsFetcher.removeAllObservers()
		realmManager.deleteAll()
    isAppLoaded = false
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

	fileprivate func indexPathsToUpdate(updates: [Int], section: Int) -> [IndexPath] {
		return updates.compactMap({ [unowned self] (index) -> IndexPath? in
			if self.tableView.hasRow(at: IndexPath(row: index, section: section)) {
				return IndexPath(row: index, section: section)
			} else {
				return nil
			}
		})
	}

	fileprivate func observeDataSourceChanges() {
		pinnedConversationsNotificationToken = realmPinnedConversations?.observe { [weak self] (changes: RealmCollectionChange) in
			guard let unwrappedSelf = self else { return }
			switch changes {
			case .initial:
				break
			case .update(_, let deletions, let insertions, let modifications):
				if unwrappedSelf.isAppLoaded {
					unwrappedSelf.tableView.beginUpdates()
					unwrappedSelf.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .none)
					unwrappedSelf.tableView.deleteRows(at: unwrappedSelf.indexPathsToUpdate(updates: deletions, section: 0), with: .automatic)
					UIView.performWithoutAnimation { unwrappedSelf.tableView.reloadRows(at: unwrappedSelf.indexPathsToUpdate(updates: modifications, section: 0), with: .none) }
					unwrappedSelf.tableView.endUpdates()
				}

				break
			case .error(let err): fatalError("\(err)"); break
			}
		}

		unpinnedConversationsNotificationToken = realmUnpinnedConversations?.observe { [weak self] (changes: RealmCollectionChange) in
			guard let unwrappedSelf = self else { return }
			switch changes {
			case .initial:
				UIView.performWithoutAnimation { unwrappedSelf.tableView.reloadData() }
				break
			case .update(_, let deletions, let insertions, let modifications):
				if unwrappedSelf.isAppLoaded {
					unwrappedSelf.tableView.beginUpdates()
					unwrappedSelf.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 1) }, with: .none)
					unwrappedSelf.tableView.deleteRows(at: unwrappedSelf.indexPathsToUpdate(updates: deletions, section: 1), with: .automatic)
					UIView.performWithoutAnimation { unwrappedSelf.tableView.reloadRows(at: unwrappedSelf.indexPathsToUpdate(updates: modifications, section: 1), with: .none) }
					unwrappedSelf.tableView.endUpdates()
				}
				break
			case .error(let err): fatalError("\(err)"); break
			}
		}
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
      destination.users = RealmKeychain.realmUsersArray()
      destination.filteredUsers = RealmKeychain.realmUsersArray()
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

	fileprivate func showActivityTitle(title: UINavigationItemTitle) {
		navigationItem.showActivityView(with: title)
	}

	fileprivate func hideActivityTitle(title: UINavigationItemTitle) {
		navigationItem.hideActivityView(with: title)
	}
  
  fileprivate func managePresense() {
    if currentReachabilityStatus == .notReachable {
			showActivityTitle(title: .connecting)
    }
    
    let connectedReference = Database.database().reference(withPath: ".info/connected")
    connectedReference.observe(.value, with: { [weak self] (snapshot) in
      
      if self?.currentReachabilityStatus != .notReachable {
				self?.hideActivityTitle(title: .noInternet)
      } else {
				self?.showActivityTitle(title: .noInternet)
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
    guard let tabItems = tabBarController?.tabBar.items as NSArray? else { return }
    guard let tabItem = tabItems[Tabs.chats.rawValue] as? UITabBarItem else { return }
		guard let realmAllConversations = realmAllConversations else { return }
		let badge = realmAllConversations.compactMap({ (conversation) -> Int in
			return conversation.badge.value ?? 0
		}).reduce(0, +)

    guard badge > 0 else {
			tabItem.badgeValue = nil
      UIApplication.shared.applicationIconBadgeNumber = 0
      return
    }
    
    tabItem.badgeValue = badge.toString()
    UIApplication.shared.applicationIconBadgeNumber = badge
  }

	@objc func handleReloadTable() {

		realmPinnedConversations = realmPinnedConversations?.sorted(byKeyPath: "lastMessageTimestamp", ascending: false)
		realmUnpinnedConversations = realmUnpinnedConversations?.sorted(byKeyPath: "lastMessageTimestamp", ascending: false)

		guard let realmAllConversations = realmAllConversations else { return }

    if !isAppLoaded {
      UIView.transition(with: tableView,
												duration: 0.1,
												options: .transitionCrossDissolve,
												animations: { [weak self] in self?.tableView.reloadData() }, completion: { [weak self] (_) in
        self?.initAllTabs()

				for conversation in realmAllConversations {
          guard let chatID = conversation.chatID else { return }

          if let isGroupChat = conversation.isGroupChat.value, isGroupChat {
						if let uid = Auth.auth().currentUser?.uid, conversation.chatParticipantsIDs.contains(uid) {
							typingIndicatorManager.observeChangesForGroupTypingIndicator(with: chatID)
						}
          } else {
            typingIndicatorManager.observeChangesForDefaultTypingIndicator(with: chatID)
          }
        }
     })
    } else {
			DispatchQueue.main.async { [weak self] in
				UIView.performWithoutAnimation {
					self?.tableView.reloadData()
				}
			}
    }

		configureTabBarBadge()

    if realmAllConversations.count == 0 {
      checkIfThereAnyActiveChats(isEmpty: true)
    } else {
      checkIfThereAnyActiveChats(isEmpty: false)
    }
    
    guard !isAppLoaded else { return }
    delegate?.manageAppearance(self, didFinishLoadingWith: true)
    isAppLoaded = true
  }

    // MARK: - Table view data source
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard let realmPinnedConversations = realmPinnedConversations else { return "" }
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
		guard let realmPinnedConversations = realmPinnedConversations else { return 0 }
    if section == 0 {
      return 20
    } else {
      if realmPinnedConversations.count == 0 {
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

		if #available(iOS 11.0, *) {
			if navigationItem.searchController?.searchBar.text != "" { return [] }
		} else {
			if searchBar?.text != "" { return [] }
		}

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
			return realmPinnedConversations?.count ?? 0
    } else {
			return realmUnpinnedConversations?.count ?? 0
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as? UserCell ?? UserCell()

    if indexPath.section == 0 {
			guard let realmPinnedConversations = realmPinnedConversations else { return cell }
      cell.configureCell(for: indexPath, conversations: realmPinnedConversations)
    } else {
			guard let realmUnpinnedConversations = realmUnpinnedConversations else { return cell }
      cell.configureCell(for: indexPath, conversations: realmUnpinnedConversations)
    }

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var conversation: Conversation!

		searchBar?.resignFirstResponder()
		searchChatsController?.searchBar.resignFirstResponder()

    if indexPath.section == 0 {
			guard let realmPinnedConversations = realmPinnedConversations else { return }
      let pinnedConversation = realmPinnedConversations[indexPath.row]
      conversation = pinnedConversation
    } else {
			guard let realmUnpinnedConversations = realmUnpinnedConversations else { return }
      let unpinnedConversation = realmUnpinnedConversations[indexPath.row]
      conversation = unpinnedConversation
    }

    chatLogPresenter.open(conversation, controller: self)
  }
}

extension ChatsTableViewController: DeleteAndExitDelegate {
  func deleteAndExit(from conversationID: String) {
		guard let realmPinnedConversations = realmPinnedConversations else { return }
    let pinnedIDs = realmPinnedConversations.map({$0.chatID ?? ""})
    let section = pinnedIDs.contains(conversationID) ? 0 : 1
    guard let row = conversationIndex(for: conversationID, at: section) else { return }
  
    let indexPath = IndexPath(row: row, section: section)
    deleteConversation(at: indexPath)
  }
  
  func conversationIndex(for conversationID: String, at section: Int) -> Int? {
    let conversationsArray = section == 0 ? realmPinnedConversations : realmUnpinnedConversations
		guard let index = conversationsArray?.firstIndex(where: { (conversation) -> Bool in
      guard let chatID = conversation.chatID else { return false }
      return chatID == conversationID
    }) else { return nil }
    return index
  }
}

extension ChatsTableViewController: ConversationUpdatesDelegate {
  
  func conversations(didStartFetching: Bool) {
    guard !isAppLoaded else { return }
		showActivityTitle(title: .updating)
  }
  
  func conversations(didStartUpdatingData: Bool) {
		showActivityTitle(title: .updating)
  }
  
  func conversations(didFinishFetching: Bool, conversations: [Conversation]) {
    notificationsManager.observersForNotifications(conversations: conversations)
		if !isAppLoaded {
			observeDataSourceChanges()
		}

		guard let token1 = pinnedConversationsNotificationToken, let token2 = unpinnedConversationsNotificationToken else { return }
		realmManager.update(conversations: conversations, tokens: [token1, token2])
		handleReloadTable()
		hideActivityTitle(title: .updating)
  }

  func conversations(update conversation: Conversation, reloadNeeded: Bool) {
		realmManager.update(conversation: conversation)

		if let realmAllConversations = realmAllConversations {
			notificationsManager.updateConversations(to: Array(realmAllConversations))
		}

		hideActivityTitle(title: .updating)
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
