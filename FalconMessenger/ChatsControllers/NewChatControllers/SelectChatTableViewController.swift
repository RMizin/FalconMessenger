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
  
  let falconUsersCellID = "falconUsersCellID"
  
  let newGroupCellID = "newGroupCellID"
  
  let newGroupAction = "New Group"

  var actions = ["New Group"]
  
  var users = [User]()
  
  var filteredUsers = [User]()
  
  var searchBar: UISearchBar?
  
  private let reloadAnimation = UITableViewRowAnimation.none
  
  var phoneNumberKit = PhoneNumberKit()

  let viewControllerPlaceholder = ViewControllerPlaceholder()

  
    override func viewDidLoad() {
      super.viewDidLoad()
     
      setupMainView()
      setupTableView()
      setupSearchController()
      setupViewControllerPlaceholder()
    //checkContactsAuthorizationStatus() 
  }
  
  deinit {
    print("new chat deinit")
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    setupViewControllerPlaceholder()
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }
  
  fileprivate func setupMainView() {
    navigationItem.title = "New Message"
    
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
      navigationController?.navigationBar.prefersLargeTitles = true
    }
    extendedLayoutIncludesOpaqueBars = true
    definesPresentationContext = true
    edgesForExtendedLayout = [UIRectEdge.top, UIRectEdge.bottom]
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  @objc fileprivate func dismissNavigationController() {
    dismiss(animated: true, completion: nil)
  }
  
  fileprivate func setupTableView() {
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
    tableView.separatorStyle = .none
    tableView.prefetchDataSource = self
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
  
  fileprivate func setupViewControllerPlaceholder() {
    viewControllerPlaceholder.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    DispatchQueue.main.async {
      self.viewControllerPlaceholder.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300)
    }
  }
  
  func checkContactsAuthorizationStatus() -> Bool {
    let contactsAuthorityCheck = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
    
    switch contactsAuthorityCheck {
    case .denied, .notDetermined, .restricted:
      viewControllerPlaceholder.addViewControllerPlaceholder(for: self.view, title: viewControllerPlaceholder.contactsAuthorizationDeniedtitle, subtitle: viewControllerPlaceholder.contactsAuthorizationDeniedSubtitle, priority: .high, position: .center)
      return false
    case .authorized:
      viewControllerPlaceholder.removeViewControllerPlaceholder(from: self.view, priority: .high)
      return true
    }
  }
  
  fileprivate func handleFalconContactsAbsence() {
    viewControllerPlaceholder.addViewControllerPlaceholder(for: self.view, title: viewControllerPlaceholder.emptyFalconUsersTitle, subtitle: viewControllerPlaceholder.emptyFalconUsersSubtitle, priority: .low, position: .center)
  }

  fileprivate func correctSearchBarForCurrentIOSVersion() -> UISearchBar {
    var searchBar: UISearchBar!
    searchBar = self.searchBar
   
    return searchBar
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
    return ""
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
      cell.textLabel?.textColor = FalconPalette.defaultBlue
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
      cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.scaleDownLargeImages, .continueInBackground], completed: { (image, error, cacheType, url) in
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
  var messagesFetcher:MessagesFetcher? = nil
  var destinationLayout:AutoSizingCollectionViewFlowLayout? = nil
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.section == 0 {
      let destination = SelectGroupMembersController()
      destination.users = self.users
      destination.filteredUsers = self.filteredUsers
      self.navigationController?.pushViewController(destination, animated: true)
    }
    
    if indexPath.section == 1 {
      
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }
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
  }
}

extension SelectChatTableViewController: UITableViewDataSourcePrefetching {
  
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let urls = users.map { URL(string: $0.photoURL ?? "")  }
    SDWebImagePrefetcher.shared().prefetchURLs(urls as? [URL])
  }
}

extension SelectChatTableViewController: MessagesDelegate {
  
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
    //chatLogController?.observeMembersChanges()
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
