//
//  NotificationsTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/17/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class NotificationsTableViewController: MenuControlsTableViewController {

	var notificationElements = [SwitchObject]()

  override func viewDidLoad() {
		super.viewDidLoad()
    createDataSource()
		navigationItem.title = "Notifications"
  }

  fileprivate func createDataSource() {
    let inAppNotificationsState = userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications)
    let inAppSoundsState = userDefaults.currentBoolObjectState(for: userDefaults.inAppSounds)
    let inAppVibrationState = userDefaults.currentBoolObjectState(for: userDefaults.inAppVibration)
    let inAppNotifications = SwitchObject("In-App Preview", subtitle: nil, state: inAppNotificationsState, defaultsKey: userDefaults.inAppNotifications)
    let inAppSounds = SwitchObject("In-App Sounds", subtitle: nil, state: inAppSoundsState, defaultsKey: userDefaults.inAppSounds)
    let inAppVibration =  SwitchObject("In-App Vibrate", subtitle: nil, state: inAppVibrationState, defaultsKey: userDefaults.inAppVibration)
    
    notificationElements.append(inAppNotifications)
    notificationElements.append(inAppSounds)
    notificationElements.append(inAppVibration)
  }

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return notificationElements.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: switchCellID, for: indexPath) as? SwitchTableViewCell ?? SwitchTableViewCell()
    cell.currentViewController = self
    cell.setupCell(object: notificationElements[indexPath.row], index: indexPath.row)
    
    return cell
  }
}
