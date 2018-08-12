//
//  NotificationsAndSoundsTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/21/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class NotificationsAndSoundsTableViewController: UITableViewController {
  
   let notificationsSwich = UISwitch()
   let soundsSwich = UISwitch()
   let vibrationSwich = UISwitch()
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
      configureController()
      configureUISwith()
    }
  

    fileprivate func configureController() {
     
      tableView = UITableView(frame: self.tableView.frame, style: .grouped)
      tableView.separatorStyle = .none
      
      title = "Notifications"
      extendedLayoutIncludesOpaqueBars = true
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    }
  
  
    fileprivate func configureUISwith () {
      
      soundsSwich.addTarget(self, action: #selector(switchStateChanged(sender:)), for: .valueChanged)
      soundsSwich.setOn(userDefaults.currentBoolObjectState(for: userDefaults.inAppSounds), animated: false)
      
      vibrationSwich.addTarget(self, action: #selector(switchStateChanged(sender:)), for: .valueChanged)
      vibrationSwich.setOn(userDefaults.currentBoolObjectState(for: userDefaults.inAppVibration), animated: false)
      
      notificationsSwich.addTarget(self, action: #selector(switchStateChanged(sender:)), for: .valueChanged)
      notificationsSwich.setOn(userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications), animated: false)
    }
  
  
  @objc func switchStateChanged(sender:UISwitch) {
    if sender == soundsSwich {
      if sender.isOn {
        userDefaults.updateObject(for: userDefaults.inAppSounds, with: true)
      } else {
        userDefaults.updateObject(for: userDefaults.inAppSounds, with: false)
      }

    } else if sender == vibrationSwich {
      if sender.isOn {
        userDefaults.updateObject(for: userDefaults.inAppVibration, with: true)
      } else {
        userDefaults.updateObject(for: userDefaults.inAppVibration, with: false)
      }
    } else if sender == notificationsSwich {
      if sender.isOn {
        userDefaults.updateObject(for: userDefaults.inAppNotifications, with: true)
      } else {
        userDefaults.updateObject(for: userDefaults.inAppNotifications, with: false)
      }
    }
  }
  
  
    deinit {
      print("Notifications And Sounds DID DEINIT")
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
      let identifier = "cell"
    
      let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
      cell.backgroundColor = view.backgroundColor
      cell.selectionStyle = .none
      cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
      cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
      if indexPath.row == 0 {
        cell.accessoryView = notificationsSwich
        cell.textLabel?.text = "In-App Preview"
      }
      if indexPath.row == 1 {
        cell.accessoryView = soundsSwich
        cell.textLabel?.text = "In-App Sounds"
      }
      if indexPath.row == 2 {
        cell.accessoryView = vibrationSwich
        cell.textLabel?.text = "In-App Vibrate"
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
