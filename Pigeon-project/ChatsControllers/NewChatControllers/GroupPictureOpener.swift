//
//  GroupPictureOpener.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Photos
import Firebase


class GroupPictureOpener: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
  weak var controllerWithUserProfilePhoto: UIViewController?
  weak var userProfileContainerView: GroupProfileTableHeaderContainer?
  
  
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
    overlay.navigationItem.title = "Group avatar"
    
    overlay.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(handleSelectProfileImageView))
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
        self.userProfileContainerView?.profileImageView.image = nil
        self.managePhotoPlaceholderLabelAppearance()
        self.overlay.photosViewController?.dismiss(animated: true, completion: nil)
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
       self.userProfileContainerView?.profileImageView.image = selectedImage //temporary
      self.managePhotoPlaceholderLabelAppearance() // temporary
      if currentReachabilityStatus == .notReachable {
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controllerWithUserProfilePhoto!)
        return
      }
    }
    
    controllerWithUserProfilePhoto?.dismiss(animated: true, completion: nil)
  }

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

