//
//  GroupAdminControlsPictureAvatarOpenerDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/19/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension GroupAdminPanelTableViewController: AvatarOpenerDelegate {
  func avatarOpener(avatarPickerDidPick image: UIImage) {
		navigationController?.view.isUserInteractionEnabled = false
    groupProfileTableHeaderContainer.profileImageView.showActivityIndicator()
    deleteCurrentPhoto { [weak self] (_) in
      self?.updateUserProfile(with: image, completion: { [weak self] (isUpdated) in
        self?.groupProfileTableHeaderContainer.profileImageView.hideActivityIndicator()
        self?.navigationController?.view.isUserInteractionEnabled = true
        guard isUpdated else {
          basicErrorAlertWith(title: basicErrorTitleForAlert, message: thumbnailUploadError, controller: self)
          return
        }
        self?.groupProfileTableHeaderContainer.profileImageView.image = image
      })
    }
  }
  
  func avatarOpener(didPerformDeletionAction: Bool) {
		navigationController?.view.isUserInteractionEnabled = false
    groupProfileTableHeaderContainer.profileImageView.showActivityIndicator()
    deleteCurrentPhoto { [weak self] (isDeleted) in
     	self?.navigationController?.view.isUserInteractionEnabled = true
      self?.groupProfileTableHeaderContainer.profileImageView.hideActivityIndicator()
      guard isDeleted else {
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self)
        return
      }
      self?.groupProfileTableHeaderContainer.profileImageView.image = nil
    }
  }
}

extension GroupAdminPanelTableViewController { // delete
  
  typealias CurrentPictureDeletionCompletionHandler = (_ success: Bool) -> Void
  func deleteCurrentPhoto(completion: @escaping CurrentPictureDeletionCompletionHandler) {
    guard let groupAvatarURL = groupAvatarURL, groupAvatarURL != "" else { completion(true); return }
    let storage = Storage.storage()
    let storageReference = storage.reference(forURL: groupAvatarURL)
    let groupChatsMetaReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    
    storageReference.delete { _ in
      let chatOriginalPhotoURLReference = groupChatsMetaReference.child("chatOriginalPhotoURL")
      let chatThumbnailPhotoURLReference = groupChatsMetaReference.child("chatThumbnailPhotoURL")
      chatOriginalPhotoURLReference.setValue("")
      chatThumbnailPhotoURLReference.setValue("")
      completion(true)
    }
  }
}

extension GroupAdminPanelTableViewController { // update
  
  typealias UpdateUserProfileCompletionHandler = (_ success: Bool) -> Void
  func updateUserProfile(with image: UIImage, completion: @escaping UpdateUserProfileCompletionHandler) {
    let userReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    let thumbnailImage = createImageThumbnail(image)
    var images = [(image: UIImage, quality: CGFloat, key: String)]()
    images.append((image: image, quality: 0.5, key: "chatOriginalPhotoURL"))
    images.append((image: thumbnailImage, quality: 1, key: "chatThumbnailPhotoURL"))
    
    let photoUpdatingGroup = DispatchGroup()
    for _ in images { photoUpdatingGroup.enter() }
    
    photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
      completion(true)
    })
    
    for imageElement in images {
      uploadAvatarForUserToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
        userReference.updateChildValues([imageElement.key: url], withCompletionBlock: { (_, _) in
          photoUpdatingGroup.leave()
        })
      }
    }
  }
}
