//
//  ContactsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Contacts
import FirebaseAuth
import FirebaseDatabase
import SDWebImage
import PhoneNumberKit
import RealmSwift

private let falconUsersCellID = "falconUsersCellID"
private let currentUserCellID = "currentUserCellID"

class ContactsController: FalconTableViewController {

	let chatLogPresenter = ChatLogPresenter()

  var contacts = [CNContact]()
  var filteredContacts = [CNContact]()
  var users: Results<User>?

  var searchBar: UISearchBar?
  var searchContactsController: UISearchController?

  let phoneNumberKit = PhoneNumberKit()
  //let viewPlaceholder = ViewPlaceholder()
  let falconUsersFetcher = FalconUsersFetcher()
  let contactsFetcher = ContactsFetcher()

	let realm = try! Realm(configuration: RealmKeychain.realmUsersConfiguration())

    override func viewDidLoad() {
        super.viewDidLoad()

      configureViewController()
      setupSearchController()
      addContactsObserver()
      addObservers()
			setupDataSource()
      DispatchQueue.global(qos: .userInteractive).async { [weak self] in
        self?.falconUsersFetcher.loadFalconUsers()
        self?.contactsFetcher.fetchContacts()
      }
    }

    deinit {
			stopContiniousUpdate()
      NotificationCenter.default.removeObserver(self)
    }

