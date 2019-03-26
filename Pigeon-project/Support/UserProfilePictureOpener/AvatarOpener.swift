//
//  UserProfilePictureOpener.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos
import AVFoundation
import CropViewController

protocol AvatarOpenerDelegate: class {
 func avatarOpener(avatarPickerDidPick image: UIImage)
 func avatarOpener(didPerformDeletionAction: Bool)
}

class AvatarOpener: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
  
  private var galleryPreview: INSPhotosViewController?
  private let overlay = AvatarOpenerOverlay()
  private var picker: UIImagePickerController!
  
  private weak var parentController: UIViewController?
  private weak var avatarImageView: UIImageView?
  
  weak var delegate: AvatarOpenerDelegate?
   
  func handleAvatarOpening(avatarView: UIImageView, at controller: UIViewController, isEditButtonEnabled: Bool, title: AvatarOverlayTitle) {
  
    parentController = controller
    avatarImageView = avatarView
    setupOverlay(isEditButonEnabled: isEditButtonEnabled, title: title)
   
    switch avatarView.image == nil {
    case true:
      openPhotoManager()
      break
    case false:
      openAvatar(avatarView: avatarView, at: controller)
      break
    }
  }

  private func openAvatar(avatarView: UIImageView, at controller: UIViewController) {
   
    let currentPhoto = INSPhoto(image: avatarView.image, thumbnailImage: nil, messageUID: nil)
    galleryPreview = INSPhotosViewController(photos: [currentPhoto], initialPhoto: currentPhoto, referenceView: avatarView)
    overlay.photosViewController = galleryPreview
    galleryPreview?.overlayView = overlay
    galleryPreview?.referenceViewForPhotoWhenDismissingHandler = { photo in return avatarView }
    galleryPreview?.modalPresentationStyle = .overFullScreen
    galleryPreview?.modalPresentationCapturesStatusBarAppearance = true
    
    guard let destination = galleryPreview else { return }
    controller.present(destination, animated: true, completion: nil)
  }
  
  func setupOverlay(isEditButonEnabled: Bool, title: AvatarOverlayTitle) {
    overlay.setOverlayTitle(title: title)
    overlay.navigationBar.barStyle = .blackTranslucent
    overlay.navigationBar.barTintColor = .black
    let item = UIBarButtonItem(image: UIImage(named: "ShareExternalIcon"), style: .plain, target: self, action: #selector(toolbarTouchHandler))
    overlay.toolbar.setItems([item], animated: true)
    
    guard isEditButonEnabled else { return }
    overlay.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(openPhotoManager))
  }
  
  @objc private func toolbarTouchHandler() {
    let activity = UIActivityViewController(activityItems: [avatarImageView?.image as Any], applicationActivities: nil) //possible error
    galleryPreview?.present(activity, animated: true, completion: nil)
  }
  
  @objc private func openPhotoManager() {
    print("\n presenting alert \n")
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    alert.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { _ in
      self.galleryPreview?.dismiss(animated: true, completion: nil)
      self.openCamera()
    }))
    
    alert.addAction(UIAlertAction(title: "Choose photo", style: .default, handler: { _ in
      self.galleryPreview?.dismiss(animated: true, completion: nil)
      self.openGallery()
    }))
    
    alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
    
    if avatarImageView?.image == nil {
      print("image nil")
      parentController?.present(alert, animated: true, completion: nil)
    } else {
         print("image not nil")
      alert.addAction(UIAlertAction(title: "Delete photo", style: .destructive, handler: { _ in
        self.dismissAndDelete()
      }))
      
      galleryPreview?.present(alert, animated: true, completion: nil)
    }
  }
  
  private func dismissAndDelete() {
    self.overlay.photosViewController?.dismiss(animated: true, completion: {
      self.delegate?.avatarOpener(didPerformDeletionAction: true)
    })
  }
  
  private func openGallery() {
    guard let controller = parentController else { return }
    
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controller)
      return
    }
    
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
      case .authorized:
        presentGallery()
        break
      case .denied, .restricted:
        basicErrorAlertWith(title: basicTitleForAccessError, message: photoLibraryAccessDeniedMessageProfilePicture, controller: controller)
        return
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization() { status in
          switch status {
            case .authorized:
              self.presentGallery()
              break
            case .denied, .restricted, .notDetermined:
              basicErrorAlertWith(title: basicTitleForAccessError, message: photoLibraryAccessDeniedMessageProfilePicture, controller: controller)
              break
							@unknown default:
								fatalError()
					}
        }
		@unknown default:
			fatalError()
		}
  }

 private func openCamera() {
    guard let controller = parentController else { return }
  
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controller)
      return
    }
   
    let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    
    switch authorizationStatus {
      case .authorized:
        presentCamera()
        break
      case .denied, .restricted:
        basicErrorAlertWith(title: basicTitleForAccessError, message: cameraAccessDeniedMessageProfilePicture, controller: controller)
        return
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
          switch granted {
            case true:
              self.presentCamera()
              break
            case false:
              basicErrorAlertWith(title: basicTitleForAccessError, message: cameraAccessDeniedMessageProfilePicture, controller: controller)
              break
          }
        }
			@unknown default:
				fatalError()
		}
  }
  
  private func presentGallery() {
    picker = UIImagePickerController()
    picker.delegate = self
    picker.allowsEditing = false
    picker.sourceType = .photoLibrary
    picker.modalPresentationStyle = .overFullScreen
    picker.modalPresentationCapturesStatusBarAppearance = true
    parentController?.present(picker, animated: true, completion: nil)
  }
  
  private func presentCamera() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      guard let controller = parentController else { return }
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: cameraNotExistsMessage, controller: controller)
      return
    }
    picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = .camera
    picker.allowsEditing = false
    picker.modalPresentationStyle = .overFullScreen
    picker.modalPresentationCapturesStatusBarAppearance = true
    parentController?.present(picker, animated: true, completion: nil)
  }

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		var selectedImageFromPicker: UIImage?
		if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
			selectedImageFromPicker = editedImage

		} else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
			selectedImageFromPicker = originalImage
		}

		if let selectedImage = selectedImageFromPicker {
			let cropController = CropViewController(croppingStyle: .default, image: selectedImage)
			cropController.delegate = self
			picker.pushViewController(cropController, animated: true)
		}

	}

  
  func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
    cropViewController.delegate = nil
    
    let compressedImageData = compressImage(image: image)
    if let compressedImage = UIImage(data: compressedImageData) {
      delegate?.avatarOpener(avatarPickerDidPick: compressedImage)
    }
  
    parentController?.dismiss(animated: true, completion: nil)
  }
  
  func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
    if picker.sourceType == .camera {
      parentController?.dismiss(animated: true, completion: {
        self.parentController?.present(self.picker, animated: true, completion: nil)
      })
    } else {
      picker.popViewController(animated: true)
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    parentController?.dismiss(animated: true, completion: nil)
  }
}
