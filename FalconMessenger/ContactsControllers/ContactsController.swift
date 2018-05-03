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

public var shouldReloadContactsControllerAfterChangingTheme = false

var localPhones = [String]()

var globalUsers = [User]()

class ContactsController: UITableViewController {
  
  let phoneNumberKit = PhoneNumberKit()
  
  var contacts = [CNContact]()
  
  var filteredContacts = [CNContact]()
  
  var users = [User]()
  
  var filteredUsers = [User]()
  
  let contactsCellID = "contactsCellID"
  
  let falconUsersCellID = "falconUsersCellID"
  
  let currentUserCellID = "currentUserCellID"
  
  private let reloadAnimation = UITableViewRowAnimation.none
  
  var searchBar: UISearchBar?
    
  var searchContactsController: UISearchController?
  
  let viewControllerPlaceholder = ViewControllerPlaceholder()
  
  let falconUsersFetcher = FalconUsersFetcher()

    override func viewDidLoad() {
        super.viewDidLoad()
      
      extendedLayoutIncludesOpaqueBars = true
      edgesForExtendedLayout = UIRectEdge.top
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      falconUsersFetcher.delegate = self
      setupTableView()
      setupSearchController()
      fetchContacts()
      checkContactsAuthorizationStatus()
    }
  
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      checkContactsAuthorizationStatus()
      setUpColorsAccordingToTheme()
      
