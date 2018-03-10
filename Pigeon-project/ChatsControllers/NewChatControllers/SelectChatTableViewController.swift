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
  
  var searchContactsController: UISearchController?
  
  private let reloadAnimation = UITableViewRowAnimation.none
  
  var phoneNumberKit = PhoneNumberKit()

  let viewControllerPlaceholder = ViewControllerPlaceholder()
  
  let falconUsersFetcher = FalconUsersFetcher()
  
  
    override func viewDidLoad() {
      super.viewDidLoad()
     
      setupMainView()
      setupTableView()
      
      falconUsersFetcher.delegate = self
      falconUsersFetcher.fetchFalconUsers(asynchronously: false)
      
      setupSearchController()
      setupViewControllerPlaceholder()
      checkContactsAuthorizationStatus()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if self.navigationController?.visibleViewController is ChatLogController ||
      self.navigationController?.visibleViewController is SelectParticipantsTableViewController {
      return
    }

    if falconUsersFetcher.userReference != nil {
      for handle in falconUsersFetcher.userHandle {
        falconUsersFetcher.userReference.removeObserver(withHandle: handle)
      }
    }
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
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
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
  
  fileprivate func setupViewControllerPlaceholder() {
    viewControllerPlaceholder.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    DispatchQueue.main.async {
      self.viewControllerPlaceholder.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300)
    }
  }
  
  fileprivate func checkContactsAuthorizationStatus() {
    let contactsAuthorityCheck = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
    
    switch contactsAuthorityCheck {
    case .denied, .notDetermined, .restricted:
      viewControllerPlaceholder.addViewControllerPlaceholder(for: self.view, title: viewControllerPlaceholder.contactsAuthorizationDeniedtitle, subtitle: viewControllerPlaceholder.contactsAuthorizationDeniedSubtitle, priority: .high, position: .center)
    case .authorized:
      viewControllerPlaceholder.removeViewControllerPlaceholder(from: self.view, priority: .high)
    }
  }
  
  fileprivate func reloadTableView(updatedUsers: [User]) {
    
    self.users = updatedUsers
    self.users = falconUsersFetcher.rearrangeUsers(users: self.users)

    let searchBar = correctSearchBarForCurrentIOSVersion()
    let isSearchInProgress = searchBar.text != ""
    let isSearchControllerEmpty = self.filteredUsers.count == 0
    
    if isSearchInProgress && !isSearchControllerEmpty {
      return
    } else {
      self.filteredUsers = self.users
      guard self.filteredUsers.count != 0 else {
        handleFalconContactsAbsence()
        return
      }
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  fileprivate func handleFalconContactsAbsence() {
    viewControllerPlaceholder.addViewControllerPlaceholder(for: self.view, title: viewControllerPlaceholder.emptyFalconUsersTitle, subtitle: viewControllerPlaceholder.emptyFalconUsersSubtitle, priority: .low, position: .center)
  }

  fileprivate func correctSearchBarForCurrentIOSVersion() -> UISearchBar {
    var searchBar: UISearchBar!
    if #available(iOS 11.0, *) {
      searchBar = self.searchContactsController?.searchBar
    } else {
      searchBar = self.searchBar
    }
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
      
       let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID, for: indexPath) as! FalconUsersTableViewCell
      
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

extension SelectChatTableViewController: FalconUsersUpdatesDelegate {
  func falconUsers(shouldBeUpdatedTo users: [User]) {
    self.reloadTableView(updatedUsers: users)
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
