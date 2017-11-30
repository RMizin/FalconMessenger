//
//  ContactsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Contacts
import PhoneNumberKit
import Firebase
import SDWebImage


public var shouldReloadContactsControllerAfterChangingTheme = false


class ContactsController: UITableViewController {
  
  let phoneNumberKit = PhoneNumberKit()
  
  var contacts = [CNContact]()
  
  var filteredContacts = [CNContact]()
  
  var localPhones = [String]()
  
  var users = [User]()
  
  var filteredUsers = [User]()
  
  var currentUser: User?
  
  let contactsCellID = "contactsCellID"
  
  let pigeonUsersCellID = "pigeonUsersCellID"
  
  let currentUserCellID = "currentUserCellID"
  
  private let reloadAnimation = UITableViewRowAnimation.none
  
  var searchBar: UISearchBar?
    
  var searchContactsController: UISearchController?
  
  let contactsAuthorizationDeniedContainer:ContactsAuthorizationDeniedContainer! = ContactsAuthorizationDeniedContainer()
  

    override func viewDidLoad() {
        super.viewDidLoad()
      
      extendedLayoutIncludesOpaqueBars = true
      edgesForExtendedLayout = UIRectEdge.top
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.sectionIndexBackgroundColor = view.backgroundColor
      tableView.backgroundColor = view.backgroundColor

      setupTableView()
      setupSearchController()
      fetchContacts()
      checkContactsAuthorizationStatus()
    }
  
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
        checkContactsAuthorizationStatus()
        fetchCurrentUser()
        setUpColorsAccordingToTheme()
    }
  
    override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
      contactsAuthorizationDeniedContainer.frame = CGRect(x: 0, y: 135, width: self.view.bounds.width, height: 100)
      contactsAuthorizationDeniedContainer.layoutIfNeeded()
    }
  
  
  fileprivate func setUpColorsAccordingToTheme() {
    if shouldReloadContactsControllerAfterChangingTheme {
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.sectionIndexBackgroundColor = view.backgroundColor
      tableView.backgroundColor = view.backgroundColor
      tableView.reloadData()
      print("reloading")
      shouldReloadContactsControllerAfterChangingTheme = false
    }
  }
  
    fileprivate func setupTableView() {
        tableView.register(ContactsTableViewCell.self, forCellReuseIdentifier: contactsCellID)
        tableView.register(PigeonUsersTableViewCell.self, forCellReuseIdentifier: pigeonUsersCellID)
        tableView.register(CurrentUserTableViewCell.self, forCellReuseIdentifier: currentUserCellID)
        tableView.separatorStyle = .none
        tableView.prefetchDataSource = self
        definesPresentationContext = true
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
          searchBar?.searchBarStyle = .minimal
          searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
          tableView.tableHeaderView = searchBar
        }
    }
  
  
  fileprivate func checkContactsAuthorizationStatus() {
    let contactsAuthorityCheck = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
    
    switch contactsAuthorityCheck {
    case .denied, .notDetermined, .restricted:
      self.view.addSubview(contactsAuthorizationDeniedContainer)
      contactsAuthorizationDeniedContainer.frame = CGRect(x: 0, y: 135, width: self.view.bounds.width, height: 100)
      
    case .authorized:
      for subview in self.view.subviews {
        if subview is ContactsAuthorizationDeniedContainer {
          subview.removeFromSuperview()
        }
      }
    }
  }

  
  fileprivate func fetchCurrentUser() {
    guard let uid = Auth.auth().currentUser?.uid else {
      return
    }
    
    let userReference = Database.database().reference().child("users").child(uid)
    userReference.observe(.value) { (snapshot) in
      if snapshot.exists() {
        guard var dictionary = snapshot.value as? [String: AnyObject] else {
          return
        }
        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
        self.currentUser = User(dictionary: dictionary)
      }
    }
  }
  
  
 fileprivate func fetchContacts () {
    
    let status = CNContactStore.authorizationStatus(for: .contacts)
    if status == .denied || status == .restricted {
      presentSettingsActionSheet()
      return
    }
    
    // open it
    let store = CNContactStore()
    store.requestAccess(for: .contacts) { granted, error in
      guard granted else {
        DispatchQueue.main.async {
          self.presentSettingsActionSheet()
        }
        return
      }
      
      // get the contacts
      let request = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey as NSString, CNContactPhoneNumbersKey as NSString, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)])
      do {
        try store.enumerateContacts(with: request) { contact, stop in
          self.contacts.append(contact)
        }
      } catch {
        print(error)
      }
      
      self.localPhones.removeAll()
      self.filteredContacts = self.contacts

      for contact in self.contacts {
       
        for phone in contact.phoneNumbers {
        
          self.localPhones.append(phone.value.stringValue)
        }
      }
      
      self.fetchPigeonUsers()
      self.sendUserContactsToDatabase()
    }
  }
  
  
 fileprivate func rearrangeUsers() { /* Moves Online users to the top  */
    for index in 0...self.users.count - 1 {
      if self.users[index].onlineStatus == statusOnline {
        self.users = rearrange(array: self.users, fromIndex: index, toIndex: 0)
      }
    }
  }
  
 fileprivate func rearrangeFilteredUsers() { /* Moves Online users to the top  */
    for index in 0...self.filteredUsers.count - 1 {
      if self.filteredUsers[index].onlineStatus == statusOnline {
        self.filteredUsers = rearrange(array: self.filteredUsers, fromIndex: index, toIndex: 0)
      }
    }
  }
  
 fileprivate func sortUsers() { /* Sort users by las online date  */
    self.users.sort(by: { (user1, user2) -> Bool in
     return (user1.onlineStatus ?? "", user1.phoneNumber ?? "") > (user2.onlineStatus ?? "", user2.phoneNumber ?? "") // sort
    })
  }
  
  
 fileprivate func sendUserContactsToDatabase() {
    guard let uid = Auth.auth().currentUser?.uid else {
      return
    }
    
    let userReference = Database.database().reference().child("users").child(uid)
    var preparedNumbers = [String]()
  
    for number in localPhones {
      do {
        let countryCode = try self.phoneNumberKit.parse(number).countryCode
        let nationalNumber = try self.phoneNumberKit.parse(number).nationalNumber
        preparedNumbers.append( ("+" + String(countryCode) + String(nationalNumber)) )
      } catch {
        // print("Generic parser error")
      }
    }
    userReference.updateChildValues(["contacts": preparedNumbers])
  }
  
  