      if shouldReFetchFalconUsers {
        shouldReFetchFalconUsers = false
        DispatchQueue.main.async {
          self.falconUsersFetcher.fetchFalconUsers()
        }
      }
    }
  
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
      super.viewWillTransition(to: size, with: coordinator)
      setupViewControllerPlaceholder()
    }
  
    override var preferredStatusBarStyle: UIStatusBarStyle {
      return ThemeManager.currentTheme().statusBarStyle
    }
  
  
    fileprivate func setUpColorsAccordingToTheme() {
      if shouldReloadContactsControllerAfterChangingTheme {
        shouldReloadContactsControllerAfterChangingTheme = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.reloadData()
      }
    }
  
    fileprivate func setupTableView() {
      tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
      tableView.sectionIndexBackgroundColor = view.backgroundColor
      tableView.backgroundColor = view.backgroundColor
      tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
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
        searchBar?.placeholder = "Search"
        searchBar?.searchBarStyle = .minimal
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        tableView.tableHeaderView = searchBar
      }
    }
  
    fileprivate func setupViewControllerPlaceholder() {
      viewControllerPlaceholder.backgroundColor = .clear
      DispatchQueue.main.async {
        if #available(iOS 11.0, *) {
         self.viewControllerPlaceholder.frame = CGRect(x: 0, y: 135, width: self.view.frame.width, height: self.view.frame.height-135)
        } else {
          self.viewControllerPlaceholder.frame = CGRect(x: 0, y: 175, width: self.view.frame.width, height: self.view.frame.height-175)
        }
      }
    }
  
    fileprivate func checkContactsAuthorizationStatus() {
      setupViewControllerPlaceholder()
      let contactsAuthorityCheck = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
      
      switch contactsAuthorityCheck {
      case .denied, .notDetermined, .restricted:
        viewControllerPlaceholder.addViewControllerPlaceholder(for: self.view, title: viewControllerPlaceholder.contactsAuthorizationDeniedtitle, subtitle: viewControllerPlaceholder.contactsAuthorizationDeniedSubtitle, priority: .high, position: .top)
        
      case .authorized:
        viewControllerPlaceholder.removeViewControllerPlaceholder(from: self.view, priority: .high)
      }
    }

    fileprivate func fetchContacts () {
      
      let status = CNContactStore.authorizationStatus(for: .contacts)
      let store = CNContactStore()
      if status == .denied || status == .restricted { return }
    
      store.requestAccess(for: .contacts) { granted, error in
        guard granted else { return }

        let request = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey as NSString, CNContactPhoneNumbersKey as NSString, CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactImageDataAvailableKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor])
        
        do {
          try store.enumerateContacts(with: request) { contact, stop in self.contacts.append(contact) }
        } catch {}
        
        localPhones.removeAll()
        self.filteredContacts = self.contacts

        let phoneNumbers = self.contacts.flatMap({$0.phoneNumbers.map({$0.value.stringValue.digits}) })
        localPhones.append(contentsOf: phoneNumbers)
        
        self.falconUsersFetcher.fetchFalconUsers()
        self.sendUserContactsToDatabase()
      }
    }
  
   fileprivate func sendUserContactsToDatabase() {
      guard let uid = Auth.auth().currentUser?.uid else { return }

      let userReference = Database.database().reference().child("users").child(uid)
      var preparedNumbers = [String]()

      for number in localPhones {
        do {
          let countryCode = try self.phoneNumberKit.parse(number).countryCode
          let nationalNumber = try self.phoneNumberKit.parse(number).nationalNumber
          preparedNumbers.append( ("+" + String(countryCode) + String(nationalNumber)) )
        } catch {}
      }
      userReference.updateChildValues(["contacts": preparedNumbers])
    }
  
    fileprivate func reloadTableView(updatedUsers: [User]) {
      
      users = falconUsersFetcher.rearrangeUsers(users: updatedUsers)
      let searchBar = correctSearchBarForCurrentIOSVersion()
      let isSearchInProgress = searchBar.text != ""
      let isSearchControllerEmpty = filteredUsers.count == 0
      
      if isSearchInProgress && !isSearchControllerEmpty { return } else {
        filteredUsers = users
        guard filteredUsers.count != 0 else { return }
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      }
    }
  
    fileprivate func correctSearchBarForCurrentIOSVersion() -> UISearchBar {
      var searchBar: UISearchBar!
      if #available(iOS 11.0, *) {
        searchBar = searchContactsController?.searchBar
      } else {
        searchBar = self.searchBar
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
      return selectCell(for: indexPath)!
    }
  
    func selectCell(for indexPath: IndexPath) -> UITableViewCell? {
      
      if indexPath.section == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: currentUserCellID, for: indexPath) as! CurrentUserTableViewCell
        cell.title.text = NameConstants.personalStorage
        return cell
      }
      
      if indexPath.section == 1 {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID, for: indexPath) as! FalconUsersTableViewCell
      
        if let name = filteredUsers[indexPath.row].name {
          cell.title.text = name
        }
      
        if let statusString = filteredUsers[indexPath.row].onlineStatus as? String {
          if statusString == statusOnline {
            cell.subtitle.textColor = FalconPalette.defaultBlue
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
        cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.scaleDownLargeImages, .continueInBackground, .avoidAutoSetImage], completed: { (image, error, cacheType, url) in
          
          guard image != nil else { return }
          guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
             cell.icon.image = image
            return
          }
          
          UIView.transition(with:  cell.icon,
                            duration: 0.20,
                            options: .transitionCrossDissolve,
                            animations: { cell.icon.image = image },
                            completion: nil)
        })
        
        return cell
        
      } else if indexPath.section == 2 {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID, for: indexPath) as! FalconUsersTableViewCell
        if filteredContacts[indexPath.row].imageDataAvailable {
          let image = UIImage(data: filteredContacts[indexPath.row].thumbnailImageData!)
          cell.icon.image = image
        } else {
          cell.icon.image = UIImage(named: "UserpicIcon")
        }
      
        cell.title.text = filteredContacts[indexPath.row].givenName + " " + filteredContacts[indexPath.row].familyName
        cell.subtitle.text = filteredContacts[indexPath.row].phoneNumbers[0].value.stringValue
        
        return cell
      }
      return nil
    }
  
  var chatLogController:ChatLogController? = nil
  var messagesFetcher:MessagesFetcher? = nil
  var destinationLayout:AutoSizingCollectionViewFlowLayout? = nil
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }
      
      if indexPath.section == 0 {
     
        let conversationDictionary: [String: AnyObject] = ["chatID": currentUserID as AnyObject,
                                                          "isGroupChat": false  as AnyObject,
                                                          "chatParticipantsIDs": [currentUserID] as AnyObject]
        
        let conversation = Conversation(dictionary: conversationDictionary)

        destinationLayout = AutoSizingCollectionViewFlowLayout()
        destinationLayout?.minimumLineSpacing = 3
        chatLogController = ChatLogController(collectionViewLayout: destinationLayout!)
        
        messagesFetcher = MessagesFetcher()
        messagesFetcher?.delegate = self
        messagesFetcher?.loadMessagesData(for: conversation)
        
      }
      
      if indexPath.section == 1 {
     
        let conversationDictionary: [String: AnyObject] = ["chatID": filteredUsers[indexPath.row].id as AnyObject, "chatName": filteredUsers[indexPath.row].name as AnyObject,
                                                           "isGroupChat": false  as AnyObject,
                                                           "chatOriginalPhotoURL": filteredUsers[indexPath.row].photoURL as AnyObject,
                                                           "chatThumbnailPhotoURL": filteredUsers[indexPath.row].thumbnailPhotoURL as AnyObject,
                                                           "chatParticipantsIDs": [filteredUsers[indexPath.row].id, currentUserID] as AnyObject]
        
        let conversation = Conversation(dictionary: conversationDictionary)
        
        destinationLayout = AutoSizingCollectionViewFlowLayout()
        destinationLayout?.minimumLineSpacing = AutoSizingCollectionViewFlowLayout.lineSpacing
        chatLogController = ChatLogController(collectionViewLayout: destinationLayout!)
        
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
        destination .hidesBottomBarWhenPushed = true
        destination.contactPhoneNumbers = filteredContacts[indexPath.row].phoneNumbers
        navigationController?.pushViewController(destination, animated: true)
      }
    }
}

extension ContactsController: FalconUsersUpdatesDelegate {
  func falconUsers(shouldBeUpdatedTo users: [User]) {
    globalUsers = users
    self.reloadTableView(updatedUsers: users)
  }
}

extension ContactsController: UITableViewDataSourcePrefetching {
  
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let urls = users.map { URL(string: $0.photoURL ?? "")  }
    SDWebImagePrefetcher.shared().prefetchURLs(urls as? [URL])
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
    chatLogController?.observeTypingIndicator()
    chatLogController?.configureTitleViewWithOnlineStatus()
    chatLogController?.messagesFetcher.collectionDelegate = chatLogController
    guard let destination = chatLogController else { return }
    
    if #available(iOS 11.0, *) {
    } else {
      self.chatLogController?.startCollectionViewAtBottom()
    }
    
    navigationController?.pushViewController(destination, animated: true)
    chatLogController = nil
    destinationLayout = nil
  }
}
