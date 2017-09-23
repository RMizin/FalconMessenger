//
//  NotificationsAndSoundsTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/21/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class NotificationsAndSoundsTableViewController: UITableViewController {
  
   let accessorySwich = UISwitch()
  
  
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
      view.backgroundColor = .white
      navigationController?.navigationBar.backgroundColor = .white
    }
  
  
    fileprivate func configureUISwith () {
      
      accessorySwich.addTarget(self, action: #selector(switchStateChanged), for: .valueChanged)
      accessorySwich.setOn(UserDefaults.standard.bool(forKey: "In-AppSounds"), animated: false)
    }
  
  
    @objc func switchStateChanged() {
     
      if accessorySwich.isOn {
        UserDefaults.standard.set(true, forKey: "In-AppSounds")
      } else {
        UserDefaults.standard.set(false, forKey: "In-AppSounds")
      }
      
      UserDefaults.standard.synchronize()
    }
  
  
    deinit {
      print("Notifications And Sounds DID DEINIT")
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
      let identifier = "cell"
    
      let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
    
      cell.accessoryView = accessorySwich
      cell.textLabel?.text = "In-App Sounds"
      cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
    
      return cell
    }
  
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 55
    }
  
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      return 65
    }
}
