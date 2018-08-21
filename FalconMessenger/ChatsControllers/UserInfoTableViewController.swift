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

  var user: User? {
    didSet {
      contactPhoneNumber = user?.phoneNumber ?? ""
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  var conversationID = String()
  var onlineStatus = String()
  var contactPhoneNumber = String()

  var userReference: DatabaseReference!
  var handle: DatabaseHandle!
  var shouldDisplayContactAdder:Bool?
  private var observer: NSObjectProtocol!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupMainView()
    setupTableView()
    getUserInfo()
    addObservers()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if userReference != nil {
      userReference.removeObserver(withHandle: handle)
    }
  }
  
  deinit {
    print("user info deinit")
    NotificationCenter.default.removeObserver(observer)
  }
  
  fileprivate func addObservers() {
    observer = NotificationCenter.default.addObserver(forName: .localPhonesUpdated, object: nil, queue: .main) { [weak self] notification in
      DispatchQueue.main.async {
        self?.tableView.reloadData()
      }
    }
  }
  
  fileprivate func setupMainView() {
    title = "Info"
    extendedLayoutIncludesOpaqueBars = true
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
    }
  }
  
  fileprivate func setupTableView() {
    tableView.separatorStyle = .none
    tableView.register(UserinfoHeaderTableViewCell.self, forCellReuseIdentifier: headerCellIdentifier)
    tableView.register(UserInfoPhoneNumberTableViewCell.self, forCellReuseIdentifier: phoneNumberCellIdentifier)
  }
  
  fileprivate func getUserInfo() {
    userReference = Database.database().reference().child("users").child(conversationID)
    handle = userReference.observe(.value) { (snapshot) in
      if snapshot.exists() {
        guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
        self.user = User(dictionary: dictionary)
      }
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
  
    if indexPath.section == 0 {
      return 100
    } else {
      return 200
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
   
    let phoneNumberCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! UserInfoPhoneNumberTableViewCell
    
    if globalDataStorage.localPhones.contains(contactPhoneNumber.digits) {
      phoneNumberCell.add.isHidden = true
      phoneNumberCell.contactStatus.isHidden = true
      phoneNumberCell.addHeightConstraint.constant = 0
      phoneNumberCell.contactStatusHeightConstraint.constant = 0
    } else {
      phoneNumberCell.add.isHidden = false
      phoneNumberCell.contactStatus.isHidden = false
      phoneNumberCell.addHeightConstraint.constant = 40
      phoneNumberCell.contactStatusHeightConstraint.constant = 40
    }
  }
  
  fileprivate func stringTimestamp(onlineStatusObject: AnyObject) -> String {
    if let onlineStatusStringStamp = onlineStatusObject as? String, onlineStatusStringStamp == statusOnline {
      return statusOnline
    } else if let onlineStatusTimeIntervalStamp = onlineStatusObject as? TimeInterval { //user got server timestamp in miliseconds
      let date = Date(timeIntervalSince1970: onlineStatusTimeIntervalStamp/1000)
      let subtitle = "Last seen " + timeAgoSinceDate(date)
      return subtitle
    }
    return ""
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    if indexPath.section == 0 {
      
      let headerCell = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier,
                                                     for: indexPath) as? UserinfoHeaderTableViewCell ?? UserinfoHeaderTableViewCell()
      
      headerCell.title.text = user?.name ?? ""
      headerCell.title.font = UIFont.boldSystemFont(ofSize: 20)
      
      if let timestamp = user?.onlineStatus {
        headerCell.subtitle.text = stringTimestamp(onlineStatusObject: timestamp)
      }
    
      headerCell.selectionStyle = .none
      
      guard let photoURL = user?.photoURL else { headerCell.icon.image = UIImage(named: "UserpicIcon"); return headerCell }
      headerCell.icon.showActivityIndicator()
      headerCell.icon.sd_setImage(with: URL(string: photoURL), placeholderImage: UIImage(named: "UserpicIcon"), options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
         headerCell.icon.hideActivityIndicator()
        guard error == nil else { return }
        headerCell.icon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openPhoto)))
      })
    
      return headerCell
      
    } else {
      let phoneNumberCell = tableView.dequeueReusableCell(withIdentifier: phoneNumberCellIdentifier,
                                                          for: indexPath) as? UserInfoPhoneNumberTableViewCell ?? UserInfoPhoneNumberTableViewCell()
      phoneNumberCell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      phoneNumberCell.userInfoTableViewController = self
      
      if globalDataStorage.localPhones.contains(contactPhoneNumber.digits) {
        phoneNumberCell.add.isHidden = true
        phoneNumberCell.contactStatus.isHidden = true
        phoneNumberCell.addHeightConstraint.constant = 0
        phoneNumberCell.contactStatusHeightConstraint.constant = 0
      } else {
        phoneNumberCell.add.isHidden = false
        phoneNumberCell.contactStatus.isHidden = false
        phoneNumberCell.addHeightConstraint.constant = 40
        phoneNumberCell.contactStatusHeightConstraint.constant = 40
      }
      
      var phoneTitle = "mobile\n"
      let phoneBody = user?.phoneNumber ?? ""
      if phoneBody == "" || phoneBody == " " { phoneTitle = "" }
      phoneNumberCell.phoneLabel.attributedText = setAttributedText(title: phoneTitle, body: phoneBody)
      
      var bioTitle = "bio\n"
      let bioBody = user?.bio ?? ""
      if bioBody == "" || bioBody == " " { bioTitle = "" }
      phoneNumberCell.bio.attributedText = setAttributedText(title: bioTitle, body: bioBody)
      
      return phoneNumberCell
    }
  }
  
  func setAttributedText(title: String, body: String) -> NSAttributedString {
    let mutableAttributedString = NSMutableAttributedString()
    let titleAttributes = [ NSAttributedStringKey.foregroundColor: FalconPalette.defaultBlue, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)]
    let bodyAttributes = [ NSAttributedStringKey.foregroundColor: ThemeManager.currentTheme().generalTitleColor, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18)]
    let titleAttributedString = NSAttributedString(string: title, attributes: titleAttributes)
    let bodyAttributedString = NSAttributedString(string: body, attributes: bodyAttributes)
    mutableAttributedString.append(titleAttributedString)
    mutableAttributedString.append(bodyAttributedString)
    return mutableAttributedString
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
