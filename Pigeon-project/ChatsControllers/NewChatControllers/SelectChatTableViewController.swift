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

class SelectChatTableViewController: UITableViewController {
  
  let pigeonUsersCellID = "pigeonUsersCellID"
  
  let newGroupCellID = "newGroupCellID"
  
 // let newGroupAction = "New Group"

//  var actions = ["New Group"]
   var actions = [String]()
  
  var users = [User]()
  
  var filteredUsers = [User]()
  
  var searchBar: UISearchBar?
  
  var searchContactsController: UISearchController?
  
  private let reloadAnimation = UITableViewRowAnimation.none
  
  var phoneNumberKit = PhoneNumberKit()
  
  let contactsAuthorizationDeniedContainer:ContactsAuthorizationDeniedContainer! = ContactsAuthorizationDeniedContainer()
  
  
    override func viewDidLoad() {
      super.viewDidLoad()

      setupMainView()
      setupTableView()
      fetchFalconUsers()
      setupSearchController()
      setUpColorsAccordingToTheme()
      checkContactsAuthorizationStatus()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    contactsAuthorizationDeniedContainer.frame = CGRect(x: 0, y: 135, width: self.view.bounds.width, height: 100)
    contactsAuthorizationDeniedContainer.layoutIfNeeded()
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }
  
