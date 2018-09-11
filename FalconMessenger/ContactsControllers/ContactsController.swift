//
//  ContactsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Contacts
import Firebase
import SDWebImage
import PhoneNumberKit

private let falconUsersCellID = "falconUsersCellID"
private let currentUserCellID = "currentUserCellID"

class ContactsController: UITableViewController {
  
  var contacts = [CNContact]()
  var filteredContacts = [CNContact]()
  var users = [User]()
  var filteredUsers = [User]()
  
  var searchBar: UISearchBar?
  var searchContactsController: UISearchController?
  
  let phoneNumberKit = PhoneNumberKit()
  let viewPlaceholder = ViewPlaceholder()
  let falconUsersFetcher = FalconUsersFetcher()
  let contactsFetcher = ContactsFetcher()
  let navigationItemActivityIndicator = NavigationItemActivityIndicator()

    override func viewDidLoad() {
        super.viewDidLoad()

      configureViewController()
      setupSearchController()
      addContactsObserver()
      addObservers()
      DispatchQueue.global(qos: .default).async { [unowned self] in
        self.falconUsersFetcher.loadFalconUsers()
        self.contactsFetcher.fetchContacts()
      }
    }
  
    deinit {
      NotificationCenter.default.removeObserver(self)
    }
  
    fileprivate var shouldReSyncUsers = false
  
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      guard shouldReSyncUsers else { return }
      shouldReSyncUsers = false
      falconUsersFetcher.loadFalconUsers()
      contactsFetcher.syncronizeContacts(contacts: contacts)
    }
  
    fileprivate func deselectItem() {
      guard DeviceType.isIPad else { return }
      if let indexPath = tableView.indexPathForSelectedRow {
        tableView.deselectRow(at: indexPath, animated: true)
      }
    }
  
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return ThemeManager.currentTheme().statusBarStyle
    }
  
    fileprivate func configureViewController() {
      falconUsersFetcher.delegate = self
      contactsFetcher.delegate = self
      extendedLayoutIncludesOpaqueBars = true
      definesPresentationContext = true
      edgesForExtendedLayout = UIRectEdge.top
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
      tableView.sectionIndexBackgroundColor = view.backgroundColor
      tableView.backgroundColor = view.backgroundColor
      tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
      tableView.register(CurrentUserTableViewCell.self, forCellReuseIdentifier: currentUserCellID)
      tableView.separatorStyle = .none
    }
  
    fileprivate func setupSearchController() {
      if #available(iOS 11.0, *) {
        searchContactsController = UISearchController(searchResultsController: nil)
        searchContactsController?.searchResultsUpdater = self
        searchContactsController?.obscuresBackgroundDuringPresentation = false
        searchContactsController?.searchBar.delegate = self
        navigationItem.searchController = searchContactsController
      } else {
        searchBar = UISearchBar()
        searchBar?.delegate = self
        searchBar?.placeholder = "Search"
        searchBar?.searchBarStyle = .minimal
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        tableView.tableHeaderView = searchBar
      }
    }
  
    fileprivate func addContactsObserver() {
      NotificationCenter.default.addObserver(self, selector: #selector(contactStoreDidChange), name: .CNContactStoreDidChange, object: nil)
    }
    fileprivate func removeContactsObserver() {
      NotificationCenter.default.removeObserver(self, name: .CNContactStoreDidChange, object: nil)
    }
  
    fileprivate func addObservers() {
      NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(cleanUpController), name: NSNotification.Name(rawValue: "clearUserData"), object: nil)
    }
  
    @objc func contactStoreDidChange(notification: NSNotification) {
      guard Auth.auth().currentUser != nil else { return }
      removeContactsObserver()
      DispatchQueue.global(qos: .default).async { [unowned self] in
        print("start fetch")
        self.falconUsersFetcher.loadFalconUsers()
        self.contactsFetcher.fetchContacts()
      }
    }
  
    @objc fileprivate func changeTheme() {
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.sectionIndexBackgroundColor = view.backgroundColor
      tableView.backgroundColor = view.backgroundColor
      tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
      tableView.reloadData()
      
      navigationItemActivityIndicator.activityIndicatorView.color = ThemeManager.currentTheme().generalTitleColor
      navigationItemActivityIndicator.titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    }
  
    @objc func cleanUpController() {
      filteredUsers.removeAll()
      users.removeAll()
      tableView.reloadData()
      shouldReSyncUsers = true
      userDefaults.removeObject(for: userDefaults.contactsCount)
      userDefaults.removeObject(for: userDefaults.contactsSyncronizationStatus)
    }
  
    fileprivate var isAppLoaded = false
    fileprivate func reloadTableView(updatedUsers: [User]) {
     
      let searchBar = correctSearchBarForCurrentIOSVersion()
      let isSearchInactive = searchBar.text?.isEmpty ?? true
    //  let isSearchControllerEmpty = filteredUsers.count == 0
      guard isSearchInactive else { return }
   //   if isSearchInProgress && !isSearchControllerEmpty { return } else {
        users = updatedUsers
        filteredUsers = users
      
        guard isAppLoaded == false else {
          DispatchQueue.main.async {
            self.tableView.reloadData()
          }; return
        }
        isAppLoaded = true
        UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()}, completion: nil)
     // }
    }
  
    fileprivate func correctSearchBarForCurrentIOSVersion() -> UISearchBar {
      var searchBar = UISearchBar()
      if #available(iOS 11.0, *) {
        searchBar = searchContactsController?.searchBar ?? searchBar
      } else {
        searchBar = self.searchBar ?? searchBar
      }
      return searchBar
    }
  
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
      return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == 0 {
        return 1
      } else if section == 1 {
        return filteredUsers.count
      } else {
        return filteredContacts.count
      }
    }
  
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 65
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      if section == 0 { return " " }
      guard section == 2, filteredContacts.count != 0 else { return "" }
      return " "
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      if section == 0 { return 10 }
      guard section == 2, filteredContacts.count != 0 else { return 0 }
      return 8
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
      view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
      guard section == 2 else { return }
      view.tintColor = ThemeManager.currentTheme().inputTextViewColor
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if indexPath.section == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: currentUserCellID, for: indexPath) as? CurrentUserTableViewCell ?? CurrentUserTableViewCell()
        cell.title.text = NameConstants.personalStorage
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID, for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
        let parameter = indexPath.section == 1 ? filteredUsers[indexPath.row] : filteredContacts[indexPath.row]
        cell.configureCell(for: parameter)
        return cell
      }
    }

    var chatLogController: ChatLogViewController? = nil
    var messagesFetcher: MessagesFetcher? = nil
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }
      
      if chatLogController != nil && DeviceType.isIPad { //bugfix
        chatLogController?.closeChatLog()
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
      }
      
      if indexPath.section == 0 {
     
        let conversationDictionary: [String: AnyObject] = ["chatID": currentUserID as AnyObject,
                                                          "isGroupChat": false  as AnyObject,
                                                          "chatParticipantsIDs": [currentUserID] as AnyObject]
        
        let conversation = Conversation(dictionary: conversationDictionary)
        chatLogController = ChatLogViewController()
        
        messagesFetcher = MessagesFetcher()
        messagesFetcher?.delegate = self
        messagesFetcher?.loadMessagesData(for: conversation)
      }
      
      if indexPath.section == 1 {
        let conversationDictionary: [String: AnyObject] = ["chatID": filteredUsers[indexPath.row].id as AnyObject,
                                                           "chatName": filteredUsers[indexPath.row].name as AnyObject,
                                                           "isGroupChat": false  as AnyObject,
                                                           "chatOriginalPhotoURL": filteredUsers[indexPath.row].photoURL as AnyObject,
                                                           "chatThumbnailPhotoURL": filteredUsers[indexPath.row].thumbnailPhotoURL as AnyObject,
                                                           "chatParticipantsIDs": [filteredUsers[indexPath.row].id, currentUserID] as AnyObject]
        
        let conversation = Conversation(dictionary: conversationDictionary)
        chatLogController = ChatLogViewController()
        messagesFetcher = MessagesFetcher()
        messagesFetcher?.delegate = self
        messagesFetcher?.loadMessagesData(for: conversation)
      }
    
      if indexPath.section == 2 {
        let destination = ContactsDetailController()
        destination.contactName = filteredContacts[indexPath.row].givenName + " " + filteredContacts[indexPath.row].familyName
        if let photo = filteredContacts[indexPath.row].thumbnailImageData {
          destination.contactPhoto = UIImage(data: photo)
        }
        destination.contactPhoneNumbers.removeAll()
        destination.hidesBottomBarWhenPushed = true
        destination.contactPhoneNumbers = filteredContacts[indexPath.row].phoneNumbers
        navigationController?.pushViewController(destination, animated: true)
      }
    }
}

