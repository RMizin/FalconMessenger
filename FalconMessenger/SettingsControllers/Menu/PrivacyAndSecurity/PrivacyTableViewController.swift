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
    return privacyElements.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: privacyTableViewCellID, for: indexPath) as! SwitchTableViewCell
    cell.currentViewController = self
    cell.setupCell(object: privacyElements[indexPath.row], index: indexPath.row)
   
    return cell
  }
}