@objc fileprivate func fetchPigeonUsers() {

    var preparedNumber = String()
    users.removeAll()
    
    for number in localPhones {
      do {
        let countryCode = try self.phoneNumberKit.parse(number).countryCode
        let nationalNumber = try self.phoneNumberKit.parse(number).nationalNumber
        preparedNumber = "+" + String(countryCode) + String(nationalNumber)
      } catch {
       // print("Generic parser error")
      }

      var userRef: DatabaseQuery = Database.database().reference().child("users")
      userRef = userRef.queryOrdered(byChild: "phoneNumber").queryEqual(toValue: preparedNumber)
      userRef.keepSynced(true)
      userRef.observe( .value, with: { (snapshot) in
    
        if snapshot.exists() {
          // Initial load
          
          for child in snapshot.children.allObjects as! [DataSnapshot]  {
            guard var dictionary = child.value as? [String: AnyObject] else { return }
            dictionary.updateValue(child.key as AnyObject, forKey: "id")
            
            if let index = self.users.index(where: { (user) -> Bool in
              return user.id == User(dictionary: dictionary).id
            }) {
              print("Already contains updating")
              self.users[index] = User(dictionary: dictionary)
            } else {
              print("NOT CONTAINS APPENDING")
              self.users.append(User(dictionary: dictionary))
            }
            
            self.sortUsers()
            self.rearrangeUsers()

            if let index = self.users.index(where: { (user) -> Bool in
              return user.id == Auth.auth().currentUser?.uid
            }) {
               self.users.remove(at: index)
            }
            
            self.filteredUsers = self.users
          }
           self.reloadTableView(snap: snapshot)
        }
      }, withCancel: { (error) in
        //search error
      })
    }
  }
  

  fileprivate func reloadTableView(snap: DataSnapshot) {
    var searchBar: UISearchBar?
    if #available(iOS 11.0, *) {
      searchBar = self.searchContactsController?.searchBar
    } else {
      searchBar = self.searchBar
    }

    if searchBar?.text != "" && self.filteredUsers.count != 0 {
      guard var dictionary = snap.value as? [String: AnyObject] else {
        return
      }

      dictionary.updateValue(snap.key as AnyObject, forKey: "id")
      for index in 0...self.filteredUsers.count - 1  {
        if self.filteredUsers[index].id == snap.key {
          self.filteredUsers[index] = User(dictionary: dictionary)
          rearrangeUsers()
          rearrangeFilteredUsers()
          self.tableView.beginUpdates()
          for indexOfIndexPath in 0...self.filteredUsers.count - 1 {
            self.tableView.reloadRows(at: [IndexPath(row: indexOfIndexPath, section: 1)], with: self.reloadAnimation)
          }
          self.tableView.endUpdates()
        }
      }
    } else if self.filteredUsers.count == 0 {
    } else {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
 fileprivate func presentSettingsActionSheet() {
    let alert = UIAlertController(title: "Permission to Contacts", message: "Falcon messenger uses phone numbers as unique identifiers, so that it is easy for you to switch from other messaging apps and retain your social graph. We store your contacts in order to find your friends who also use Falcon. We only need the number and name (first and last) for this to work and store no other data about your contacts.", preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
      let url = URL(string: UIApplicationOpenSettingsURLString)!
      UIApplication.shared.open(url)
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
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
      if indexPath.section == 0 {
         return 100
      } else {
         return 65
      }
    }
  
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      
      if section == 0 {
        return ""
      } else if section == 1 {
      
        if filteredUsers.count == 0 {
          return ""
        } else {
          return "Falcon contacts"
        }
      } else {
        return "All contacts"
      }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
      view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
      
      if let headerTitle = view as? UITableViewHeaderFooterView {
        headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
      }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
     return selectCell(for: indexPath)!
    }
  
  
  func selectCell(for indexPath: IndexPath) -> UITableViewCell? {
    
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: currentUserCellID, for: indexPath) as! CurrentUserTableViewCell
      cell.title.text = NameConstants.personalStorage
      return cell
    }
    
    if indexPath.section == 1 {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: pigeonUsersCellID, for: indexPath) as! PigeonUsersTableViewCell
    
        if let name = filteredUsers[indexPath.row].name {
        
          cell.title.text = name
        }
      
        if let status = filteredUsers[indexPath.row].onlineStatus {
          if status == statusOnline {
            cell.subtitle.textColor = FalconPalette.falconPaletteBlue
            cell.subtitle.text = status
            
          } else {
            let date = NSDate(timeIntervalSince1970:  status.doubleValue )
            cell.subtitle.textColor = UIColor.lightGray
            cell.subtitle.text = "last seen " + timeAgoSinceDate(date: date, timeinterval: status.doubleValue, numericDates: false)
          }
        } else {
          
          cell.subtitle.text = ""
        }
      
        if let url = filteredUsers[indexPath.row].thumbnailPhotoURL {          
          cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.progressiveDownload, .continueInBackground], completed: { (image, error, cacheType, url) in
            if image != nil {
              if (cacheType != SDImageCacheType.memory && cacheType != SDImageCacheType.disk) {
                cell.icon.alpha = 0
                UIView.animate(withDuration: 0.25, animations: {
                  cell.icon.alpha = 1
                })
              } else {
                cell.icon.alpha = 1
              }
            }

          })
        }
      
      return cell
      
    } else if indexPath.section == 2 {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: contactsCellID, for: indexPath) as! ContactsTableViewCell
      
      cell.icon.image = UIImage(named: "UserpicIcon")
      cell.title.text = filteredContacts[indexPath.row].givenName + " " + filteredContacts[indexPath.row].familyName
      
      return cell
    }
    
    return nil
  }
  
  
    var chatLogController:ChatLogController? = nil
    var autoSizingCollectionViewFlowLayout:AutoSizingCollectionViewFlowLayout? = nil
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
      if indexPath.section == 0 {
        
        guard currentUser != nil else  {
          return
        }
        
        autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
        autoSizingCollectionViewFlowLayout?.minimumLineSpacing = 5
        chatLogController = ChatLogController(collectionViewLayout: autoSizingCollectionViewFlowLayout!)
        chatLogController?.delegate = self
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.user = currentUser
      }
      
      if indexPath.section == 1 {
        
        autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
        autoSizingCollectionViewFlowLayout?.minimumLineSpacing = 5
        chatLogController = ChatLogController(collectionViewLayout: autoSizingCollectionViewFlowLayout!)
        chatLogController?.delegate = self
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.user = filteredUsers[indexPath.row]
      }
    
      if indexPath.section == 2 {
        let destination = ContactsDetailController()
        destination.contactName = filteredContacts[indexPath.row].givenName + " " + filteredContacts[indexPath.row].familyName
        destination.contactPhoneNumbers.removeAll()
        destination .hidesBottomBarWhenPushed = true
        for phoneNumber in filteredContacts[indexPath.row].phoneNumbers {
          destination.contactPhoneNumbers.append(phoneNumber.value.stringValue)
        }
        self.navigationController?.pushViewController(destination, animated: true)
      }
    }
}