extension ContactsController: FalconUsersUpdatesDelegate { 
  func falconUsers(shouldBeUpdatedTo users: [User]) {
    globalDataStorage.falconUsers = users
    reloadTableView(updatedUsers: users)
    
    let syncronizationStatus = userDefaults.currentBoolObjectState(for: userDefaults.contactsSyncronizationStatus)
    guard syncronizationStatus == true else { return }
    addContactsObserver()
    DispatchQueue.main.async {
      self.navigationItemActivityIndicator.hideActivityIndicator(for: self.navigationItem, activityPriority: .medium)
    }
  }
}

extension ContactsController: ContactsUpdatesDelegate {
  func contacts(shouldPerformSyncronization: Bool) {
    guard shouldPerformSyncronization else { return }
    
    DispatchQueue.main.async { [unowned self] in
      self.navigationItemActivityIndicator.showActivityIndicator(for: self.navigationItem, with: .updatingUsers, activityPriority: .medium, color: ThemeManager.currentTheme().generalTitleColor)
    }
    
    DispatchQueue.global(qos: .default).async { [unowned self] in
      self.falconUsersFetcher.loadAndSyncFalconUsers()
    }
  }
  
  func contacts(updateDatasource contacts: [CNContact]) {
    self.contacts = contacts
    self.filteredContacts = contacts
    DispatchQueue.main.async { [unowned self] in
      self.tableView.reloadData()
    }
  }
  
