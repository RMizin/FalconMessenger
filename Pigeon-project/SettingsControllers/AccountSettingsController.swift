//
//  AccountSettingsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/5/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


class AccountSettingsController: UIViewController {

  let accountSettingsTableView: UITableView = UITableView(frame: CGRect.zero, style: .grouped)
  
  let accountSettingsCellId = "userProfileCell"

  var firstSection = [( icon: UIImage(named: "Notification") , title: "Notifications and sounds" ),
                      ( icon: UIImage(named: "ChangeNumber") , title: "Change number"),
                      ( icon: UIImage(named: "Storage") , title: "Data and storage")]
  
  var secondSection = [/* ( icon: UIImage(named: "language") , title: "Язык", controller: nil), */
    ( icon: UIImage(named: "About") , title: "About"),
    ( icon: UIImage(named: "Logout") , title: "Log out")]
  
  fileprivate func basicErrorAlertWith (title:String, message: String) {
    
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Settings"
    view.backgroundColor = UIColor.white
    view.addSubview(accountSettingsTableView)
    
    accountSettingsTableView.delegate = self
    accountSettingsTableView.dataSource = self
    accountSettingsTableView.backgroundColor = UIColor.white
    accountSettingsTableView.separatorStyle = .none
    accountSettingsTableView.isScrollEnabled = false
    accountSettingsTableView.register(AccountSettingsTableViewCell.self, forCellReuseIdentifier: accountSettingsCellId)
    setConstraints()
  }
  
  
  fileprivate func setConstraints() {
    accountSettingsTableView.translatesAutoresizingMaskIntoConstraints = false
    accountSettingsTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    accountSettingsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    accountSettingsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    accountSettingsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
  }
  
  
  func removeUserNotificationToken() {
    
    let userReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("notificationTokens")
    
    userReference.removeValue()// updateChildValues([token : true])
  }
  func logoutButtonTapped () {
    
    
    self.tabBarController?.selectedIndex = tabs.chats.rawValue
    removeUserNotificationToken()
    let firebaseAuth = Auth.auth()
    do {
      try firebaseAuth.signOut()
    
    } catch let signOutError as NSError {
      print ("Error signing out: %@", signOutError)
      basicErrorAlertWith(title: "Error signing out", message: "Please check your internet connection and try again later.")
      return
    }
    UIApplication.shared.applicationIconBadgeNumber = 0
    let destination = OnboardingController()
    
    let newNavigationController = UINavigationController(rootViewController: destination)
    newNavigationController.navigationBar.shadowImage = UIImage()
    newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
    
    newNavigationController.navigationBar.isTranslucent = false
    newNavigationController.modalTransitionStyle = .crossDissolve
    
    self.present(newNavigationController, animated: true, completion: nil)
    
  }
  
}

extension AccountSettingsController: UIScrollViewDelegate {}
extension AccountSettingsController: UITableViewDelegate {}


extension AccountSettingsController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = accountSettingsTableView.dequeueReusableCell(withIdentifier: accountSettingsCellId, for: indexPath) as! AccountSettingsTableViewCell
    
    if indexPath.section == 0 {
      
      cell.icon.image = firstSection[indexPath.row].icon
      cell.title.text = firstSection[indexPath.row].title
    }
    
    if indexPath.section == 1 {
      
      cell.icon.image = secondSection[indexPath.row].icon
      cell.title.text = secondSection[indexPath.row].title
      
      if indexPath.row == 1 {
        cell.accessoryType = .none
        
      }
    }
    return cell
  }
  
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.section == 0 {
      
      if indexPath.row == 0 {
        let destination = NotificationsAndSoundsTableViewController()
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination  , animated: true)
      }
      
      if indexPath.row == 1 {
        
      }
      
      if indexPath.row == 2 {
        let destination = StorageTableViewController()
        destination.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(destination  , animated: true)
      }
    }
    
      
      if indexPath.section == 1 {
        
        if indexPath.row == 0 {
          let destination = AboutTableViewController()
          destination.hidesBottomBarWhenPushed = true
          self.navigationController?.pushViewController(destination  , animated: true)
        }
        
        if indexPath.row == 1 {
          
          logoutButtonTapped()
        }
      }
    
    accountSettingsTableView.deselectRow(at: indexPath, animated: true)
  }
  
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
  }
  
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if section == 0 {
      return firstSection.count
    }
    if section == 1 {
      return secondSection.count
    } else {
      
      return 0
    }
  }
}
