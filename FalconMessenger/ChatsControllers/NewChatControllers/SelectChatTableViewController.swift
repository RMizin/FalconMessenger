//
//  SelectChatTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/6/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import PhoneNumberKit
import SDWebImage
import Contacts

private let falconUsersCellID = "falconUsersCellID"
private let newGroupCellID = "newGroupCellID"

class SelectChatTableViewController: UITableViewController {
  
  let newGroupAction = "New Group"
  var actions = ["New Group"]
  var users = [User]()
  var filteredUsers = [User]()
  var filteredUsersWithSection = [[User]]()
  var collation = UILocalizedIndexedCollation.current()
  var sectionTitles = [String]()
  var searchBar: UISearchBar?
  var phoneNumberKit = PhoneNumberKit()
  let viewPlaceholder = ViewPlaceholder()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureController()
    setupSearchController()
  }

  @objc fileprivate func updateUsers() {
    self.users = RealmKeychain.realmUsersArray()
    self.filteredUsers = RealmKeychain.realmUsersArray()
    
    if !(RealmKeychain.realmUsersArray().count == 0) {
      self.viewPlaceholder.remove(from: self.view, priority: .high)
    }
    
    if self.searchBar != nil && !self.searchBar!.isFirstResponder {
      self.setUpCollation()
    }
    
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
  
  deinit {
    print("new chat deinit")
    NotificationCenter.default.removeObserver(self)
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }
  
  fileprivate func configureController() {
    navigationItem.title = "New Message"
    
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
      navigationController?.navigationBar.prefersLargeTitles = true
    }
    extendedLayoutIncludesOpaqueBars = true
    definesPresentationContext = true
    edgesForExtendedLayout = [UIRectEdge.top, UIRectEdge.bottom]
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
    tableView.separatorStyle = .none
  }
  
  fileprivate func deselectItem() {
    guard DeviceType.isIPad else { return }
    if let indexPath = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  @objc fileprivate func dismissNavigationController() {
    dismiss(animated: true, completion: nil)
  }

  fileprivate func setupSearchController() {
    searchBar = UISearchBar()
    searchBar?.delegate = self
    searchBar?.searchBarStyle = .minimal
    searchBar?.changeBackgroundColor(to: ThemeManager.currentTheme().searchBarColor)
    searchBar?.placeholder = "Search"
    searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
    tableView.tableHeaderView = searchBar
  }
  
  func checkContactsAuthorizationStatus() -> Bool {
    let contactsAuthorityCheck = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
    
    switch contactsAuthorityCheck {
    case .denied, .notDetermined, .restricted:
      viewPlaceholder.add(for: self.view, title: .denied, subtitle: .denied, priority: .high, position: .center)
      return false
    case .authorized:
      viewPlaceholder.remove(from: self.view, priority: .high)
      return true
		@unknown default:
			fatalError()
		}
  }

  func checkNumberOfContacts() {
    guard users.count == 0 else { return }
    viewPlaceholder.add(for: self.view, title: .empty, subtitle: .empty, priority: .low, position: .center)
  }

  fileprivate func correctSearchBarForCurrentIOSVersion() -> UISearchBar {
    var searchBar: UISearchBar!
    searchBar = self.searchBar
   
    return searchBar
  }
  
  @objc func setUpCollation() {
    let (arrayContacts, arrayTitles) = collation.partitionObjects(array: self.filteredUsers,
                                                                  collationStringSelector: #selector(getter: User.name))
    guard let contacts = arrayContacts as? [[User]] else { return }
    filteredUsersWithSection = contacts
    sectionTitles = arrayTitles
    setupHeaderSectionWithControls()
  }

  fileprivate func setupHeaderSectionWithControls() {
    sectionTitles.insert("", at: 0)
    filteredUsersWithSection.insert([User](), at: 0)
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return sectionTitles.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return actions.count
    } else {
      return filteredUsersWithSection[section].count
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 65
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sectionTitles[section]
  }
  
  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    return sectionTitles
  }

  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
    if let headerTitle = view as? UITableViewHeaderFooterView {
      headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
      headerTitle.textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 25
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return selectCell(for: indexPath)
  }
  
  func selectCell(for indexPath: IndexPath) -> UITableViewCell {
    let headerSection = 0
    if indexPath.section == headerSection {
      let defaultCell = UITableViewCell(style: .default, reuseIdentifier: newGroupCellID)
      let cell = tableView.dequeueReusableCell(withIdentifier: newGroupCellID) ?? defaultCell
      cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      cell.imageView?.image = UIImage(named: "groupChat")
      cell.imageView?.contentMode = .scaleAspectFit
      cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
      cell.textLabel?.text = actions[indexPath.row]
      cell.textLabel?.textColor = ThemeManager.currentTheme().controlButtonTintColor

      return cell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID,
                                             for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
    let falconUser = filteredUsersWithSection[indexPath.section][indexPath.row]
    cell.configureCell(for: falconUser)
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		searchBar?.resignFirstResponder()

    if indexPath.section == 0 {
      let destination = SelectGroupMembersController()
      let users = blacklistManager.removeBannedUsers(users: RealmKeychain.realmUsersArray())
      destination.users = users
      destination.filteredUsers = users
      destination.setUpCollation()
      self.navigationController?.pushViewController(destination, animated: true)
    } else {
      let falconUser = filteredUsersWithSection[indexPath.section][indexPath.row]
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }
			guard let id = falconUser.id, let conversation = RealmKeychain.defaultRealm.objects(Conversation.self).filter("chatID == %@", id).first else {
				let conversationDictionary = ["chatID": falconUser.id as AnyObject,
																			"chatName": falconUser.name as AnyObject,
																			"isGroupChat": false  as AnyObject,
																			"chatOriginalPhotoURL": falconUser.photoURL as AnyObject,
																			"chatThumbnailPhotoURL": falconUser.thumbnailPhotoURL as AnyObject,
																			"chatParticipantsIDs": [falconUser.id, currentUserID] as AnyObject]
				let conversation = Conversation(dictionary: conversationDictionary)
                chatLogPresenter.open(conversation, controller: self)
				return
			}

        chatLogPresenter.open(conversation, controller: self)
    }
  }
}
