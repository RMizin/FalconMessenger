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
private let adminControlsCellID = "adminControlsCellID"

protocol UserBlockDelegate: class {
  func blockUser(with uid: String)
}

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
  var shouldDisplayContactAdder: Bool?
  private var observer: NSObjectProtocol!
  
  weak var delegate: UserBlockDelegate?
  
  let adminControls = ["Shared Media", "Block User"]

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupMainView()
    setupTableView()
    getUserInfo()
    addObservers()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
		if self.navigationController?.visibleViewController is SharedMediaController {
			return
		}
		
    if userReference != nil {
      userReference.removeObserver(withHandle: handle)
    }
  }
  
  deinit {
    print("user info deinit")
    NotificationCenter.default.removeObserver(observer)
  }
  
  fileprivate func addObservers() {
    observer = NotificationCenter.default.addObserver(forName: .localPhonesUpdated,
                                                      object: nil,
                                                      queue: .main) { [weak self] _ in
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
    tableView.register(GroupAdminControlsTableViewCell.self, forCellReuseIdentifier: adminControlsCellID)
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
    return 3
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		if section == 1 {
			return adminControls.count
		}

    return 1
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 100
    } else if indexPath.section == 2 {
      return 130
    } else {
      return 60
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
   
    let phoneNumberCell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? UserInfoPhoneNumberTableViewCell ?? UserInfoPhoneNumberTableViewCell()
    
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
      
      guard let photoURL = user?.thumbnailPhotoURL else {
        headerCell.icon.image = UIImage(named: "UserpicIcon")
        return headerCell
      }
      headerCell.icon.showActivityIndicator()
      headerCell.icon.sd_setImage(with: URL(string: photoURL),
                                  placeholderImage: UIImage(named: "UserpicIcon"),
                                  options: [.continueInBackground, .scaleDownLargeImages],
                                  completed: { (_, error, _, _) in
        headerCell.icon.hideActivityIndicator()
        guard error == nil else { return }
        headerCell.icon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openPhoto)))
      })
    
      return headerCell
      
    } else if indexPath.section == 2 {
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
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: adminControlsCellID,
                                               for: indexPath) as? GroupAdminControlsTableViewCell ?? GroupAdminControlsTableViewCell()


      cell.selectionStyle = .none
      cell.title.text = adminControls[indexPath.row]
			cell.title.textColor = cell.title.text == adminControls.last ? FalconPalette.dismissRed : view.tintColor
    
      return cell
    }
  }
  
  func setAttributedText(title: String, body: String) -> NSAttributedString {
    let mutableAttributedString = NSMutableAttributedString()
		let titleAttributes = [NSAttributedString.Key.foregroundColor: view.tintColor,
													 NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)]
		let bodyAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor,
													NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)]
		let titleAttributedString = NSAttributedString(string: title, attributes: titleAttributes as [NSAttributedString.Key : Any])
    let bodyAttributedString = NSAttributedString(string: body, attributes: bodyAttributes)
    mutableAttributedString.append(titleAttributedString)
    mutableAttributedString.append(bodyAttributedString)
    return mutableAttributedString
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.section == 1 {
			if indexPath.row == 0 {
				let destination = SharedMediaController(collectionViewLayout: UICollectionViewFlowLayout())
				destination.fetchingData = (userID: Auth.auth().currentUser!.uid, chatID: conversationID)
				navigationController?.pushViewController(destination, animated: true)
			} else {
				delegate?.blockUser(with: conversationID)
			}
    }
  }
}
