//
//  MediaPicerControllerNew+ImagePicker.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary
import MobileCoreServices
import AVFoundation

extension MediaPickerControllerNew {
  
 @objc func openPhotoLibrary() {
    imagePicker.sourceType = .photoLibrary
    presentImagePicker()
  }
  
 @objc func openCamera() {
    
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      imagePicker.sourceType = .camera
      presentImagePicker()
      
    } else {
      
      let alert = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      alert.modalPresentationStyle = .overCurrentContext
      present(alert, animated: true, completion: nil)
    }
  }

  override func imagePickerController(_ picker: UIImagePickerController,
																			didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    
		if picker.sourceType == UIImagePickerController.SourceType.camera {
      
			if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
        
        if mediaType  == "public.image" {
          
					guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
      
            PHPhotoLibrary.shared().performChanges ({
              
              PHAssetChangeRequest.creationRequestForAsset(from: originalImage)
              
            }, completionHandler: { (isSaved, _) in
              
              guard isSaved else {
                self.delegate?.controller?(self, didTakeImage: originalImage)
                self.dismissImagePicker()
                return
              }
                
              let options = PHFetchOptions()
              options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
              options.fetchLimit = 1
              let result = PHAsset.fetchAssets(with: options)
              let asset = result.firstObject
                
              self.reFetchAssets(completionHandler: { (isCompleted) in
                if isCompleted {
                  self.delegate?.controller?(self, didTakeImage: originalImage, with: asset!)
                  self.dismissImagePicker()
                }
              })
            })
        }
        
        if mediaType == "public.movie" {
          
					if let pickedVideo = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            
            PHPhotoLibrary.shared().performChanges ({
              
              PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: pickedVideo)
              
            }) { isSaved, _ in

              guard isSaved else {
                let alertMessage = videoRecordedButLibraryUnavailableError
                self.dismissImagePicker()
                basicErrorAlertWith(title: basicTitleForAccessError, message: alertMessage, controller: self)
                return
              }

              let options = PHFetchOptions()
              options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
              options.fetchLimit = 1
              let result = PHAsset.fetchAssets(with: options)
              let asset = result.firstObject
                
              self.reFetchAssets(completionHandler: { (isCompleted) in
                if isCompleted {
                  self.delegate?.controller?(self, didRecordVideoAsset: asset!)
                  self.dismissImagePicker()
                }
              })
            }
          }
        }
      }
      
    } else {
      
			if let imageURL = info[UIImagePickerController.InfoKey.referenceURL] as? URL {
        
        let result = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
        let asset = result.firstObject
        
        guard let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems else { return }
                
        for selectedIndexPath in selectedIndexPaths where self.assets[selectedIndexPath.item] == asset {
        //  if  {
            print("you selected already selected image")
            dismissImagePicker()
            return
        //  }
        }
    
				guard let indexForSelection = self.assets.firstIndex(where: { (phAsset) -> Bool in
          return phAsset == asset
        }) else {
          print("you selected image which is not in preview, processing...")
          self.delegate?.controller?(self, didSelectAsset: asset!, at: nil)
          dismissImagePicker()
          return
        }
        
        print("you selected not selected image, selecting...")
        let indexPathForSelection = IndexPath(item: indexForSelection, section: ImagePickerTrayController.librarySectionIndex)
        self.collectionView.selectItem(at: indexPathForSelection, animated: false, scrollPosition: .left)
        self.delegate?.controller?(self, didSelectAsset: asset!, at: indexPathForSelection)
        dismissImagePicker()
      }
    }
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismissImagePicker()
  }
  
  func presentImagePicker() {
    imagePicker.modalPresentationStyle = .overCurrentContext
		present(imagePicker, animated: true) {
			self.imagePicker.navigationBar.layoutSubviews()
		}
  }
  
  func dismissImagePicker () {
    dismiss(animated: true, completion: nil)
  }
}
