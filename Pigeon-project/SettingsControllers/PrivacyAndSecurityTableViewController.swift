//
//  PrivacyAndSecurityTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 4/16/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class PrivacyAndSecurityTableViewController: UITableViewController {

  let biometricalAuthSwich = UISwitch()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureController()
    configureUISwith()
  }
  
  fileprivate func configureController() {
    
    tableView = UITableView(frame: self.tableView.frame, style: .grouped)
    tableView.separatorStyle = .none
    
    title = "Privacy"
    extendedLayoutIncludesOpaqueBars = true
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  
  fileprivate func configureUISwith () {
    
    biometricalAuthSwich.addTarget(self, action: #selector(switchStateChanged(sender:)), for: .valueChanged)
    biometricalAuthSwich.setOn(UserDefaults.standard.bool(forKey: "BiometricalAuth"), animated: false)
  }
  
  @objc func switchStateChanged(sender: UISwitch) {
    if sender == biometricalAuthSwich {
      if sender.isOn {
        UserDefaults.standard.set(true, forKey: "BiometricalAuth")
      } else {
        UserDefaults.standard.set(false, forKey: "BiometricalAuth")
      }
    }
    UserDefaults.standard.synchronize()
  }
  
  deinit {
    print("Privacy DID DEINIT")
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
      
      let biometricType = UserDefaults.standard.integer(forKey: "biometricType")
      
      var title = String()
      switch biometricType {
        case 0: //none
          title = "Unlock with Passcode"
          break
        case 1: // touch id
           title = "Unlock with Touch ID"
         
          break
        case 2: // face id
          title = "Unlock with Face ID"
          break
        default: break
      }

      cell.accessoryView = biometricalAuthSwich
      
      cell.textLabel?.text = title
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