  func contacts(handleAccessStatus: Bool) {
    guard handleAccessStatus else {
      viewPlaceholder.add(for: view, title: .denied, subtitle: .denied, priority: .high, position: .top)
      return
    }
    viewPlaceholder.remove(from: view, priority: .high)
  }
}

extension ContactsController: MessagesDelegate {
  
  func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
    chatLogController?.updateMessageStatus(messageRef: reference)
  }
  
  func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
    chatLogController?.hidesBottomBarWhenPushed = true
    chatLogController?.messagesFetcher = messagesFetcher
    chatLogController?.messages = messages
    chatLogController?.conversation = conversation
    chatLogController?.groupedMessages = Message.groupedMessages(messages)
    chatLogController?.observeTypingIndicator()
    chatLogController?.configureTitleViewWithOnlineStatus()
    chatLogController?.observeBlockChanges()
    chatLogController?.messagesFetcher?.collectionDelegate = chatLogController
    guard let destination = chatLogController else { return }
        
    if DeviceType.isIPad {
      let navigationController = UINavigationController(rootViewController: destination)
      splitViewController?.showDetailViewController(navigationController, sender: self)
    } else {
      navigationController?.pushViewController(destination, animated: true)
      chatLogController = nil
      messagesFetcher?.delegate = nil
      messagesFetcher = nil
    }
    deselectItem()
  }
}
