//
//  CreateProfileController+handlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos
import AVFoundation


private let deletionErrorMessage = "There was a problem when deleting. Try again later."
private let cameraNotExistsMessage = "You don't have camera"
private let thumbnailUploadError = "Failed to upload your image to database. Please, check your internet connection and try again."
private let fullsizePictureUploadError = "Failed to upload fullsize image to database. Please, check your internet connection and try again. Despite this error, thumbnail version of this picture has been uploaded, but you still should re-upload your fullsize image."
private let noInternetError = "Internet connection is not available. Try again later"


extension UserProfileController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  fileprivate func basicErrorAlertWith (title: String, message: String) {
    
    self.userProfileContainerView.profileImageView.hideActivityIndicator()
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
 
 @objc func openUserProfilePicture() {
    settingsContainer?.cancelBarButtonPressed()
    if userProfileContainerView.profileImageView.image == nil {
      handleSelectProfileImageView()
      
      return
    }
   UIApplication.shared.statusBarStyle = .lightContent
    referenceView = userProfileContainerView.profileImageView
    currentPhoto = INSPhoto(image: userProfileContainerView.profileImageView.image, thumbnailImage: nil, messageUID: nil)
    galleryPreview = INSPhotosViewController(photos: [currentPhoto], initialPhoto: currentPhoto, referenceView: referenceView)

    overlay.photosViewController = galleryPreview
    galleryPreview.overlayView = overlay
 //   galleryPreview.modalPresentationCapturesStatusBarAppearance = false
 // galleryPreview.setNeedsStatusBarAppearanceUpdate()
//modalPresentationCapturesStatusBarAppearance
  
    overlay.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(UserProfileController.handleSelectProfileImageView))
    overlay.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "BackButton" ), style: .done, target: self, action: #selector(UserProfileController.backButtonTapped))
    overlay.navigationBar.setItems([overlay.navigationItem], animated: true)

    let item = UIBarButtonItem(image: UIImage(named: "ShareExternalIcon"), style: .plain, target: self, action: #selector(self.toolbarTouchHandler))
    overlay.toolbar.setItems([item], animated: true)
  
    galleryPreview.referenceViewForPhotoWhenDismissingHandler = { photo in
      return self.referenceView
    }

    present(galleryPreview, animated: true, completion: nil)
  }
  
  
  @objc func backButtonTapped() {
    overlay.photosViewController?.dismiss(animated: true, completion: nil)
  }
  

 @objc func toolbarTouchHandler() {
  
  let activity = UIActivityViewController(activityItems: [userProfileContainerView.profileImageView.image!], applicationActivities: nil)
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
    
   if userProfileContainerView.profileImageView.image != nil {
      alert.addAction(UIAlertAction(title: "Delete photo", style: .destructive, handler: { _ in
        self.overlay.photosViewController?.dismiss(animated: true, completion: {
          self.deleteCurrentPhoto(completion: { (isDeleted) in
            if isDeleted {
              self.userProfileContainerView.profileImageView.hideActivityIndicator()
              print("deleted")
            } else {
              
              self.userProfileContainerView.profileImageView.hideActivityIndicator()
              self.basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage)
            }
          })
        })
      }))
    }
    
   alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
    
    if userProfileContainerView.profileImageView.image == nil {
      present(alert, animated: true, completion: nil)
      } else {
       galleryPreview.present(alert, animated: true, completion: nil)
      }
  }
  
  
 fileprivate typealias currentPictureDeletionCompletionHandler = (_ success: Bool) -> Void
  
 fileprivate func deleteCurrentPhoto(completion: @escaping currentPictureDeletionCompletionHandler) {
  
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError)
      return
    }
  
    guard let currentUser = Auth.auth().currentUser?.uid else {
      completion(false)
      return
    }
  
    userProfileContainerView.profileImageView.showActivityIndicator()
      
    let userRef = Database.database().reference().child("users").child(currentUser)
    userRef.observeSingleEvent(of: .value, with: { (snapshot) in
      
      let userData = snapshot.value as? NSDictionary
        
      guard let userPhotoURLPath = userData?["photoURLPath"] as? String, let userThumbnailPhotoURLPath = userData?["thumbnailPhotoURLPath"] as? String else {
        completion(false)
        return
      }
      
      if userThumbnailPhotoURLPath != "" || userPhotoURLPath != "" {
            
        let imageRef = Storage.storage().reference().child("/userProfilePictures/\(userPhotoURLPath)")
        let thumbnailImageRef = Storage.storage().reference().child("/userProfilePictures/\(userThumbnailPhotoURLPath)")
          
        thumbnailImageRef.delete(completion: nil)
        imageRef.delete(completion: nil)
        
        let userReference = Database.database().reference().child("users").child(currentUser)
        userReference.updateChildValues(["photoURL" : "", "thumbnailPhotoURL" : "", "thumbnailPhotoURLPath" : "", "photoURLPath" : ""], withCompletionBlock: { (error, referene) in
                  
          if error != nil {
            print("error deleting url from firebase")
            completion(false)
            return
          }
          
          completion(true)
        })
      } else {
        completion(true)
      }
    }, withCancel: { (error) in
      self.basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError)
    })
  }
  
  
  func openGallery() {
    
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError)
      return
    }
    
    let status = PHPhotoLibrary.authorizationStatus()
    
    switch status {
      case .authorized:
        presentGallery()
        break

      case .denied, .restricted:
        basicErrorAlertWith(title: basicTitleForAccessError, message: photoLibraryAccessDeniedMessageProfilePicture)
        return

      case .notDetermined:

        PHPhotoLibrary.requestAuthorization() { status in
          switch status {
            case .authorized:
              self.presentGallery()
              break
            
            case .denied, .restricted, .notDetermined:
              self.basicErrorAlertWith(title: basicTitleForAccessError, message: photoLibraryAccessDeniedMessageProfilePicture)
              return
        }
      }
    }
  }
  
  func presentGallery() {
    picker.allowsEditing = true
    picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    present(picker, animated: true, completion: nil)
  }
  
  
  func openCamera() {
    
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError)
      return
    }
   
    let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    
    switch authorizationStatus {
      case .authorized:
        presentCamera()
        break
      
      case .denied, .restricted:
        self.basicErrorAlertWith(title: basicTitleForAccessError, message: cameraAccessDeniedMessageProfilePicture)
        return
      
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
          
          switch granted {
            case true:
              self.presentCamera()
              break
            
            case false:
              self.basicErrorAlertWith(title: basicTitleForAccessError, message: cameraAccessDeniedMessageProfilePicture)
              return
          }
        }
    }
  }
  
  
  func presentCamera() {
    if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
      picker.sourceType = UIImagePickerControllerSourceType.camera
      picker.allowsEditing = true
      self.present(picker, animated: true, completion: nil)
      
    } else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: cameraNotExistsMessage)
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
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError)
        return
      }
          deleteCurrentPhoto(completion: { (isDeleted) in
            if isDeleted {
              self.userProfileContainerView.profileImageView.image = selectedImage
              self.updateUserProfile(with:  self.userProfileContainerView.profileImageView.image!)
            } else {
              self.basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage)
            }
         })
    }
    
    userProfileContainerView.profileImageView.showActivityIndicator()
    dismiss(animated: true, completion: nil)
  }
  

  func updateUserProfile(with image: UIImage) {
    let thumbnailImage = createImageThumbnail(image)
   
    uploadAvatarForUserToFirebaseStorageUsingImage(thumbnailImage, quality: 1) { (thumbnailImageURL, path) in
      
      let reference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
      reference.updateChildValues(["thumbnailPhotoURL" : String(describing: thumbnailImageURL), "thumbnailPhotoURLPath" : path], withCompletionBlock: { (error, ref) in
        if error != nil {
          self.basicErrorAlertWith(title: basicErrorTitleForAlert, message: thumbnailUploadError)
          return
        }
      })
    }
    
    uploadAvatarForUserToFirebaseStorageUsingImage(image, quality: 0.5, completion: { (imageURL, path) in
      
      if imageURL == "" && path == "" {
       self.basicErrorAlertWith(title: basicErrorTitleForAlert, message: fullsizePictureUploadError)
        return
      }
      
      self.userProfileContainerView.profileImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: image, options: [.highPriority, .continueInBackground], completed: { (image, error, cacheType, url) in
        if error != nil  {
          self.basicErrorAlertWith(title: basicErrorTitleForAlert, message: fullsizePictureUploadError)
        
          return
        }
        
        let reference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
        reference.updateChildValues(["photoURL" : String(describing: imageURL), "photoURLPath" : path], withCompletionBlock: { (error, ref) in
          
          if error != nil {
            self.basicErrorAlertWith(title: basicErrorTitleForAlert, message: fullsizePictureUploadError)
          }
      
           self.userProfileContainerView.profileImageView.hideActivityIndicator()
        })
      })
    })
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    print("canceled picker")
    dismiss(animated: true, completion: nil)
  }
}
