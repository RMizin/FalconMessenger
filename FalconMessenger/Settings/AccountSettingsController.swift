//
//  AccountSettingsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/5/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import ARSLineProgress

class AccountSettingsController: UITableViewController {

  let userProfileContainerView = UserProfileContainerView()
  let avatarOpener = AvatarOpener()
  let userProfileDataDatabaseUpdater = UserProfileDataDatabaseUpdater()
  
  let accountSettingsCellId = "userProfileCell"

  var firstSection = [( icon: UIImage(named: "Notification"), title: "Notifications and Sounds"),
                      ( icon: UIImage(named: "Privacy"), title: "Privacy and Security"),
                      ( icon: UIImage(named: "ChangeNumber"), title: "Change Number"),
											(	icon: UIImage(named: "Appearance"), title: "Appearance"),
                      ( icon: UIImage(named: "Storage"), title: "Data and Storage")]
  
  var secondSection = [( icon: UIImage(named: "Legal"), title: "About"),
                       ( icon: UIImage(named: "Logout"), title: "Log Out")]
  
  let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonPressed))
  let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneBarButtonPressed))
  
  var currentName = String()
  var currentBio = String()
  
  override func viewDidLoad() {
     super.viewDidLoad()
    
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.top
    tableView = UITableView(frame: tableView.frame, style: .grouped)
    configureTableView()
    configureContainerView()
    listenChanges()
    addObservers()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if userProfileContainerView.phone.text == "" {
      listenChanges()
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
		layoutTableHeaderView()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		layoutTableHeaderView()
	}

	fileprivate func layoutTableHeaderView() {
		guard let headerView = tableView.tableHeaderView else { return }
		let height = tableHeaderHeight()
		var headerFrame = headerView.frame
		guard height != headerFrame.size.height else { return }
		headerFrame.size.height = height
		headerView.frame = headerFrame
		tableView.tableHeaderView = headerView
	}

  fileprivate func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(clearUserData), name: NSNotification.Name(rawValue: "clearUserData"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
  }
  
  @objc fileprivate func changeTheme() {
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.backgroundColor = view.backgroundColor
    navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
    navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
    tabBarController?.tabBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
    tabBarController?.tabBar.barStyle = ThemeManager.currentTheme().barStyle
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    userProfileContainerView.addPhotoLabel.textColor = ThemeManager.currentTheme().tintColor
    userProfileContainerView.backgroundColor = view.backgroundColor
    userProfileContainerView.profileImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    userProfileContainerView.userData.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    userProfileContainerView.name.textColor = ThemeManager.currentTheme().generalTitleColor
    userProfileContainerView.bio.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    userProfileContainerView.bio.textColor = ThemeManager.currentTheme().generalTitleColor
    userProfileContainerView.bio.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    userProfileContainerView.name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    tableView.reloadData()
  
    guard let splitViewController = splitViewController, splitViewController.viewControllers.indices.contains(1) else { return }
    if let placeholder = splitViewController.viewControllers[1] as? SplitPlaceholderViewController {
      placeholder.updateBackgrounColor()
    }
  }
  
  @objc fileprivate func openUserProfilePicture() {
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
      return
    }
    avatarOpener.delegate = self
    avatarOpener.handleAvatarOpening(avatarView: userProfileContainerView.profileImageView, at: self,
																		 isEditButtonEnabled: true,
																		 title: .user,
																		 urlString: nil,
																		 thumbnailURLString: nil)
    cancelBarButtonPressed()
  }

  @objc func clearUserData() {
    userProfileContainerView.name.text = ""
    userProfileContainerView.phone.text = ""
    userProfileContainerView.profileImageView.image = nil
  }
  
  func listenChanges() {
    if let currentUser = Auth.auth().currentUser?.uid {
      let photoURLReference = Database.database().reference().child("users").child(currentUser).child("photoURL")
      photoURLReference.observe(.value, with: { [weak self] (snapshot) in
        if let url = snapshot.value as? String {
          self?.userProfileContainerView.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: nil, options: [.scaleDownLargeImages, .continueInBackground], completed: nil)
        }
      })
      
      let nameReference = Database.database().reference().child("users").child(currentUser).child("name")
      nameReference.observe(.value, with: { [weak self] (snapshot) in
        if let name = snapshot.value as? String {
          self?.userProfileContainerView.name.text = name
          self?.currentName = name
        }
      })
      
      let bioReference = Database.database().reference().child("users").child(currentUser).child("bio")
      bioReference.observe(.value, with: { [weak self] (snapshot) in
				guard let unwrappedSelf = self else { return }
        if let bio = snapshot.value as? String {
          unwrappedSelf.userProfileContainerView.bio.text = bio
          unwrappedSelf.userProfileContainerView.bioPlaceholderLabel.isHidden = !unwrappedSelf.userProfileContainerView.bio.text.isEmpty
          unwrappedSelf.currentBio = bio
        }
      })
      
      let phoneNumberReference = Database.database().reference().child("users").child(currentUser).child("phoneNumber")
      phoneNumberReference.observe(.value, with: { [weak self] (snapshot) in
        if let phoneNumber = snapshot.value as? String {
          self?.userProfileContainerView.phone.text = phoneNumber
        }
      })
    }
  }

  fileprivate func configureTableView() {
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.separatorStyle = .none
    tableView.sectionHeaderHeight = 0
		tableView.showsVerticalScrollIndicator = false
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.tableHeaderView = userProfileContainerView
    tableView.register(AccountSettingsTableViewCell.self, forCellReuseIdentifier: accountSettingsCellId)
  }
  
  fileprivate func configureContainerView() {
    userProfileContainerView.name.addTarget(self, action: #selector(nameDidBeginEditing), for: .editingDidBegin)
    userProfileContainerView.name.addTarget(self, action: #selector(nameEditingChanged), for: .editingChanged)
    userProfileContainerView.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openUserProfilePicture)))
    userProfileContainerView.bio.delegate = self
    userProfileContainerView.name.delegate = self
  }
  
  func logoutButtonTapped() {
    if DeviceType.isIPad {
        UIView.performWithoutAnimation {
            splitViewController?.showDetailViewController(SplitPlaceholderViewController(), sender: self)
        }
    }
    
    let firebaseAuth = Auth.auth()
    guard let uid = Auth.auth().currentUser?.uid else { return }
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: "Error signing out", message: noInternetError, controller: self)
      return
    }
    ARSLineProgress.ars_showOnView(tableView)
  
    let userReference = Database.database().reference().child("users").child(uid).child("notificationTokens")
    userReference.removeValue { [weak self] (error, reference) in

    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearUserData"), object: nil)

    Database.database().reference(withPath: ".info/connected").removeAllObservers()
      
      if error != nil {
        ARSLineProgress.hide()
        basicErrorAlertWith(title: "Error signing out", message: "Try again later", controller: self)
        return
      }
      
      let onlineStatusReference = Database.database().reference().child("users").child(uid).child("OnlineStatus")
      onlineStatusReference.setValue(ServerValue.timestamp())
      
      do {
        try firebaseAuth.signOut()
        
      } catch let signOutError as NSError {
        ARSLineProgress.hide()
        basicErrorAlertWith(title: "Error signing out", message: signOutError.localizedDescription, controller: self)
        return
      }
      AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
      UIApplication.shared.applicationIconBadgeNumber = 0
      
      let destination = OnboardingController()
      
      let navigationController = UINavigationController(rootViewController: destination)
      navigationController.navigationBar.isTranslucent = false
      navigationController.modalTransitionStyle = .crossDissolve
      navigationController.modalPresentationStyle = .overFullScreen
      if #available(iOS 13.0, *) {
          navigationController.isModalInPresentation = true
      }
        
      ARSLineProgress.hide()
      if DeviceType.isIPad {
        self?.splitViewController?.show(navigationController, sender: self)
      } else {
        self?.present(navigationController, animated: true, completion: {
          self?.tabBarController?.selectedIndex = Tabs.chats.rawValue
        })
      }
    }
  }
}