  fileprivate func setupMainView() {
    navigationItem.title = "New Message"
    
    let newChatBarButton = UIBarButtonItem(barButtonSystemItem: .cancel , target: self, action: #selector(dismissNavigationController))
    navigationItem.leftBarButtonItem =  newChatBarButton

    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
      navigationController?.navigationBar.prefersLargeTitles = true
    }
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  @objc fileprivate func dismissNavigationController() {
    dismiss(animated: true, completion: nil)
  }
  
  fileprivate func setupTableView() {
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(PigeonUsersTableViewCell.self, forCellReuseIdentifier: pigeonUsersCellID)
    tableView.separatorStyle = .none
    tableView.prefetchDataSource = self
    definesPresentationContext = true
  }
  
  fileprivate func setUpColorsAccordingToTheme() {
    if shouldReloadContactsControllerAfterChangingTheme {
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.sectionIndexBackgroundColor = view.backgroundColor
      tableView.backgroundColor = view.backgroundColor
      tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
      tableView.reloadData()
      print("reloading")
      shouldReloadContactsControllerAfterChangingTheme = false
    }
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
  
  fileprivate func rearrangeUsers() { /* Moves Online users to the top  */
    for index in 0...self.users.count - 1 {
      if self.users[index].onlineStatus as? String == statusOnline {
        self.users = rearrange(array: self.users, fromIndex: index, toIndex: 0)
      }
    }
  }
  
  fileprivate func rearrangeFilteredUsers() { /* Moves Online users to the top  */
    for index in 0...self.filteredUsers.count - 1 {
      if self.filteredUsers[index].onlineStatus as? String == statusOnline {
        self.filteredUsers = rearrange(array: self.filteredUsers, fromIndex: index, toIndex: 0)
      }
    }
  }
  
  fileprivate func sortUsers() { /* Sort users by last online date  */
    self.users.sort(by: { (user1, user2) -> Bool in
      if let firstUserOnlineStatus = user1.onlineStatus as? TimeInterval , let secondUserOnlineStatus = user2.onlineStatus as? TimeInterval {
        return (firstUserOnlineStatus, user1.phoneNumber ?? "") > ( secondUserOnlineStatus, user2.phoneNumber ?? "")
      } else {
        return ( user1.phoneNumber ?? "") > (user2.phoneNumber ?? "") // sort
      }
    })
  }
  
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if userReference != nil {
      for handle in userHandle {
        userReference.removeObserver(withHandle: handle)
      }
    }
  }
  
  deinit {
    print("new chat deinit")
   
  }

  var userReference: DatabaseReference!
  var userQuery: DatabaseQuery!
  var userHandle = [DatabaseHandle]()
  
  @objc fileprivate func fetchFalconUsers() {
    
    var preparedNumber = String()
    
    for number in localPhones {
      do {
        let countryCode = try self.phoneNumberKit.parse(number).countryCode
        let nationalNumber = try self.phoneNumberKit.parse(number).nationalNumber
        preparedNumber = "+" + String(describing: countryCode) + String(describing: nationalNumber)
      } catch {
        // print("Generic parser error")
      }
  
       userReference = Database.database().reference().child("users")
       userQuery = userReference.queryOrdered(byChild: "phoneNumber")
       let databaseHandle = DatabaseHandle()
       userHandle.insert(databaseHandle, at: 0 )
       userHandle[0] = userQuery.queryEqual(toValue: preparedNumber).observe(.value, with: { (snapshot) in
        
        if snapshot.exists() {
          
          for child in snapshot.children.allObjects as! [DataSnapshot]  {
            guard var dictionary = child.value as? [String: AnyObject] else { return }
            dictionary.updateValue(child.key as AnyObject, forKey: "id")
            
            let newUser = User(dictionary: dictionary)
            if let index = self.users.index(where: { ($0.id) == newUser.id }) {
               self.users[index] = newUser
            } else {
              self.users.append(newUser)
            }

            self.sortUsers()
            self.rearrangeUsers()

            if let index = self.users.index(where: { ($0.id) == Auth.auth().currentUser?.uid }) {
              self.users.remove(at: index)
            }
            self.filteredUsers = self.users
          }
          self.reloadTableView(snap: snapshot)
        }
      }, withCancel: nil)
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
      guard var dictionary = snap.value as? [String: AnyObject] else { return }

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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
      return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section == 0 {
        return actions.count
      } else {
        return filteredUsers.count
      }
    }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 65
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    
    if section == 0 {
      return ""
    } else {
      if filteredUsers.count == 0 {
        return ""
      } else {
        return "Falcon contacts"
      }
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
      let cell = tableView.dequeueReusableCell(withIdentifier: newGroupCellID) ?? UITableViewCell(style: .default, reuseIdentifier: newGroupCellID)
      cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      cell.imageView?.image = UIImage(named: "groupChat")
      cell.imageView?.contentMode = .scaleAspectFit
      cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
      cell.textLabel?.text = actions[indexPath.row]
      cell.textLabel?.textColor = FalconPalette.falconPaletteBlue
      return cell
    }
    
    if indexPath.section == 1 {
      
       let cell = tableView.dequeueReusableCell(withIdentifier: pigeonUsersCellID, for: indexPath) as! PigeonUsersTableViewCell
      
      if let name = filteredUsers[indexPath.row].name {
        cell.title.text = name
      }
      
      if let statusString = filteredUsers[indexPath.row].onlineStatus as? String {
        if statusString == statusOnline {
          cell.subtitle.textColor = FalconPalette.falconPaletteBlue
          cell.subtitle.text = statusString
        } else {
          cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
          let date = Date(timeIntervalSince1970: TimeInterval(statusString)!)
          let subtitle = "Last seen " + timeAgoSinceDate(date)
          cell.subtitle.text = subtitle
        }
        
      } else if let statusTimeinterval = filteredUsers[indexPath.row].onlineStatus as? TimeInterval {
        cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
        let date = Date(timeIntervalSince1970: statusTimeinterval/1000)
        let subtitle = "Last seen " + timeAgoSinceDate(date)
        cell.subtitle.text = subtitle
      }
      
      guard let url = filteredUsers[indexPath.row].thumbnailPhotoURL else { return cell }
      cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.progressiveDownload, .continueInBackground], completed: { (image, error, cacheType, url) in
        guard image != nil else { return }
        guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
          cell.icon.alpha = 1
          return
        }
        cell.icon.alpha = 0
        UIView.animate(withDuration: 0.25, animations: { cell.icon.alpha = 1 })
      })
      return cell
    }
    return nil
  }

  
  var chatLogController:ChatLogController? = nil
  var autoSizingCollectionViewFlowLayout:AutoSizingCollectionViewFlowLayout? = nil
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    if indexPath.section == 0 {}
    
    if indexPath.section == 1 {
      
      autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
      autoSizingCollectionViewFlowLayout?.minimumLineSpacing = 4
      chatLogController = ChatLogController(collectionViewLayout: autoSizingCollectionViewFlowLayout!)
      chatLogController?.delegate = self
      chatLogController?.allMessagesRemovedDelegate = appDelegate.chatsController
      chatLogController?.hidesBottomBarWhenPushed = true
      chatLogController?.user = filteredUsers[indexPath.row]
    }
  }
}

extension SelectChatTableViewController: UITableViewDataSourcePrefetching {
  
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let urls = users.map { URL(string: $0.photoURL ?? "")  }
    SDWebImagePrefetcher.shared().prefetchURLs(urls as? [URL])
  }
}

extension SelectChatTableViewController: MessagesLoaderDelegate {
  
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
