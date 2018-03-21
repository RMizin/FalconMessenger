//
//  GroupAdminControlsTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/19/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase


class GroupAdminControlsTableViewController: UITableViewController {
  
  fileprivate let membersCellID = "membersCellID"
  fileprivate let adminControlsCellID = "adminControlsCellID"
  
  let groupProfileTableHeaderContainer = GroupProfileTableHeaderContainer()
  let userProfilePictureOpener = GroupAdminControlsPictureOpener()
  
  var chatReference: DatabaseReference!
  var chatHandle: DatabaseHandle!
  var membersAddingReference: DatabaseReference!
  var membersAddingHandle: DatabaseHandle!
  var membersRemovingHandle: DatabaseHandle!
  
  var members = [User]()
  var adminControls:[GroupAdminControlls] = [GroupAdminControlls(name: "Manage members", icon: UIImage(named: "addUser")!),
                                             GroupAdminControlls(name: "Change administrator", icon: UIImage(named: "manageAdmins")!),
                                             GroupAdminControlls(name: "Leave the group", icon: UIImage(named: "leaveGroup")!)]//,
  //   GroupAdminControlls(name: "Dissolve the group", icon: UIImage(named: "dissolveGroup")!)]
  
  var chatID = String() {
    didSet {
      observeConversationDataChanges()
      observeMembersChanges()
    }
  }
  
  var isCurrentUserAdministrator = false
  
  var conversationAdminID = String() {
    didSet {
      manageControlsAppearance()
    }
  }
  
