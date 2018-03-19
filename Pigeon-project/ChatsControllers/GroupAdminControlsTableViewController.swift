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
  
  fileprivate var membersCellID = "membersCellID"
  
  let groupProfileTableHeaderContainer = GroupProfileTableHeaderContainer()
  
  let userProfilePictureOpener = GroupAdminControlsPictureOpener()
  
  var chatReference: DatabaseReference!
  
  var chatHandle: DatabaseHandle!
  
  var chatID: String!
  
  var conversationAdminID:String!

  
  var members: [User]! {
    didSet {
      setConversationData()
    }
  }
  
  var initialAvatarSet = true
  
  var groupAvatarURL:String! {
    didSet {
     
      if groupAvatarURL != "" && initialAvatarSet {
        self.groupProfileTableHeaderContainer.profileImageView.showActivityIndicator()
        groupProfileTableHeaderContainer.profileImageView.sd_setImage(with: URL(string:groupAvatarURL), placeholderImage: nil, options: [], completed: { (image, error, cacheType, url) in
          self.groupProfileTableHeaderContainer.profileImageView.hideActivityIndicator()
          self.initialAvatarSet = false
        })
      }
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
    print("view did dissappear")
    if chatReference != nil {
      chatReference.removeObserver(withHandle: chatHandle)
      chatReference = nil
      chatReference = nil
    }
  }
  
  deinit {
    print("admin deinit")
  }
  

  fileprivate func setupMainView() {
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
      navigationController?.navigationBar.prefersLargeTitles = true
    }
    navigationItem.title = "Info"
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
    tableView.separatorStyle = .none
    tableView.allowsSelection = false
    tableView.prefetchDataSource = self
  }
  
  fileprivate func setupContainerView() {
    groupProfileTableHeaderContainer.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openUserProfilePicture)))
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
  
  
  fileprivate func setConversationData() {
    chatReference = Database.database().reference().child("user-messages").child(Auth.auth().currentUser!.uid).child(chatID).child(messageMetaDataFirebaseFolder)
    chatHandle = chatReference.observe( .value) { (snapshot) in
      guard let conversationDictionary = snapshot.value as? [String: AnyObject] else { return }
      let conversation = Conversation(dictionary: conversationDictionary)
      if let url = conversation.chatPhotoURL {
         self.groupAvatarURL = url
      } else {
        self.groupAvatarURL = ""
      }
      
      if let name = conversation.chatName {
        self.groupProfileTableHeaderContainer.name.text = name
      } else {
        self.groupProfileTableHeaderContainer.name.text = ""
      }
      
      if let admin = conversation.admin {
        self.conversationAdminID = admin
      } else {
       self.conversationAdminID = ""
      }

      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  /*fileprivate func observeConversationChanges() {
    
    changesReference = Database.database().reference().child("user-messages").child(Auth.auth().currentUser!.uid).child(chatID).child(messageMetaDataFirebaseFolder)
    changesHandle = changesReference.observe(.childChanged) { (snapshot) in
      
      print("child changed")
      
      if snapshot.key == "chatOriginalPhotoURL" {
        self.setChangedURL(from: snapshot)
      } else if snapshot.key == "chatParticipantsIDs" {
        self.setChangedMembers(from: snapshot)
      }
    }
    
  }*/
  
  
  /*
  fileprivate func setChangedURL( from snapshot: DataSnapshot) {
    print("url changed")
    guard let newURL = snapshot.value as? String else { self.groupAvatarURL = ""; print(self.groupAvatarURL, "gravurl return"); return }
    self.groupAvatarURL = newURL
    print(self.groupAvatarURL, "gravurl")
  }
  
  fileprivate func setChangedMembers(from snapshot: DataSnapshot) {
    print("members changed")
    guard let newMembers = snapshot.value as? [String] else  { return }
    
    var newMembersArray = [User]()
    let group = DispatchGroup()
    
    for _ in newMembers {
      group.enter()
    }
    
    group.notify(queue: DispatchQueue.main, execute: {
      self.members = newMembersArray
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    })
    
    for newMember in newMembers {
      let userRef = Database.database().reference().child("users").child(newMember)
      userRef.observeSingleEvent(of: .value, with: { (snapshot) in
        guard var userDictionary = snapshot.value as? [String: AnyObject] else {group.leave(); return }
        userDictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
        let user = User(dictionary: userDictionary)
        newMembersArray.append(user)
        group.leave()
      })
    }
  }
  */
  
  @objc fileprivate func openUserProfilePicture() {
    userProfilePictureOpener.controllerWithUserProfilePhoto = self
    userProfilePictureOpener.userProfileContainerView = groupProfileTableHeaderContainer
    userProfilePictureOpener.photoURL = groupAvatarURL
    userProfilePictureOpener.members = members
    userProfilePictureOpener.chatID = chatID
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
    return 1
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return "\(members.count) members"
  }

  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 20
  }
  
  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
    if let headerTitle = view as? UITableViewHeaderFooterView {
      headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 14)
    }
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return members.count
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: membersCellID, for: indexPath) as! FalconUsersTableViewCell
    
    if  members[indexPath.row].id == conversationAdminID {
      let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
      label.text = "admin"
      label.font = UIFont.systemFont(ofSize: 12)
      label.textColor = ThemeManager.currentTheme().generalSubtitleColor
      cell.accessoryType = UITableViewCellAccessoryType.none
      cell.accessoryView = label
      cell.accessoryView?.backgroundColor = UIColor.clear
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
