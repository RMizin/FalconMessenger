//
//  GroupAdminControlsPictureOpener.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/19/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Photos
import Firebase



private let deletionErrorMessage = "There was a problem when deleting. Try again later."
private let cameraNotExistsMessage = "You don't have camera"
private let thumbnailUploadError = "Failed to upload your image to database. Please, check your internet connection and try again."
private let fullsizePictureUploadError = "Failed to upload fullsize image to database. Please, check your internet connection and try again. Despite this error, thumbnail version of this picture has been uploaded, but you still should re-upload your fullsize image."


class GroupAdminControlsPictureOpener: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  

  weak var controllerWithUserProfilePhoto: GroupAdminControlsTableViewController?
  weak var userProfileContainerView: GroupProfileTableHeaderContainer?
  var members = [User]()
  var chatID = String()
  var isAdminToolsEnabled = false
  
  
  private var referenceView: UIView!
  private var currentPhoto: INSPhoto!
  private var galleryPreview: INSPhotosViewController!
  private let overlay = UserProfilePictureOverlayView(frame: CGRect.zero)
  private let picker = UIImagePickerController()
  
  
  @objc func openUserProfilePicture() {
    picker.delegate = self
    if userProfileContainerView?.profileImageView.image == nil {
      handleSelectProfileImageView()
      
      return
    }
    
    referenceView = userProfileContainerView?.profileImageView
    currentPhoto = INSPhoto(image: userProfileContainerView?.profileImageView.image, thumbnailImage: nil, messageUID: nil)
    galleryPreview = INSPhotosViewController(photos: [currentPhoto], initialPhoto: currentPhoto, referenceView: referenceView)
    
    overlay.photosViewController = galleryPreview
    galleryPreview.overlayView = overlay
    if isAdminToolsEnabled {
      overlay.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(handleSelectProfileImageView))
    }
   
    overlay.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "BackButton" ), style: .done, target: self, action: #selector(backButtonTapped))
    overlay.navigationBar.setItems([overlay.navigationItem], animated: true)
    overlay.navigationBar.barStyle = .blackTranslucent
    overlay.navigationBar.barTintColor = .black
    
    let item = UIBarButtonItem(image: UIImage(named: "ShareExternalIcon"), style: .plain, target: self, action: #selector(self.toolbarTouchHandler))
    overlay.toolbar.setItems([item], animated: true)
    
    galleryPreview.referenceViewForPhotoWhenDismissingHandler = { photo in
      return self.referenceView
    }
    
    galleryPreview.modalPresentationStyle = .overFullScreen
    galleryPreview.modalPresentationCapturesStatusBarAppearance = true
    
    controllerWithUserProfilePhoto?.present(galleryPreview, animated: true, completion: nil)
  }
  
  
  @objc func backButtonTapped() {
    overlay.photosViewController?.dismiss(animated: true, completion: nil)
  }
  
  
  @objc func toolbarTouchHandler() {
    
    let activity = UIActivityViewController(activityItems: [userProfileContainerView?.profileImageView.image as Any], applicationActivities: nil)
    galleryPreview.present(activity, animated: true, completion: nil)
  }
  
  @objc func handleSelectProfileImageView() {
    
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { _ in
      
      self.overlay.photosViewController?.dismiss(animated: true, completion: nil)
      self.openCamera()
    }))
    
    alert.addAction(UIAlertAction(title: "Choose photo", style: .default, handler: { _ in
      
      self.overlay.photosViewController?.dismiss(animated: true, completion: nil)
      self.openGallery()
      
    }))
    
    if userProfileContainerView?.profileImageView.image != nil {
      alert.addAction(UIAlertAction(title: "Delete photo", style: .destructive, handler: { _ in
        self.overlay.photosViewController?.dismiss(animated: true, completion: {
          self.deleteCurrentPhoto(completion: { (isDeleted) in
            if isDeleted {
              if self.userProfileContainerView?.profileImageView.image != nil {
                self.userProfileContainerView?.profileImageView.image = nil
              }
              self.managePhotoPlaceholderLabelAppearance()
              self.userProfileContainerView?.profileImageView.hideActivityIndicator()
              print("deleted")
              
            } else {
              
              self.userProfileContainerView?.profileImageView.hideActivityIndicator()
              basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self.controllerWithUserProfilePhoto!)
              // print("in error", userProfileContainerView?.profileImageView)
            }
          })
        })
      }))
    }
    
    alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
    
    if userProfileContainerView?.profileImageView.image == nil {
      controllerWithUserProfilePhoto?.present(alert, animated: true, completion: nil)
    } else {
      galleryPreview.navigationController?.navigationBar.barStyle = .blackTranslucent
      galleryPreview.present(alert, animated: true, completion: nil)
    }
  }
  
  
  fileprivate typealias currentPictureDeletionCompletionHandler = (_ success: Bool) -> Void
  
  fileprivate func deleteCurrentPhoto(completion: @escaping currentPictureDeletionCompletionHandler) {
    
    if currentReachabilityStatus == .notReachable {
      userProfileContainerView?.profileImageView.hideActivityIndicator()
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controllerWithUserProfilePhoto!)
      return
    }
    
    guard (Auth.auth().currentUser?.uid) != nil else {
      completion(false)
      return
    }
    
    userProfileContainerView?.profileImageView.showActivityIndicator()
    
    if controllerWithUserProfilePhoto!.groupAvatarURL == "" {
      completion(true)
      return
    }
    let storage = Storage.storage()
    
    let storageRef = storage.reference(forURL: controllerWithUserProfilePhoto!.groupAvatarURL)
    
    //Removes image from storage
    storageRef.delete { error in
      if let error = error {
        print(error, "!!!!")
           completion(false)
        self.userProfileContainerView?.profileImageView.hideActivityIndicator()
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self.controllerWithUserProfilePhoto!)
      } else {
        
        for member in self.members {
          guard let memberID = member.id else { continue }
          let chatOriginalPhotoURLReference = Database.database().reference().child("user-messages").child(memberID).child(self.chatID).child(messageMetaDataFirebaseFolder).child("chatOriginalPhotoURL")
          let chatThumbnailPhotoURLReference = Database.database().reference().child("user-messages").child(memberID).child(self.chatID).child(messageMetaDataFirebaseFolder).child("chatThumbnailPhotoURL")
          chatOriginalPhotoURLReference.removeValue()
          chatThumbnailPhotoURLReference.removeValue()
          print("removing for member: \(memberID)")
        }
        completion(true)
        print("file deleted")
        // File deleted successfully
      }
    }
  }
  
  func openGallery() {
    
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controllerWithUserProfilePhoto!)
      return
    }
    
    let status = PHPhotoLibrary.authorizationStatus()
    
    switch status {
    case .authorized:
      presentGallery()
      break
      
    case .denied, .restricted:
      basicErrorAlertWith(title: basicTitleForAccessError, message: photoLibraryAccessDeniedMessageProfilePicture, controller: controllerWithUserProfilePhoto!)
      return
      
    case .notDetermined:
      
      PHPhotoLibrary.requestAuthorization() { status in
        switch status {
        case .authorized:
          self.presentGallery()
          break
          
        case .denied, .restricted, .notDetermined:
          basicErrorAlertWith(title: basicTitleForAccessError, message: photoLibraryAccessDeniedMessageProfilePicture, controller: self.controllerWithUserProfilePhoto!)
          return
        }
      }
    }
  }
  
  func presentGallery() {
    picker.allowsEditing = true
    picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    controllerWithUserProfilePhoto?.present(picker, animated: true, completion: nil)
  }
  
  
  func openCamera() {
    
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controllerWithUserProfilePhoto!)
      return
    }
    
    let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    
    switch authorizationStatus {
    case .authorized:
      presentCamera()
      break
      
    case .denied, .restricted:
      basicErrorAlertWith(title: basicTitleForAccessError, message: cameraAccessDeniedMessageProfilePicture, controller: controllerWithUserProfilePhoto!)
      return
      
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
        
        switch granted {
        case true:
          self.presentCamera()
          break
          
        case false:
          basicErrorAlertWith(title: basicTitleForAccessError, message: cameraAccessDeniedMessageProfilePicture, controller: self.controllerWithUserProfilePhoto!)
          return
        }
      }
    }
  }
  
  
  func presentCamera() {
    if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
      picker.sourceType = UIImagePickerControllerSourceType.camera
      picker.allowsEditing = true
      controllerWithUserProfilePhoto?.present(picker, animated: true, completion: nil)
      
    } else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: cameraNotExistsMessage, controller: controllerWithUserProfilePhoto!)
    }
  }
  
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
    var selectedImageFromPicker: UIImage?
    if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
      selectedImageFromPicker = editedImage
      
    } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
      selectedImageFromPicker = originalImage
    }
    
    if let selectedImage = selectedImageFromPicker {
      
      if currentReachabilityStatus == .notReachable {
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controllerWithUserProfilePhoto!)
        return
      }
      
      guard self.userProfileContainerView?.profileImageView.image != nil else {
        self.userProfileContainerView?.profileImageView.image = selectedImage
        self.updateUserProfile(with: self.userProfileContainerView!.profileImageView.image!)
        self.userProfileContainerView?.profileImageView.showActivityIndicator()
        controllerWithUserProfilePhoto?.dismiss(animated: true, completion: nil)
        return
      }
      
      deleteCurrentPhoto(completion: { (isDeleted) in
        if isDeleted {
          self.userProfileContainerView?.profileImageView.image = selectedImage
          self.updateUserProfile(with: self.userProfileContainerView!.profileImageView.image!)   /////23/23//42/423/423/42/42/42/342
        } else {
          if self.userProfileContainerView?.profileImageView.image != nil {
            self.userProfileContainerView?.profileImageView.hideActivityIndicator()
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self.controllerWithUserProfilePhoto!)
          } else {
            self.userProfileContainerView?.profileImageView.image = selectedImage
            self.updateUserProfile(with: self.userProfileContainerView!.profileImageView.image!)
          }
          
        }
      })
    }
    
    self.userProfileContainerView?.profileImageView.showActivityIndicator()
    controllerWithUserProfilePhoto?.dismiss(animated: true, completion: nil)
  }
  
  
  @objc func updateUserProfile(with image: UIImage) {
    
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller:  self.controllerWithUserProfilePhoto!)
      return
    }

    let chatImage = image

    let chatCreatingGroup = DispatchGroup()
    

    
    for _ in members {
      chatCreatingGroup.enter()
    }
    
    chatCreatingGroup.notify(queue: DispatchQueue.main, execute: {
      print("group finished Notifiying...")
      self.userProfileContainerView?.profileImageView.hideActivityIndicator()
    })
    
    for member in members {
      guard let memberID = member.id else { continue }
      
      let reference = Database.database().reference().child("user-messages").child(memberID).child(chatID).child(messageMetaDataFirebaseFolder)
   
        
        let chatThumbnailImage = createImageThumbnail(chatImage)
        let imagesToUpload = [chatThumbnailImage, chatImage]
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
      } // for loop
  } //func
  
  fileprivate func managePhotoPlaceholderLabelAppearance() {
    DispatchQueue.main.async {
      if self.userProfileContainerView?.profileImageView.image != nil {
        self.userProfileContainerView?.addPhotoLabel.isHidden = true
      } else {
        self.userProfileContainerView?.addPhotoLabel.isHidden = false
      }
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    print("canceled picker")
    controllerWithUserProfilePhoto?.dismiss(animated: true, completion: nil)
  }
}
