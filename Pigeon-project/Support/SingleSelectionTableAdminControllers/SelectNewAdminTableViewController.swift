//
//  SelectNewAdminTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/27/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import ARSLineProgress

class SelectNewAdminTableViewController: UITableViewController {
  
  let falconUsersCellID = "falconUsersCellID"
  
  weak var adminControlsController: GroupAdminControlsTableViewController?
  
  var filteredUsers = [User]() {
    didSet {
      configureSections()
    }
  }

  var users = [User]()
  var sortedFirstLetters = [String]()
  var sections = [[User]]()
  var selectedFalconUsers = [User]()
  var chatID = String()
  var currentUserName = String()
  var searchBar: UISearchBar?
  let informationMessageSender = InformationMessageSender()
  
  fileprivate var isInitialLoad = true
  fileprivate func configureSections() {
    if isInitialLoad {
      _ = filteredUsers.map { $0.isSelected = false }
      isInitialLoad = false
    }
    
    let firstLetters = filteredUsers.map { $0.titleFirstLetter }
    let uniqueFirstLetters = Array(Set(firstLetters))
    sortedFirstLetters = uniqueFirstLetters.sorted()
    sections = sortedFirstLetters.map { firstLetter in
      
      return self.filteredUsers
        .filter { $0.titleFirstLetter == firstLetter }
        .sorted { $0.name ?? "" < $1.name ?? "" }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupMainView()
    setupTableView()
    setupSearchController()
  }
  
  deinit {
    print("new admion deinit")
  }
  
  func setupMainView() {
    navigationItem.title = "New admin"
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
      navigationController?.navigationBar.prefersLargeTitles = true
    }
    extendedLayoutIncludesOpaqueBars = true
    definesPresentationContext = true
    edgesForExtendedLayout = [UIRectEdge.top, UIRectEdge.bottom]
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }

  fileprivate func setupTableView() {
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(NewAdminTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
    tableView.separatorStyle = .none
    setupRightBarButton(with: "Leave the group")
  }
  
  func setupRightBarButton(with title: String) {
    if #available(iOS 11.0, *) {
      let rightBarButton = UIButton(type: .system)
      rightBarButton.setTitle(title, for: .normal)
      rightBarButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
      rightBarButton.addTarget(self, action: #selector(rightBarButtonTapped), for: .touchUpInside)
      navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
    } else {
      navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(rightBarButtonTapped))
    }
    navigationItem.rightBarButtonItem?.isEnabled = false
  }
  
  @objc func rightBarButtonTapped() {
    ARSLineProgress.ars_showOnView(self.view)
    adminControlsController?.removeObservers()
    print("rbb")
  }
  
  func leaveTheGroupAndSetAdmin() {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let membersIDs = getMembersIDs()
    let reference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs").child(uid)
    reference.removeValue { (_, _) in
      let referenceText = "Administrator \(self.currentUserName) left the group"
      self.informationMessageSender.sendInformatoinMessage(chatID: self.chatID, membersIDs: membersIDs, text: referenceText)
      self.setNewAdmin(membersIDs: membersIDs)
    }
  }
  
  func setNewAdmin(membersIDs: [String]) {
    guard let newAdminID = selectedFalconUsers[0].id, let newAdminName = selectedFalconUsers[0].name else { return }
    let adminReference = Database.database().reference().child("groupChats").child(self.chatID).child(messageMetaDataFirebaseFolder)
    adminReference.updateChildValues(["admin": newAdminID]) { (_, _) in
      let newAdminText = "\(newAdminName) is new group administrator"
      self.informationMessageSender.sendInformatoinMessage(chatID: self.chatID, membersIDs: membersIDs, text: newAdminText)
      ARSLineProgress.hide()
      self.navigationController?.backToViewController(viewController: ChatLogController.self)
    }
  }
  
  func getMembersIDs() -> [String] {
    guard let uid = Auth.auth().currentUser?.uid else { return [] }
    var membersIDs = self.users.map({$0.id ?? ""})
    membersIDs.append(uid)
    return membersIDs
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
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sortedFirstLetters[section]
  }
  
  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    return sortedFirstLetters
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return sections.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sections[section].count
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 65
  }
  
  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    view.tintColor = ThemeManager.currentTheme().inputTextViewColor
    if let headerTitle = view as? UITableViewHeaderFooterView {
      headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 10)
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 20
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return selectCell(for: indexPath)!
  }
  
  func selectCell(for indexPath: IndexPath) -> UITableViewCell? {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID, for: indexPath) as? NewAdminTableViewCell ?? NewAdminTableViewCell()
    cell.selectNewAdminTableViewController = self
    let user = sections[indexPath.section][indexPath.row]
    cell.isSelected = user.isSelected
    
    if cell.isSelected {
      cell.accessoryType = .checkmark
    } else {
      cell.accessoryType = .none
    }
  
    if let name = sections[indexPath.section][indexPath.row].name {
      cell.title.text = name
    }
    
    if let statusString = sections[indexPath.section][indexPath.row].onlineStatus as? String {
      if statusString == statusOnline {
        cell.subtitle.textColor = FalconPalette.defaultBlue
        cell.subtitle.text = statusString
      } else {
        cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
        let date = Date(timeIntervalSince1970: TimeInterval(statusString)!)
        let subtitle = "Last seen " + timeAgoSinceDate(date)
        cell.subtitle.text = subtitle
      }
      
    } else if let statusTimeinterval = sections[indexPath.section][indexPath.row].onlineStatus as? TimeInterval {
      cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
      let date = Date(timeIntervalSince1970: statusTimeinterval/1000)
      let subtitle = "Last seen " + timeAgoSinceDate(date)
      cell.subtitle.text = subtitle
    }
    
    guard let url = sections[indexPath.section][indexPath.row].thumbnailPhotoURL else { return cell }
    cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.progressiveLoad, .continueInBackground], completed: { (image, error, cacheType, url) in
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
  
  func deselectAll(indexPath:IndexPath) {
    for user in selectedFalconUsers {
			if let filteredUsersIndex = filteredUsers.firstIndex(of: user) {
        filteredUsers[filteredUsersIndex].isSelected = false
      }
			if let usersIndex = users.firstIndex(of: user) {
        users[usersIndex].isSelected = false
      }
    }
    sections[indexPath.section][indexPath.row].isSelected = false
    selectedFalconUsers.removeAll()
  }
  
  func didSelectUser(at indexPath: IndexPath) {
    
    let user = sections[indexPath.section][indexPath.row]
    
		if let filteredUsersIndex = filteredUsers.firstIndex(of: user) {
      filteredUsers[filteredUsersIndex].isSelected = true
    }
    
		if let usersIndex = users.firstIndex(of: user) {
      users[usersIndex].isSelected = true
    }
    
    sections[indexPath.section][indexPath.row].isSelected = true
    selectedFalconUsers.append(sections[indexPath.section][indexPath.row])
    
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
    
    if selectedFalconUsers.count != 0 {
      navigationItem.rightBarButtonItem?.isEnabled = true
      return
    }
    self.navigationItem.rightBarButtonItem?.isEnabled = false
  }
}
