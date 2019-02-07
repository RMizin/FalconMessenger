//
//  GroupProfileTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import ARSLineProgress
import Firebase

private let selectedFlaconUsersCellID = "selectedFlaconUsersCellID"

class GroupProfileTableViewController: UITableViewController {
  
  var selectedFlaconUsers = [User]()
  let groupProfileTableHeaderContainer = GroupProfileTableHeaderContainer()
  let avatarOpener = AvatarOpener()
  let chatCreatingGroup = DispatchGroup()
  let informationMessageSender = InformationMessageSender()

  override func viewDidLoad() {
    super.viewDidLoad()
      
    setupMainView()
    setupTableView()
    configureContainerView()
    configureColorsAccordingToTheme()
  }
  
  fileprivate func setupMainView() {
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .always
      navigationController?.navigationBar.prefersLargeTitles = true
    }
    navigationItem.title = "New Group"
    extendedLayoutIncludesOpaqueBars = true
    definesPresentationContext = true
    edgesForExtendedLayout = [UIRectEdge.top, UIRectEdge.bottom]
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self,
                                                        action: #selector(createGroupChat))
    navigationItem.rightBarButtonItem?.isEnabled = false
  }
  
  fileprivate func setupTableView() {
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: selectedFlaconUsersCellID)
    tableView.separatorStyle = .none
    tableView.allowsSelection = false
  }
  
  fileprivate func configureContainerView() {
    let tapGesture = UITapGestureRecognizer(target: self,
                                            action: #selector(openUserProfilePicture))
    groupProfileTableHeaderContainer.profileImageView.addGestureRecognizer(tapGesture)
    groupProfileTableHeaderContainer.name.delegate = self
    groupProfileTableHeaderContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 170)
    tableView.tableHeaderView = groupProfileTableHeaderContainer
    groupProfileTableHeaderContainer.name.addTarget(self,
                                                    action: #selector(textFieldDidChange(_:)),
                                                    for: .editingChanged)
  }
  
  fileprivate func configureColorsAccordingToTheme() {
    groupProfileTableHeaderContainer.profileImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.userData.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.name.textColor = ThemeManager.currentTheme().generalTitleColor
    groupProfileTableHeaderContainer.name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
  }
  
  @objc fileprivate func openUserProfilePicture() {
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
      return
    }
    avatarOpener.delegate = self 
    avatarOpener.handleAvatarOpening(avatarView: groupProfileTableHeaderContainer.profileImageView,
																		 at: self,
																		 isEditButtonEnabled: true,
																		 title: .group,
																		 urlString: nil,
																		 thumbnailURLString: nil)
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    if textField.text?.count == 0 {
      navigationItem.rightBarButtonItem?.isEnabled = false
    } else {
      navigationItem.rightBarButtonItem?.isEnabled = true
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return selectedFlaconUsers.count
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: selectedFlaconUsersCellID,
                                             for: indexPath) as? FalconUsersTableViewCell ?? FalconUsersTableViewCell()
    let user = selectedFlaconUsers[indexPath.row]
    cell.configureCell(for: user)
    return cell
  }
}

extension GroupProfileTableViewController: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

extension GroupProfileTableViewController {

  @objc func createGroupChat() {
    
    guard currentReachabilityStatus != .notReachable,
      let chatName = groupProfileTableHeaderContainer.name.text,
      let currentUserID = Auth.auth().currentUser?.uid else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
      return
    }
    
    let membersIDs = fetchMembersIDs()
    let chatImage = groupProfileTableHeaderContainer.profileImageView.image
		guard let chatID = Database.database().reference().child("user-messages").child(currentUserID).childByAutoId().key else { return }
    let groupChatsReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    let childValues = ["chatID": chatID as AnyObject,
                       "chatName": chatName as AnyObject,
                       "chatParticipantsIDs": membersIDs.1 as AnyObject,
                       "admin": currentUserID as AnyObject,
                       "isGroupChat": true as AnyObject]
  
    chatCreatingGroup.enter()
    chatCreatingGroup.enter()
    createGroupNode(reference: groupChatsReference, childValues: childValues, noImagesToUpload: chatImage == nil)
    uploadAvatar(chatImage: chatImage, reference: groupChatsReference)
    
    chatCreatingGroup.notify(queue: DispatchQueue.main, execute: {
      self.hideActivityIndicator()
      print("Chat creating finished...")
      self.informationMessageSender.sendInformatoinMessage(chatID: chatID,
                                                           membersIDs: membersIDs.0,
                                                           text: "New group has been created")
      self.navigationController?.backToViewController(viewController: ChatsTableViewController.self)
    })
  }
  
  func fetchMembersIDs() -> ([String], [String: AnyObject]) {
    var membersIDs = [String]()
    var membersIDsDictionary = [String: AnyObject]()
    
    guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
    
    membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
    membersIDs.append(currentUserID)
    
    for selectedUser in selectedFlaconUsers {
      guard let id = selectedUser.id else { continue }
      membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
      membersIDs.append(id)
    }
  
    return (membersIDs, membersIDsDictionary)
  }
  
  func showActivityIndicator() {
    ARSLineProgress.show()
    self.navigationController?.view.isUserInteractionEnabled = false
  }
  
  func hideActivityIndicator() {
    self.navigationController?.view.isUserInteractionEnabled = true
    ARSLineProgress.showSuccess()
  }

  func uploadAvatar(chatImage: UIImage?, reference: DatabaseReference) {

    guard let image = chatImage else {
      reference.updateChildValues(["chatOriginalPhotoURL": "", "chatThumbnailPhotoURL": ""]) { (_, _) in
        self.chatCreatingGroup.leave()
      }
      return
    }

    let thumbnailImage = createImageThumbnail(image)
    var images = [(image: UIImage, quality: CGFloat, key: String)]()
    images.append((image: image, quality: 0.5, key: "chatOriginalPhotoURL"))
    images.append((image: thumbnailImage, quality: 1, key: "chatThumbnailPhotoURL"))
    let photoUpdatingGroup = DispatchGroup()
    for _ in images { photoUpdatingGroup.enter() }

    photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
      self.chatCreatingGroup.leave()
    })
    
    for imageElement in images {
      uploadAvatarForUserToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
        reference.updateChildValues([imageElement.key: url], withCompletionBlock: { (_, _) in
          photoUpdatingGroup.leave()
        })
      }
    }
  }

  func createGroupNode(reference: DatabaseReference, childValues: [String: Any], noImagesToUpload: Bool) {
    showActivityIndicator()
    let nodeCreationGroup = DispatchGroup()
    nodeCreationGroup.enter()
    nodeCreationGroup.notify(queue: DispatchQueue.main, execute: {
      self.chatCreatingGroup.leave()
    })
    reference.updateChildValues(childValues) { (_, _) in
      nodeCreationGroup.leave()
    }
  }
}
