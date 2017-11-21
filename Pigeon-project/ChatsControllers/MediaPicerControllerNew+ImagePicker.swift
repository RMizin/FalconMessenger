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
  
  func indexPathIsValid(indexPath: IndexPath) -> Bool {
    if indexPath.section >= self.numberOfSections(in: self.collectionView) {
      return false
    }
    if indexPath.row >=  self.collectionView.numberOfItems(inSection: indexPath.section) {
      return false
    }
    return true
  }
  
  
  override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    
    if picker.sourceType == UIImagePickerControllerSourceType.camera {
      
      if let mediaType = info[UIImagePickerControllerMediaType] as? String {
        
        if mediaType  == "public.image" {
          
          if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            PHPhotoLibrary.shared().performChanges ({
              
              PHAssetChangeRequest.creationRequestForAsset(from: originalImage)
              
            }, completionHandler: { (isSaved, error) in
              
              if isSaved {
                
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
              } else {
                
                self.delegate?.controller?(self, didTakeImage: originalImage)
                self.dismissImagePicker()
              }
            })
          }
        }
        
        if mediaType == "public.movie" {
          
          if let pickedVideo = info[UIImagePickerControllerMediaURL] as? URL {
            
            PHPhotoLibrary.shared().performChanges ({
              
              PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: pickedVideo)
              
            }) { isSaved, error in
              
              if isSaved {
                
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
              } else {
                
                let alertMessage = videoRecordedButLibraryUnavailableError
                self.dismissImagePicker()
                basicErrorAlertWith(title: basicTitleForAccessError, message: alertMessage, controller: self)
                
              }
            }
          }
        }
      }
      
    } else {
      
      if let imageURL = info[UIImagePickerControllerReferenceURL] as? URL {
        
        let result = PHAsset.fetchAssets(withALAssetURLs: [imageURL], options: nil)
        
        let asset = result.firstObject
        
        let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems
        
        for selectedIndexPath in selectedIndexPaths! {
          
          if self.assets[selectedIndexPath.item] == asset {
            
            print("you selected already selected image")
            
            dismissImagePicker()
            
            return
          }
        }
        
        for index in 0...self.assets.count - 1 {
          
          if self.assets[index] == asset {
            
            print("you selected not selected image, selecting...")
            
            let indexPathForSelection = IndexPath(item: index, section: 2)
            
            let indexPathExists = indexPathIsValid(indexPath: indexPathForSelection)
            
            if indexPathExists {
              self.collectionView.selectItem(at: indexPathForSelection, animated: false, scrollPosition: .left)
              print("exist")
              self.delegate?.controller?(self, didSelectAsset: asset!, at: indexPathForSelection)
            } else {
              print("not exists")
            }
            
            dismissImagePicker()
            return
          }
        }
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
