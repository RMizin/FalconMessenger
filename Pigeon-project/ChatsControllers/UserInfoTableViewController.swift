//
//  UserInfoTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 10/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


private let headerIdentifier = "headerCell"

class UserInfoTableViewController: UITableViewController {

  var user: User?
  var contactName = String()
  var contactPhoneNumbers = [String]()
  var contactPhoto: NSURL?
  var onlineStatus: String? {
    didSet {
      tableView.reloadSections([0], with: .none)
    }
  }
  

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Info"
    view.backgroundColor = .white
    extendedLayoutIncludesOpaqueBars = true
    tableView.separatorStyle = .none
    
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
    }
  
    tableView.register(UserinfoHeaderTableViewCell.self, forCellReuseIdentifier: headerIdentifier)
    configureTitleViewWithOnlineStatus()
  }
    
    
  func configureTitleViewWithOnlineStatus() {
    
    guard let uid = Auth.auth().currentUser?.uid, let toId = self.user?.id else {
      return
    }
    
    Database.database().reference().child("users").child(toId).child("OnlineStatus").observeSingleEvent(of: .value, with: { (snapshot) in
      
      if uid == toId {
        self.onlineStatus = "You"
        return
      }
      
      if snapshot.exists() {
        if snapshot.value as! String == "Online" {
          self.onlineStatus = "Online"
            
        } else {
          
          let date = NSDate(timeIntervalSince1970:  (snapshot.value as! String).doubleValue )
          self.onlineStatus = ("Last seen " + timeAgoSinceDate(date: date, timeinterval: (snapshot.value as! String).doubleValue, numericDates: false))
        }
      }
    })
  }

  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if section == 0 {
      return 1
    } else if section == 1 {
      return contactPhoneNumbers.count
    } else {
      return 1
    }
  }
  
  deinit {
    print("Info DE INIT")
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let defaultIdentifier = "defaultCell"
   
    let cell = tableView.dequeueReusableCell(withIdentifier: defaultIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: defaultIdentifier)
    
    cell.textLabel?.textColor = .black
    
    if indexPath.section == 0 {
      
     let headerCell = tableView.dequeueReusableCell(withIdentifier: headerIdentifier, for: indexPath) as! UserinfoHeaderTableViewCell
      
      if contactPhoto != nil {
        headerCell.icon.sd_setImage(with: contactPhoto! as URL, placeholderImage: UIImage(named: "UserpicIcon"), options: [], completed: nil)
      } else {
         headerCell.icon.image = UIImage(named: "UserpicIcon")
      }
     
      headerCell.title.text = contactName
      headerCell.title.font = UIFont.boldSystemFont(ofSize: 20)
      headerCell.subtitle.text = onlineStatus
      headerCell.icon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPhoto)))
      
      return headerCell
      
    } else if indexPath.section == 1 {
      
      cell.textLabel?.text = contactPhoneNumbers[indexPath.row]
      cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 100
    } else {
      return 50
    }
  }
}
