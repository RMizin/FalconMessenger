//
//  PrivacyTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


private let privacyTableViewCellID = "PrivacyTableViewCellID"

class PrivacyTableViewController: SwitchTableViewController {
  
  var privacyElements = [SwitchObject]()


  override func viewDidLoad() {
      super.viewDidLoad()
    createDataSource()
    setTitle("Privacy")
    registerCell(for: privacyTableViewCellID)
  }
  
  fileprivate func createDataSource() {
    let biometricsState = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
    let contactsSyncState = userDefaults.currentBoolObjectState(for: userDefaults.contactsContiniousSync)
    
    let biometricsObject = SwitchObject(Biometrics().title, subtitle: nil, state: biometricsState, defaultsKey: userDefaults.biometricalAuth)
    let contactsSyncObject = SwitchObject("Syncronize Contacts", subtitle: nil, state: contactsSyncState, defaultsKey: userDefaults.contactsContiniousSync)
    privacyElements.append(biometricsObject)
    privacyElements.append(contactsSyncObject)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 1 {
      return privacyElements.count
    }
    return 1
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 1 {
      let cell = tableView.dequeueReusableCell(withIdentifier: privacyTableViewCellID, for: indexPath) as! SwitchTableViewCell
      cell.currentViewController = self
      cell.setupCell(object: privacyElements[indexPath.row], index: indexPath.row)
      
      return cell
    }
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "identifier") ?? UITableViewCell(style: .default, reuseIdentifier: "identifier")
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
    cell.textLabel?.text = "Blocked Users"
    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
    cell.backgroundColor = view.backgroundColor
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      let destination = BlockedUsersTableViewController()
      navigationController?.pushViewController(destination, animated: true)
    }
  }
}
