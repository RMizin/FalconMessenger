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
    imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
    presentImagePicker()
  }
  
  
 @objc func openCamera() {
    
    if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
      imagePicker.sourceType = UIImagePickerControllerSourceType.camera
      
      presentImagePicker()
      
    } else {
      
      let alert = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      alert.modalPresentationStyle = .overCurrentContext
      self.present(alert, animated: true, completion: nil)
    }
  }
  
//  func indexPathIsValid(indexPath: IndexPath) -> Bool {
//    if indexPath.section >= self.numberOfSections(in: self.collectionView) {
//      return false
//    }
//    if indexPath.row >=  self.collectionView.numberOfItems(inSection: indexPath.section) {
//      return false
//    }
//    return true
//  }
  
  
  override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
    if picker.sourceType == UIImagePickerControllerSourceType.camera {
      
      if let mediaType = info[UIImagePickerControllerMediaType] as? String {
        
        if mediaType  == "public.image" {
          
          guard let originalImage = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
            
            PHPhotoLibrary.shared().performChanges ({
              
              PHAssetChangeRequest.creationRequestForAsset(from: originalImage)
              
            }, completionHandler: { (isSaved, error) in
              
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
          
          if let pickedVideo = info[UIImagePickerControllerMediaURL] as? URL {
            
            PHPhotoLibrary.shared().performChanges ({
              
              PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: pickedVideo)
              
            }) { isSaved, error in
              
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
      
      if let imageURL = info[UIImagePickerControllerReferenceURL] as? URL {
        
        let result = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
        let asset = result.firstObject
        
        guard let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems else { return }
                
        for selectedIndexPath in selectedIndexPaths {
          if self.assets[selectedIndexPath.item] == asset {
            print("you selected already selected image")
            dismissImagePicker()
            return
          }
        }
    
        guard let indexForSelection = self.assets.index(where: { (phAsset) -> Bool in
          return phAsset == asset
        }) else {
          print("you selected image which is not in preview, processing...")
          self.delegate?.controller?(self, didSelectAsset: asset!, at: nil)
          dismissImagePicker()
          return
        }
        
        print("you selected not selected image, selecting...")
        let indexPathForSelection = IndexPath(item: indexForSelection, section: 2)
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
    present(imagePicker, animated: true, completion: nil)
  }
  
  func dismissImagePicker () {
    dismiss(animated: true, completion: nil)
  }
}
