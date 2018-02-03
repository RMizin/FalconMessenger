//
//  UserInfoTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 10/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

private let headerCellIdentifier = "headerCellIdentifier"
private let phoneNumberCellIdentifier = "phoneNumberCellIdentifier"
private let bioCellIdentifier = "bioCellIdentifier"


class UserInfoTableViewController: UITableViewController {

  var user: User?
  var contactName = String()
  var contactPhoneNumbers = [String]()
  var contactPhoto: NSURL?
  var contactBio: String?
  var onlineStatus: String?
  var bioRef: DatabaseReference!
  var shouldDisplayContactAdder:Bool?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Info"
    extendedLayoutIncludesOpaqueBars = true
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    
    configureTableView()
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
    }
  }

  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if bioRef != nil {
      bioRef.removeAllObservers()
    }
  }
  
  deinit {
    print("user info deinit")
  }
    
  
  fileprivate func configureTableView() {
    tableView.separatorStyle = .none
    tableView.register(UserinfoHeaderTableViewCell.self, forCellReuseIdentifier: headerCellIdentifier)
    tableView.register(UserInfoPhoneNumberTableViewCell.self, forCellReuseIdentifier: phoneNumberCellIdentifier)
    tableView.register(UserInfoBioTableViewCell.self, forCellReuseIdentifier: bioCellIdentifier)
    
    configureBioDisplaying()
  }
  

  fileprivate func configureBioDisplaying() {
    guard let toId = self.user?.id else { return }
    bioRef = Database.database().reference().child("users").child(toId).child("bio")
    bioRef.observe( .value, with: { (snapshot) in
      guard let stringSnapshot = snapshot.value as? String  else { return }
      self.contactBio = stringSnapshot
      self.tableView.reloadData()
    })
  }


  override func numberOfSections(in tableView: UITableView) -> Int {
    return 3
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
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 100
    } else if indexPath.section == 1 {
      return 90
    } else {
      return 80
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
   
    let phoneNumberCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! UserInfoPhoneNumberTableViewCell
    
    if localPhones.contains(contactPhoneNumbers[0].digits) {
      phoneNumberCell.add.isHidden = true
      phoneNumberCell.contactStatus.isHidden = true
      phoneNumberCell.addHeightConstraint.constant = 0
      phoneNumberCell.contactStatusHeightConstraint.constant = 0
    } else {
      phoneNumberCell.add.isHidden = false
      phoneNumberCell.contactStatus.isHidden = false
      phoneNumberCell.addHeightConstraint.constant = 20
      phoneNumberCell.contactStatusHeightConstraint.constant = 40
    }
    
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    if indexPath.section == 0 {
      let headerCell = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier, for: indexPath) as! UserinfoHeaderTableViewCell
      headerCell.title.text = contactName
      headerCell.title.font = UIFont.boldSystemFont(ofSize: 20)
      headerCell.subtitle.text = onlineStatus
      headerCell.selectionStyle = .none
      
      guard contactPhoto != nil else { headerCell.icon.image = UIImage(named: "UserpicIcon"); return headerCell }
      headerCell.icon.sd_setImage(with: contactPhoto! as URL, placeholderImage: UIImage(named: "UserpicIcon"), options: [], completed: { (image, error, cacheType, url) in
        guard error == nil else { return }
        headerCell.icon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openPhoto)))

      })
    
      return headerCell
      
    } else if indexPath.section == 1 {
      let phoneNumberCell = tableView.dequeueReusableCell(withIdentifier: phoneNumberCellIdentifier, for: indexPath) as! UserInfoPhoneNumberTableViewCell
      phoneNumberCell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      
      if localPhones.contains(contactPhoneNumbers[indexPath.row].digits) {
        phoneNumberCell.add.isHidden = true
        phoneNumberCell.contactStatus.isHidden = true
        phoneNumberCell.addHeightConstraint.constant = 0
        phoneNumberCell.contactStatusHeightConstraint.constant = 0
      } else {
        phoneNumberCell.add.isHidden = false
        phoneNumberCell.contactStatus.isHidden = false
        phoneNumberCell.addHeightConstraint.constant = 20
        phoneNumberCell.contactStatusHeightConstraint.constant = 40
      }
      
      phoneNumberCell.phoneLabel.textColor = ThemeManager.currentTheme().generalTitleColor
      phoneNumberCell.userInfoTableViewController = self
      phoneNumberCell.phoneLabel.text = contactPhoneNumbers[indexPath.row]
      phoneNumberCell.phoneLabel.font = UIFont.systemFont(ofSize: 17)
      phoneNumberCell.selectionStyle = .none
      
      return phoneNumberCell
      
    } else {
      let bioCell = tableView.dequeueReusableCell(withIdentifier: bioCellIdentifier, for: indexPath) as! UserInfoBioTableViewCell
      bioCell.textLabel?.numberOfLines = 0
      bioCell.textLabel?.font = UIFont.systemFont(ofSize: 17)
      bioCell.textLabel?.text = contactBio
      bioCell.selectionStyle = .none
      bioCell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      bioCell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
      
      return bioCell
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       self.tableView.deselectRow(at: indexPath, animated: true)
  }
}