extension AccountSettingsController {
  
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: accountSettingsCellId, for: indexPath) as! AccountSettingsTableViewCell
    cell.accessoryType = .disclosureIndicator
  
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
  
 override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let destination = NotificationsTableViewController()
        destination.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(destination, animated: true)
      }
      
      if indexPath.row == 1 {
        let destination = PrivacyTableViewController()
        destination.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(destination, animated: true)
      }
      
      if indexPath.row == 2 {
         AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        let controller = ChangePhoneNumberController()
        
        if DeviceType.isIPad {
         controller.hidesBottomBarWhenPushed = true
         navigationController?.pushViewController(controller, animated: true)
        } else {
          let destination = UINavigationController(rootViewController: controller)
       //   destination.navigationBar.shadowImage = UIImage()
         // destination.navigationBar.setBackgroundImage(UIImage(), for: .default)
          destination.hidesBottomBarWhenPushed = true
          destination.navigationBar.isTranslucent = false
          present(destination, animated: true, completion: nil)
        }

      }

			if indexPath.row == 3  {
				let destination = AppearanceTableViewController()
				destination.hidesBottomBarWhenPushed = true
				navigationController?.pushViewController(destination, animated: true)
			}

      if indexPath.row == 4  {
        let destination = StorageTableViewController()
        destination.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(destination, animated: true)
      }
    }
      
    if indexPath.section == 1 {
      if indexPath.row == 0 {
        let destination = AboutTableViewController()
        destination.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(destination, animated: true)
      }
        
      if indexPath.row == 1 {
        logoutButtonTapped()
      }
    }
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
   return 2
  }
  
  override  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
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
