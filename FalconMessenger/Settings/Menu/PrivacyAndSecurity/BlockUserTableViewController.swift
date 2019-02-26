//
//  BlockUserTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

protocol UpdateBlocklistDelegate: class {
  func updateBlocklist(user: User)
}

class BlockUserTableViewController: SelectChatTableViewController {

 weak var delegate: UpdateBlocklistDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()
		actions.removeAll()
		navigationItem.title = "Block User"
	}
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let falconUser = filteredUsersWithSection[indexPath.section][indexPath.row]
    delegate?.updateBlocklist(user: falconUser)
    navigationController?.popViewController(animated: true)
  }
  
  override func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    filteredUsers = users
    guard users.count > 0 else { return }
    setUpCollation()
    UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()}, completion: nil)
    searchBar.setShowsCancelButton(false, animated: true)
    searchBar.resignFirstResponder()
  }
}
