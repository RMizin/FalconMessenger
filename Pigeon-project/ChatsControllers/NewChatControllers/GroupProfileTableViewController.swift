//
//  GroupProfileTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase


enum ImageType:String {
  case thumbnail = "chatThumbnailPhotoURL"
  case original = "chatOriginalPhotoURL"
}


class GroupProfileTableViewController: UITableViewController {
  
  fileprivate var selectedFlaconUsersCellID = "selectedFlaconUsersCellID"
  
  var selectedFlaconUsers = [User]()
  
  let groupProfileTableHeaderContainer = GroupProfileTableHeaderContainer()
  
  let userProfilePictureOpener = GroupPictureOpener()

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
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createGroupChat))
    navigationItem.rightBarButtonItem?.isEnabled = false
  }
  
  fileprivate func setupTableView() {
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.sectionIndexBackgroundColor = view.backgroundColor
    tableView.backgroundColor = view.backgroundColor
    tableView.register(FalconUsersTableViewCell.self, forCellReuseIdentifier: selectedFlaconUsersCellID)
    tableView.separatorStyle = .none
    tableView.allowsSelection = false
    tableView.prefetchDataSource = self
  }
  
  fileprivate func configureContainerView() {
    groupProfileTableHeaderContainer.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openUserProfilePicture)))
    groupProfileTableHeaderContainer.name.delegate = self
    groupProfileTableHeaderContainer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 170)
    tableView.tableHeaderView = groupProfileTableHeaderContainer
    groupProfileTableHeaderContainer.name.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    
  }
  
  fileprivate func configureColorsAccordingToTheme() {
    groupProfileTableHeaderContainer.profileImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.userData.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    groupProfileTableHeaderContainer.name.textColor = ThemeManager.currentTheme().generalTitleColor
    groupProfileTableHeaderContainer.name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
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
      return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return selectedFlaconUsers.count
    }
  
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 60
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: selectedFlaconUsersCellID, for: indexPath) as! FalconUsersTableViewCell

      if let name = selectedFlaconUsers[indexPath.row].name {
        cell.title.text = name
      }
      
      if let statusString = selectedFlaconUsers[indexPath.row].onlineStatus as? String {
        if statusString == statusOnline {
          cell.subtitle.textColor = FalconPalette.defaultBlue
          cell.subtitle.text = statusString
        } else {
          cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
          let date = Date(timeIntervalSince1970: TimeInterval(statusString)!)
          let subtitle = "Last seen " + timeAgoSinceDate(date)
          cell.subtitle.text = subtitle
        }
        
      } else if let statusTimeinterval = selectedFlaconUsers[indexPath.row].onlineStatus as? TimeInterval {
        cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
        let date = Date(timeIntervalSince1970: statusTimeinterval/1000)
        let subtitle = "Last seen " + timeAgoSinceDate(date)
        cell.subtitle.text = subtitle
      }
      
      guard let url = selectedFlaconUsers[indexPath.row].thumbnailPhotoURL else { return cell }
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

extension GroupProfileTableViewController: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let urls = selectedFlaconUsers.map { URL(string: $0.photoURL ?? "")  }
    SDWebImagePrefetcher.shared().prefetchURLs(urls as? [URL])
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
    
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
      return
    }
    
    ARSLineProgress.show()
    view.isUserInteractionEnabled = false
    
    //to group chats meta
    //+ chatID
    //+chat thumbnail
    let chatName = groupProfileTableHeaderContainer.name.text ?? "Group Chat"
    let chatImage = groupProfileTableHeaderContainer.profileImageView.image
    var chatParticipantsIDs = [String]()
    let chatCreatingGroup = DispatchGroup()
    
    //for everybody
    let badge = 0
    let muted = false
    let pinned = false
    let isGroupChat = true
   
    
    chatParticipantsIDs.append(Auth.auth().currentUser!.uid)
    for selectedUser in selectedFlaconUsers {
      if let id = selectedUser.id {
        chatParticipantsIDs.append(id)
      }
    }
    
    let chatID = Database.database().reference().child("user-messages").child(Auth.auth().currentUser!.uid).childByAutoId().key
    
    for _ in chatParticipantsIDs {
      chatCreatingGroup.enter()
    }
    
    chatCreatingGroup.notify(queue: DispatchQueue.main, execute: {
      self.view.isUserInteractionEnabled = true
      print("group finished Notifiying...")
      ARSLineProgress.showSuccess()
      self.navigationController?.backToViewController(viewController: ChatsTableViewController.self)
    })
    
    for participantID in chatParticipantsIDs {
      
      let reference = Database.database().reference().child("user-messages").child(participantID).child(chatID).child(messageMetaDataFirebaseFolder)
      if let unwrappedChatImage = chatImage {
        
        let chatThumbnailImage = createImageThumbnail(unwrappedChatImage)
        let imagesToUpload = [chatThumbnailImage, unwrappedChatImage]
        let imagesUploadGroup = DispatchGroup()
        
        for _ in imagesToUpload {
          imagesUploadGroup.enter()
        }
        
        imagesUploadGroup.notify(queue: DispatchQueue.main, execute: {
          print("images uploading finished for one of the participants, leaving main group...")
          chatCreatingGroup.leave()
        })
        
        
        for image in imagesToUpload {
          
          var quality:CGFloat = 1.0
          var imageType:ImageType = .thumbnail
          
          if image == chatImage {
            quality = 0.5
            imageType = .original
          }
          
          uploadAvatarForUserToFirebaseStorageUsingImage(image, quality: quality) { (imageURL, path) in
            reference.updateChildValues([imageType.rawValue : String(describing: imageURL)], withCompletionBlock: { (error, ref) in
              guard error == nil else {
                imagesUploadGroup.leave()
                print("leaving imagesUploadGroup in error")
                print(error?.localizedDescription ?? "")
                return
              }
              
              imagesUploadGroup.leave()
              print("leaving imagesUploadGroup in success")
            })// reference
          }// avatar upload
        } // for loop
      }// if let
      
      
      let childValues: [String: Any] = ["chatID": chatID, "chatName": chatName, /*"lastMessageID": "",*/ "badge": badge, "muted": muted, "pinned": pinned, "isGroupChat": isGroupChat, "chatParticipantsIDs": chatParticipantsIDs, "admin": Auth.auth().currentUser!.uid]
      
      reference.updateChildValues(childValues) { (error, reference) in
        if error != nil {
          chatCreatingGroup.leave()
          print(error?.localizedDescription ?? "")
          return
        }
        
        guard chatImage == nil else { return }
        chatCreatingGroup.leave()
        print("leaving group in data upload")
      }
    } // for loop
  } //func
} // extension