extension ContactsController: UITableViewDataSourcePrefetching {
  
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let urls = users.map { URL(string: $0.photoURL ?? "")  }
    SDWebImagePrefetcher.shared().prefetchURLs(urls as? [URL])
  }
}


extension ContactsController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
     
        searchBar.text = nil
        filteredUsers = users
        filteredContacts = contacts
        
        tableView.reloadData()
    }
    
  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    return true
  }
  
 func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
    filteredUsers = searchText.isEmpty ? users : users.filter({ (User) -> Bool in
      
      return User.name!.lowercased().contains(searchText.lowercased())
    })
  
  
    filteredContacts = searchText.isEmpty ? contacts : contacts.filter({ (CNContact) -> Bool in
      
        let contactFullName = CNContact.givenName.lowercased() + " " + CNContact.familyName.lowercased()
      
        return contactFullName.lowercased().contains(searchText.lowercased())
    })

    tableView.reloadData()
  }
}

extension ContactsController { /* hiding keyboard */
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    
    if #available(iOS 11.0, *) {
        searchContactsController?.resignFirstResponder()
        searchContactsController?.searchBar.resignFirstResponder()
    } else {
         searchBar?.resignFirstResponder()
    }
  }
    
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    
    if #available(iOS 11.0, *) {
        searchContactsController?.searchBar.endEditing(true)
    } else {
        self.searchBar?.endEditing(true)
    }
  }
}

extension ContactsController: MessagesLoaderDelegate {
  
  func messagesLoader( didFinishLoadingWith messages: [Message]) {
    
    self.chatLogController?.messages = messages
    
    var indexPaths = [IndexPath]()
    
    if messages.count - 1 >= 0 {
      for index in 0...messages.count - 1 {
        
        indexPaths.append(IndexPath(item: index, section: 1))
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


