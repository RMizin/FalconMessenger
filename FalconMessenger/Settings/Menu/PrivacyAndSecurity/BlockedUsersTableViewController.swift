//
//  BlockedUsersTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import ARSLineProgress

private let falconUsersCellID = "falconUsersCellID"

class BlockedUsersTableViewController: MenuControlsTableViewController {

  fileprivate var users = [User]()
  fileprivate let adminControls = ["Add Users"]
  fileprivate let userBlockingManager = UserBlockingManager()
  
  override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
		navigationItem.title = "Blacklist"
		navigationItem.rightBarButtonItem = editButtonItem
    fetchBlockedUsers()
  }
  
  fileprivate func fetchBlockedUsers() {
    ARSLineProgress.ars_showOnView(view)
    let bannedUsersLoadingGroup = DispatchGroup()
    let bannedIDs = blacklistManager.blockedUsersByCurrentUser
    
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

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      let cell = tableView.dequeueReusableCell(withIdentifier: controlButtonCellID,
                                               for: indexPath) as? GroupAdminPanelTableViewCell ?? GroupAdminPanelTableViewCell()
      cell.selectionStyle = .none
			cell.button.setTitle(adminControls[indexPath.row], for: .normal)
			cell.button.addTarget(self, action: #selector(controlButtonClicked(_:)), for: .touchUpInside)
      
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID,
                                               for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
      let parameter = users[indexPath.row]
      cell.configureCell(for: parameter)
      return cell
    }
  }

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		guard indexPath.section == 1 else { return false }
		return true
	}

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		guard indexPath.section == 1 else { return .none }
		return .delete
	}

	override  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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

	@objc fileprivate func controlButtonClicked(_ sender: UIButton) {
		guard let superview = sender.superview else { return }
		let point = tableView.convert(sender.center, from: superview)
		guard let indexPath = tableView.indexPathForRow(at: point), indexPath.section == 0 else { return }
		showAvailibleUsersToBlock()
	}

  @objc fileprivate func showAvailibleUsersToBlock() {
    let destination = BlockUserTableViewController()
    destination.hidesBottomBarWhenPushed = true
    let isContactsAccessGranted = destination.checkContactsAuthorizationStatus()
    if isContactsAccessGranted {
      let users = blacklistManager.removeBannedUsers(users: RealmKeychain.realmUsersArray())
      destination.users = users
      destination.filteredUsers = users
      destination.setUpCollation()
      destination.checkNumberOfContacts()
      destination.delegate = self
    }
    navigationController?.pushViewController(destination, animated: true)
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
