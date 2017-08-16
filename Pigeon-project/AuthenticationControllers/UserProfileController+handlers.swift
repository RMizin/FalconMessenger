//
//  CreateProfileController+handlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import Firebase
import Photos

extension UserProfileController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    // Image picker in edit mode
    if let imageVC = NSClassFromString("PUUIImageViewController") {
      if viewController.isKind(of: imageVC) {
        addRoundedEditLayer(to: viewController, forCamera: false)
      }
    }
  }
  
  
  func configureImageViewBackgroundView() {
    blackBackgroundView.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit  ", style: .done, target: self, action: #selector(UserProfileController.handleSelectProfileImageView))
    blackBackgroundView.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "BackButton" ), style: .done, target: self, action: #selector(UserProfileController.handleZoomOut))
    blackBackgroundView.navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 15)
     blackBackgroundView.navigationBar.setItems([blackBackgroundView.navigationItem], animated: true)
  }
  
  func handlerImageViewSelection() {
    if userProfileContainerView.profileImageView.image != nil {
      performZoomInForStartingImageView(userProfileContainerView.profileImageView)
    } else {
      handleSelectProfileImageView()
    }
  }
  
  
  func performZoomInForStartingImageView(_ initialImageView: UIImageView) {
   
    self.startingImageView = initialImageView
    
    self.startingImageView?.isHidden = true
    
    self.startingFrame = initialImageView.superview?.convert(initialImageView.frame, to: nil)
    
    let zoomingImageView = UIImageView(frame: self.startingFrame!)
    
    zoomingImageView.image = startingImageView?.image
    
    zoomingImageView.isUserInteractionEnabled = true
    
    zoomingImageView.addGestureRecognizer(zoomOutGesture)
    
    
    if let keyWindow = UIApplication.shared.keyWindow {
      self.blackBackgroundView = ImageViewBackgroundView(frame: keyWindow.frame)
      self.blackBackgroundView.alpha = 0
      
      keyWindow.addSubview(self.blackBackgroundView)
      keyWindow.addSubview(zoomingImageView)
      configureImageViewBackgroundView()
      configureToolbar()
      
      let scaledImage = imageWithImage(sourceImage: zoomingImageView.image!, scaledToWidth: deviceScreen.width)
      let centerY = blackBackgroundView.center.y - (scaledImage.size.height/2)
      
      UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
        
        self.blackBackgroundView.alpha = 1
      
        zoomingImageView.frame = CGRect(x: 0, y: centerY , width: scaledImage.size.width, height: scaledImage.size.height)
        
      }, completion: { (completed) in
        // do nothing
      })
    }
  }
  
  func handleZoomOut() {
    if let zoomOutImageView = zoomOutGesture.view {
      //need to animate back out to controller
      zoomOutImageView.layer.masksToBounds = true
      
      UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
        
        zoomOutImageView.frame = self.startingFrame!
        
        self.blackBackgroundView.alpha = 0
        
        zoomOutImageView.layer.cornerRadius = 48
        zoomOutImageView.contentMode = .scaleAspectFill
        zoomOutImageView.layer.borderColor = UIColor.lightGray.cgColor
        zoomOutImageView.layer.borderWidth = 1
        
      }, completion: { (completed) in
        
        zoomOutImageView.removeFromSuperview()
        
        self.startingImageView?.isHidden = false
      })
    }
  }
  
  
  func configureToolbar() {
    let item1 = UIBarButtonItem(image: UIImage(named: "ShareExternalIcon"), style: .plain, target: self, action: #selector(self.toolbarTouchHandler))
    
    item1.imageInsets = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 15)
    blackBackgroundView.toolbar.setItems([item1], animated: true)
  }

  
  func failedToSaveImageToGallery() {
    
    let alertWindow = UIWindow(frame: UIScreen.main.bounds)
    alertWindow.rootViewController = UIViewController()
    alertWindow.windowLevel = UIWindowLevelAlert + 1;
    alertWindow.makeKeyAndVisible()
    
    let alert = UIAlertController(title: "Error",
                                  message: "This app does not have access to your photos or videos. You can enable access in Privacy Settings.",
                                  preferredStyle: UIAlertControllerStyle.alert)
    
    alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.default) { UIAlertAction in
      
      alertWindow.rootViewController?.dismiss(animated: true, completion: nil)
    })
    
    self.view.isUserInteractionEnabled = true
      alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
    
  }
  
  func toolbarTouchHandler() {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Save image", style: .default, handler: { _ in
     
      if let image = self.userProfileContainerView.profileImageView.image {
        
        // Get the current authorization state.
        let status = PHPhotoLibrary.authorizationStatus()
        
        if (status == PHAuthorizationStatus.authorized) {
          // Access has been granted.
          UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
          
          ARSLineProgress.showSuccess()
        }
          
        else if (status == PHAuthorizationStatus.denied) {
          // Access has been denied.
          ARSLineProgress.showFail()
          self.failedToSaveImageToGallery()
        }
          
        else if (status == PHAuthorizationStatus.notDetermined) {
          
          // Access has not been determined.
          PHPhotoLibrary.requestAuthorization({ (newStatus) in
            
            if (newStatus == PHAuthorizationStatus.authorized) {
              UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
              
              ARSLineProgress.showSuccess()
            } else {
              self.failedToSaveImageToGallery()
            }
          })
        }
          
        else if (status == PHAuthorizationStatus.restricted) {
          // Restricted access - normally won't happen.
          self.failedToSaveImageToGallery()
        }

      }
      
    }))
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
      
    }))
    
    let alertWindow = UIWindow(frame: UIScreen.main.bounds)
    alertWindow.rootViewController = UIViewController()
    alertWindow.windowLevel = UIWindowLevelAlert + 1;
    alertWindow.makeKeyAndVisible()
    alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
    
    
  }
  
  func handleSelectProfileImageView() {
    
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { _ in
      self.handleZoomOut()
      self.openCamera()
    }))
    
    alert.addAction(UIAlertAction(title: "Choose photo", style: .default, handler: { _ in
      self.handleZoomOut()
      self.openGallery()
    }))
    
   if userProfileContainerView.profileImageView.image != nil {
      alert.addAction(UIAlertAction(title: "Delete photo", style: .destructive, handler: { _ in
        self.handleZoomOut()
        self.deletePhoto()
      }))

    }
    
    
    alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
    let alertWindow = UIWindow(frame: UIScreen.main.bounds)
    alertWindow.rootViewController = UIViewController()
    alertWindow.windowLevel = UIWindowLevelAlert + 1;
    alertWindow.makeKeyAndVisible()
    alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
  }
  
  
  func deletePhoto() {
    
    userProfileContainerView.profileImageView.showActivityIndicator()
   
    
    let userPhotoURL = UserDefaults.standard.string(forKey: "userPhotoURL")
    
    let imageRef = Storage.storage().reference(forURL: userPhotoURL!)
    
    imageRef.delete { (error) in
      if error != nil {
        print("error removig image from firebse storage")
      }
      
      print("removing completed begining removing URLS")
      
      
      let userReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
      userReference.updateChildValues(["photoURL" : ""], withCompletionBlock: { (error, referene) in
        if error != nil {
          print("error deleting url from firebase")
        }
        
        self.userProfileContainerView.profileImageView.image = nil
        UserDefaults.standard.set("", forKey: "userPhotoURL")
        self.userProfileContainerView.profileImageView.hideActivityIndicator()
      })
    }
  }
  
  
  func openGallery() {
    picker.allowsEditing = true
  
    picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    present(picker, animated: true, completion: nil)
  }
  
  
  func openCamera() {
    if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
      picker.sourceType = UIImagePickerControllerSourceType.camera
      picker.allowsEditing = true
      
      self.present(picker, animated: true, completion: nil)
      
    } else {
      
      let alert = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      self.present(alert, animated: true, completion: nil)
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
          self.userProfileContainerView.profileImageView.image = selectedImage
          updateUserProfile(with:  self.userProfileContainerView.profileImageView.image!)
    }
    
    editLayer.removeFromSuperlayer()
    label.removeFromSuperview()
    dismiss(animated: true, completion: nil)
    userProfileContainerView.profileImageView.showActivityIndicator()
  }
  

  func updateUserProfile(with image: UIImage) {
    let compressedImage = compressImage(image)
    
    uploadAvatarForUserToFirebaseStorageUsingImage(compressedImage) { (thumbnailImageURL) in
      
      let reference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
      reference.updateChildValues(["thumbnailPhotoURL" : String(describing: thumbnailImageURL)], withCompletionBlock: { (error, ref) in
        
        UserDefaults.standard.set(String(describing: thumbnailImageURL), forKey: "thumbnailUserPhotoURL")
      })
    }
    
    uploadAvatarForUserToFirebaseStorageUsingImage(image, completion: { (imageURL) in
      
      self.userProfileContainerView.profileImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: image, options: [.highPriority, .continueInBackground, .progressiveDownload], completed: { (image, error, cacheType, url) in
          
        let reference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
        reference.updateChildValues(["photoURL" : String(describing: url!)], withCompletionBlock: { (error, ref) in
          
           UserDefaults.standard.set(String(describing: url!), forKey: "userPhotoURL")
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
