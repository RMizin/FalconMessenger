//
//  BlockedUsersTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

private let falconUsersCellID = "falconUsersCellID"
private let adminControlsCellID = "adminControlsCellID"

class BlockedUsersTableViewController: UITableViewController {

  var users = [User]()
  let adminControls = ["Add Users"]
  let userBlockingManager = UserBlockingManager()
  
  override func viewDidLoad() {
      super.viewDidLoad()
    configureViewController()
    fetchBlockedUsers()
  }
  
  deinit {
    print("blocked users deinig")
  }
  
  fileprivate func fetchBlockedUsers() {
    ARSLineProgress.ars_showOnView(view)
    let bannedUsersLoadingGroup = DispatchGroup()
    let bannedIDs = globalDataStorage.blockedUsersByCurrentUser
    
    bannedIDs.forEach { (_) in
      bannedUsersLoadingGroup.enter()
    }
    
    bannedUsersLoadingGroup.notify(queue: .main) {
      self.tableView.reloadData()
      ARSLineProgress.hide()
    }
    
    bannedIDs.forEach { (bannedID) in
      let reference = Database.database().reference().child("users").child(bannedID)
      reference.observeSingleEvent(of: .value, with: { (snapshot) in
        guard var dictionary = snapshot.value as? [String: AnyObject] else {
          bannedUsersLoadingGroup.leave()
          return
        }
        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
        let user = User(dictionary: dictionary)
        self.users.append(user)
        bannedUsersLoadingGroup.leave()
      })
    }
  }
  
  fileprivate func configureViewController() {
    extendedLayoutIncludesOpaqueBars = true
    definesPresentationContext = true
    edgesForExtendedLayout = UIRectEdge.top
    navigationItem.title = "Blacklist"
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
    tableView.register(GroupAdminControlsTableViewCell.self, forCellReuseIdentifier: adminControlsCellID)
    tableView.separatorStyle = .none
    navigationItem.rightBarButtonItem = editButtonItem
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return adminControls.count
    } else {
      return users.count
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 60
    }
    return 65
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 { return " " }
    guard section == 1, users.count != 0 else { return "" }
    return " "
  }
  
  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if section == 0 { return " " }
    return ""
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    if section == 0 { return 20 }
    return 0
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 { return 20 }
    guard section == 1, users.count != 0 else { return 0 }
    return 8
  }
 
  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
    guard section == 1 else { return }
    view.tintColor = ThemeManager.currentTheme().inputTextViewColor
  }
  
  override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
    view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: adminControlsCellID,
                                               for: indexPath) as? GroupAdminControlsTableViewCell ?? GroupAdminControlsTableViewCell()
      cell.selectionStyle = .none
      cell.title.text = adminControls[indexPath.row]
      cell.title.textColor = FalconPalette.defaultBlue
      
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID,
                                               for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
      let parameter = users[indexPath.row]
      cell.configureCell(for: parameter)
      return cell
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      newChat()
		} else {
			tableView.deselectRow(at: indexPath, animated: true)
		}
  }
  
  @objc fileprivate func newChat() {
    let destination = BlockUserTableViewController()
    destination.hidesBottomBarWhenPushed = true
    let isContactsAccessGranted = destination.checkContactsAuthorizationStatus()
    if isContactsAccessGranted {
      let users = removeBannedUsers(users: globalDataStorage.falconUsers)
      destination.users = users
      destination.filteredUsers = users//globalDataStorage.falconUsers
      destination.setUpCollation()
      destination.checkNumberOfContacts()
      destination.delegate = self
    //  destination.actions.removeAll()
    }
    navigationController?.pushViewController(destination, animated: true)
  }
  
  fileprivate func removeBannedUsers(users: [User]) -> [User] {
    var users = users
    globalDataStorage.blockedUsersByCurrentUser.forEach { (blockedUID) in
      guard let index = users.index(where: { (user) -> Bool in
        return user.id == blockedUID
      }) else { return }
      
      users.remove(at: index)
    }
    return users
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    guard indexPath.section == 1 else { return false }
    return true
  }
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    guard indexPath.section == 1 else { return .none }
    return .delete
  }
  
  override  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      guard let userID = users[indexPath.row].id else { return }
      
      userBlockingManager.unblockUser(userID: userID)
      
      tableView.beginUpdates()
      users.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .left)
      tableView.endUpdates()
      
      if users.count == 0 {
        tableView.setEditing(false, animated: true)
      }
    }
  }
}

extension BlockedUsersTableViewController: UpdateBlocklistDelegate {
  func updateBlocklist(user: User) {
    guard let userID = user.id else { return }
    userBlockingManager.blockUser(userID: userID)
    users.append(user)
    tableView.beginUpdates()
    tableView.insertRows(at: [IndexPath(row: users.count-1, section: 1)], with: .none)
    tableView.endUpdates()
  }
}
