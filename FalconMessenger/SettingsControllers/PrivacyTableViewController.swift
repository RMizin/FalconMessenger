//
//  PrivacyTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


private let privacyTableViewCellID = "PrivacyTableViewCellID"

class PrivacyTableViewController: UITableViewController {
  
  
  var privacyElements = [PrivacyObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
      
      createDataSource()
      configureController()
    }
  
    fileprivate func configureController() {
      tableView = UITableView(frame: self.tableView.frame, style: .grouped)
      tableView.separatorStyle = .none
      
      title = "Privacy"
      extendedLayoutIncludesOpaqueBars = true
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.register(PrivacyTableViewCell.self, forCellReuseIdentifier: privacyTableViewCellID)
    }
  
    fileprivate func createDataSource() {
      let biometricsState = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
      let contactsSyncState = userDefaults.currentBoolObjectState(for: userDefaults.contactsContiniousSync)
      
      let biometricsObject = PrivacyObject(Biometrics().title, subtitle: nil, state: biometricsState, defaultsKey: userDefaults.biometricalAuth)
      let contactsSyncObject = PrivacyObject("Contacts syncronization", subtitle: nil, state: contactsSyncState, defaultsKey: userDefaults.contactsContiniousSync)
      privacyElements.append(biometricsObject)
      privacyElements.append(contactsSyncObject)
    }
  
    override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
    }
  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return privacyElements.count
    }
  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: privacyTableViewCellID, for: indexPath) as! PrivacyTableViewCell
      
      cell.title.text = privacyElements[indexPath.row].title
      cell.switchAccessory.isOn = privacyElements[indexPath.row].state
      
      cell.switchTapAction = { (isOn) in
        self.privacyElements[indexPath.row].state = isOn
      }
      return cell
    }
  
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 55
    }
  
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      return 65
    }
}