  var groupAvatarURL = String() {
    didSet {
      groupProfileTableHeaderContainer.profileImageView.showActivityIndicator()
      groupProfileTableHeaderContainer.profileImageView.sd_setImage(with: URL(string:groupAvatarURL), placeholderImage: nil, options: [], completed: { (image, error, cacheType, url) in
        self.groupProfileTableHeaderContainer.profileImageView.hideActivityIndicator()
        self.groupProfileTableHeaderContainer.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openUserProfilePicture)))
      })
    }
  }
  
 
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupMainView()
    setupTableView()
    setupColorsAccordingToTheme()
    setupContainerView()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    if chatReference != nil {
      chatReference.removeObserver(withHandle: chatHandle)
      chatReference = nil
      chatHandle = nil
    }
    
    if membersAddingReference != nil && membersAddingHandle != nil {
      membersAddingReference.removeObserver(withHandle: membersAddingHandle)
    }
    
    if membersAddingReference != nil && membersRemovingHandle != nil {
      membersAddingReference.removeObserver(withHandle: membersRemovingHandle)
    }
  }
  
  deinit {
    print("\nadmin deinit\n")
  }
  

  fileprivate func setupMainView() {
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
      navigationController?.navigationBar.prefersLargeTitles = true
    }
    navigationItem.title = "Group Info"
    extendedLayoutIncludesOpaqueBars = true
    definesPresentationContext = true
    edgesForExtendedLayout = [UIRectEdge.top, UIRectEdge.bottom]
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  fileprivate func setupTableView() {
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: membersCellID)
    tableView.register(AccountSettingsTableViewCell.self, forCellReuseIdentifier: adminControlsCellID)
    tableView.separatorStyle = .none
    tableView.allowsSelection = false
    tableView.prefetchDataSource = self
  }
  
  fileprivate func setupContainerView() {
 
    groupProfileTableHeaderContainer.name.delegate = self
    groupProfileTableHeaderContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 170)
    groupProfileTableHeaderContainer.name.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    tableView.tableHeaderView = groupProfileTableHeaderContainer
  }
  
  fileprivate func setupColorsAccordingToTheme() {
    groupProfileTableHeaderContainer.profileImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.userData.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.name.textColor = ThemeManager.currentTheme().generalTitleColor
    groupProfileTableHeaderContainer.name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
  }
  
  fileprivate func manageControlsAppearance() {
    if conversationAdminID != Auth.auth().currentUser!.uid {
      groupProfileTableHeaderContainer.addPhotoLabel.isHidden = true
      groupProfileTableHeaderContainer.name.isUserInteractionEnabled = false
      isCurrentUserAdministrator = false
    } else {
      groupProfileTableHeaderContainer.addPhotoLabel.isHidden = false
      groupProfileTableHeaderContainer.name.isUserInteractionEnabled = true
      isCurrentUserAdministrator = true
    }
  }

  fileprivate func observeConversationDataChanges() {
    
    chatReference = Database.database().reference().child("user-messages").child(Auth.auth().currentUser!.uid).child(chatID).child(messageMetaDataFirebaseFolder)
    chatHandle = chatReference.observe( .value) { (snapshot) in
      guard let conversationDictionary = snapshot.value as? [String: AnyObject] else { return }
      let conversation = Conversation(dictionary: conversationDictionary)
      
      if let url = conversation.chatPhotoURL {
         self.groupAvatarURL = url
      }
      
      if let name = conversation.chatName {
        self.groupProfileTableHeaderContainer.name.text = name
      }
      
      if let admin = conversation.admin {
        self.conversationAdminID = admin
      }
    }
  }
  
  func observeMembersChanges() {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    membersAddingReference = Database.database().reference().child("user-messages").child(uid).child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs")
    
    membersAddingHandle = membersAddingReference.observe(.childAdded) { (snapshot) in
      guard let id = snapshot.value as? String else { return }
      
      let newMemberReference = Database.database().reference().child("users").child(id)
      
      newMemberReference.observeSingleEvent(of: .value, with: { (snapshot) in
        
        guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
      
        let user = User(dictionary: dictionary)
        
        if let userIndex = self.members.index(where: { (member) -> Bool in
          return member.id == snapshot.key }) {
          self.members[userIndex] = user
        } else {
          self.members.append(user)
        }
        
        DispatchQueue.main.async {
          self.tableView.reloadSections([1], with: .none)
        }
      })
    }
    
    membersRemovingHandle = membersAddingReference.observe(.childRemoved) { (snapshot) in
      guard let id = snapshot.value as? String else { return }
      
      guard let memberIndex = self.members.index(where: { (member) -> Bool in
        return member.id == id
      }) else { return }
      
      self.members.remove(at: memberIndex)
      
      DispatchQueue.main.async {
        self.tableView.reloadSections([1], with: .none)
      }
    }
  }
  
  @objc fileprivate func openUserProfilePicture() {
    userProfilePictureOpener.controllerWithUserProfilePhoto = self
    userProfilePictureOpener.userProfileContainerView = groupProfileTableHeaderContainer
    userProfilePictureOpener.openUserProfilePicture()
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if textField.text?.count == 0 {
      navigationItem.rightBarButtonItem?.isEnabled = false
    } else {
      navigationItem.rightBarButtonItem?.isEnabled = true
    }
  }
  
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      if adminControls.count == 0 {
        return ""
      }
      return "Group management"
    }
    return "\(members.count) members"
  }

  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    
    if section == 0 {
      return 20
    }
    return 50
  }
  
  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
    if let headerTitle = view as? UITableViewHeaderFooterView {
      headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 14)
    }
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return adminControls.count
    }
    return members.count
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 
    if indexPath.section == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: adminControlsCellID, for: indexPath) as! AccountSettingsTableViewCell
      cell.title.text = adminControls[indexPath.row].controlName
      cell.icon.image = adminControls[indexPath.row].controlIcon
      if indexPath.row == 0 || indexPath.row == 1 {
        cell.title.textColor = FalconPalette.falconPaletteBlue
      } else {
        cell.title.textColor = .red
      }
      return cell
    
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: membersCellID, for: indexPath) as! FalconUsersTableViewCell
      
      if members[indexPath.row].id == conversationAdminID {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        label.text = "admin"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        cell.accessoryType = UITableViewCellAccessoryType.none
        cell.accessoryView = label
        cell.accessoryView?.backgroundColor = UIColor.clear
      } else {
        cell.accessoryView = nil
      }
      
      if let name = members[indexPath.row].name {
        cell.title.text = name
      }
      if members[indexPath.row].id == Auth.auth().currentUser?.uid {
        cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
        cell.subtitle.text = "You"
      } else {
        if let statusString = members[indexPath.row].onlineStatus as? String {
          if statusString == statusOnline {
            cell.subtitle.textColor = FalconPalette.falconPaletteBlue
            cell.subtitle.text = statusString
          } else {
            cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
            let date = Date(timeIntervalSince1970: TimeInterval(statusString)!)
            let subtitle = "Last seen " + timeAgoSinceDate(date)
            cell.subtitle.text = subtitle
          }
        } else if let statusTimeinterval = members[indexPath.row].onlineStatus as? TimeInterval {
          cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
          let date = Date(timeIntervalSince1970: statusTimeinterval/1000)
          let subtitle = "Last seen " + timeAgoSinceDate(date)
          cell.subtitle.text = subtitle
        }
      }
      
      guard let url = members[indexPath.row].thumbnailPhotoURL else { return cell }
      cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.progressiveDownload, .continueInBackground], completed: { (image, error, cacheType, url) in
        guard image != nil else { return }
        guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
          cell.icon.alpha = 1
          return
        }
        cell.icon.alpha = 0
        UIView.animate(withDuration: 0.25, animations: { cell.icon.alpha = 1 })
      })
      return cell
    }
  }
}

extension GroupAdminControlsTableViewController: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let urls = members.map { URL(string: $0.photoURL ?? "")  }
    SDWebImagePrefetcher.shared().prefetchURLs(urls as? [URL])
  }
}

extension GroupAdminControlsTableViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