		func setupDataSource() {
			users = realm.objects(User.self).sorted(byKeyPath: "onlineStatusSortDescriptor", ascending: false)
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
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(contactStoreDidChange),
                                             name: .CNContactStoreDidChange,
                                             object: nil)
    }

    fileprivate func removeContactsObserver() {
      NotificationCenter.default.removeObserver(self, name: .CNContactStoreDidChange, object: nil)
    }

    fileprivate func addObservers() {
      NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(cleanUpController),
                                             name: NSNotification.Name(rawValue: "clearUserData"),
                                             object: nil)
    }
  
    @objc func contactStoreDidChange(notification: NSNotification) {
      guard Auth.auth().currentUser != nil else { return }
      removeContactsObserver()
      DispatchQueue.global(qos: .userInteractive).async { [weak self] in
        print("start fetch")
        self?.falconUsersFetcher.loadFalconUsers()
        self?.contactsFetcher.fetchContacts()
      }
    }

    @objc fileprivate func changeTheme() {
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.sectionIndexBackgroundColor = view.backgroundColor
      tableView.backgroundColor = view.backgroundColor
      tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
      tableView.reloadData()

     // navigationItemActivityIndicator.activityIndicatorView.color = ThemeManager.currentTheme().generalTitleColor
     // navigationItemActivityIndicator.titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    }

    @objc func cleanUpController() {
			stopContiniousUpdate()
			func deleteAll() {
				do {
					try realm.safeWrite {
						realm.deleteAll()
					}
				} catch {}
			}

			deleteAll()
      shouldReSyncUsers = true
      userDefaults.removeObject(for: userDefaults.contactsCount)
      userDefaults.removeObject(for: userDefaults.contactsSyncronizationStatus)
    }

	fileprivate var isAppLoaded = false

	fileprivate func reloadTableView(updatedUsers: [User]) {
		continiousUIUpdate(users: updatedUsers)
	}

	fileprivate var updateUITimer: DispatchSourceTimer?

	fileprivate func continiousUIUpdate(users: [User]) {
		guard users.count > 0 else { return }
		updateUITimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
		updateUITimer?.schedule(deadline: .now(), repeating: .seconds(60))
		updateUITimer?.setEventHandler { [weak self] in
			guard let unwrappedSelf = self else { return }
			unwrappedSelf.performUIUpdate(users: users)
		}
		updateUITimer?.resume()
	}

	fileprivate func performUIUpdate(users: [User]) {
		autoreleasepool {
			if !realm.isInWriteTransaction {
				realm.beginWrite()
				for user in users {
					user.onlineStatusString = user.stringStatus(onlineStatus: user.onlineStatus)
					realm.create(User.self, value: user, update: .modified)
				}
				try! realm.commitWrite()
			}
		}

		guard isAppLoaded == false else {
			DispatchQueue.main.async { [weak self] in
				self?.tableView.reloadData()
			}
			return
		}

		isAppLoaded = true
		UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { [weak self] in
			self?.tableView.reloadData()
		}, completion: nil)
	}

	fileprivate func stopContiniousUpdate() {
		updateUITimer?.cancel()
		updateUITimer = nil
	}
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
      return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == 0 {
        return 1
      } else if section == 1 {
				return users?.count ?? 0
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
        let cell = tableView.dequeueReusableCell(withIdentifier: currentUserCellID,
                                                 for: indexPath) as? CurrentUserTableViewCell ?? CurrentUserTableViewCell()
        cell.title.text = NameConstants.personalStorage
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID,
                                                 for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
				let parameter = indexPath.section == 1 ? users?[indexPath.row] : filteredContacts[indexPath.row]
        cell.configureCell(for: parameter)
        return cell
      }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }

			searchBar?.resignFirstResponder()
			searchContactsController?.searchBar.resignFirstResponder()

      if indexPath.section == 0 {
				guard let conversation = RealmKeychain.defaultRealm.objects(Conversation.self).filter("chatID == %@", currentUserID).first else {
					let conversationDictionary = ["chatID": currentUserID as AnyObject,
																				"chatName": NameConstants.personalStorage as AnyObject,
																			  "isGroupChat": false  as AnyObject,
																				"chatParticipantsIDs": [currentUserID] as AnyObject]
					let conversation = Conversation(dictionary: conversationDictionary)
                    chatLogPresenter.open(conversation, controller: self)
					return
				}
        chatLogPresenter.open(conversation, controller: self)

      } else if indexPath.section == 1 {
					guard let id = users?[indexPath.row].id, let conversation = RealmKeychain.defaultRealm.objects(Conversation.self).filter("chatID == %@", id).first else {
						let conversationDictionary = ["chatID": users?[indexPath.row].id as AnyObject,
																					"chatName": users?[indexPath.row].name as AnyObject,
																			   	"isGroupChat": false as AnyObject,
																				  "chatOriginalPhotoURL": users?[indexPath.row].photoURL as AnyObject,
																				  "chatThumbnailPhotoURL": users?[indexPath.row].thumbnailPhotoURL as AnyObject,
																			  	"chatParticipantsIDs": [users?[indexPath.row].id, currentUserID] as AnyObject]
					let conversation = Conversation(dictionary: conversationDictionary)
                        chatLogPresenter.open(conversation, controller: self)

					return
				}
        chatLogPresenter.open(conversation, controller: self)
      } else if indexPath.section == 2 {
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
    reloadTableView(updatedUsers: users)

    let syncronizationStatus = userDefaults.currentBoolObjectState(for: userDefaults.contactsSyncronizationStatus)
    guard syncronizationStatus == true else { return }
    addContactsObserver()
		DispatchQueue.main.async { [weak self] in
			self?.navigationItem.hideActivityView(with: .updatingUsers)
		}
  }
}

extension ContactsController: ContactsUpdatesDelegate {
  func contacts(shouldPerformSyncronization: Bool) {
		guard shouldPerformSyncronization else { return }
		DispatchQueue.main.async { [weak self] in
			self?.navigationItem.showActivityView(with: .updatingUsers)
		}
    DispatchQueue.global(qos: .userInteractive).async { [weak self] in
      self?.falconUsersFetcher.loadAndSyncFalconUsers()
    }
  }

  func contacts(updateDatasource contacts: [CNContact]) {
    self.contacts = contacts
    self.filteredContacts = contacts
    DispatchQueue.main.async { [weak self] in
			UIView.performWithoutAnimation {
				self?.tableView.reloadSections([2], with: .none)
			}
    }
  }

  func contacts(handleAccessStatus: Bool) {
//    guard handleAccessStatus, (users?.count ?? 0) > 0 else {
//      viewPlaceholder.add(for: view, title: .denied, subtitle: .denied, priority: .high, position: .top)
//      return
//    }
//    viewPlaceholder.remove(from: view, priority: .high)
  }
}
