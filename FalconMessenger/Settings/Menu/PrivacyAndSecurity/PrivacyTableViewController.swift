//
//  PrivacyTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class PrivacyTableViewController: MenuControlsTableViewController {
  
	var privacyElements = [SwitchObject]()

  override func viewDidLoad() {
		super.viewDidLoad()
    createDataSource()
		navigationItem.title = "Privacy"
  }
  
  fileprivate func createDataSource() {
    let biometricsState = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
    let contactsSyncState = userDefaults.currentBoolObjectState(for: userDefaults.contactsContiniousSync)
    let biometricsObject = SwitchObject(Biometrics().title, subtitle: nil, state: biometricsState, defaultsKey: userDefaults.biometricalAuth)
    let contactsSyncObject = SwitchObject("Syncronize Contacts", subtitle: nil, state: contactsSyncState, defaultsKey: userDefaults.contactsContiniousSync)
    privacyElements.append(biometricsObject)
    privacyElements.append(contactsSyncObject)
  }

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 1 { return privacyElements.count }
    return 1
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: controlButtonCellID,
																							 for: indexPath) as? GroupAdminPanelTableViewCell ?? GroupAdminPanelTableViewCell()
			cell.button.setTitle("Blacklist", for: .normal)
			cell.button.addTarget(self, action: #selector(controlButtonClicked(_:)), for: .touchUpInside)
			cell.selectionStyle = .none

			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: switchCellID,
																							 for: indexPath) as? SwitchTableViewCell ?? SwitchTableViewCell()
			cell.currentViewController = self
			cell.setupCell(object: privacyElements[indexPath.row], index: indexPath.row)

			return cell
		}
  }

	@objc fileprivate func controlButtonClicked(_ sender: UIButton) {
		guard let superview = sender.superview else { return }
		let point = tableView.convert(sender.center, from: superview)
		guard let indexPath = tableView.indexPathForRow(at: point), indexPath.section == 0 else { return }
		let destination = BlockedUsersTableViewController()
		navigationController?.pushViewController(destination, animated: true)
	}
}
