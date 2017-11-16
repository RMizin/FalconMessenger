//
//  ChatLogController+MediaPickerHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos


extension ChatLogController {
  
  @objc func toggleTextView () {
    
    inputContainerView.inputTextView.inputView = nil
    inputContainerView.inputTextView.reloadInputViews()
    inputContainerView.attachButton.isSelected = false
  }
  
    
  @objc func togglePhoto () {
    
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
      case .authorized:
        break
      case .denied, .restricted:
        break
      case .notDetermined:
        PHPhotoLibrary.requestAuthorization() { status in
          switch status {
            case .authorized:
              self.inputContainerView.mediaPickerController?.customMediaPickerView.imageManager = PHCachingImageManager()
              self.inputContainerView.mediaPickerController?.customMediaPickerView.fetchAssets()
              self.inputContainerView.mediaPickerController?.customMediaPickerView.collectionView.reloadData()
            break
        case .denied, .restricted, .notDetermined:
          break
        }
      }
    }
    
    if mediaPickerController == nil {
      mediaPickerController = MediaPickerController()
    }
  
    inputContainerView.attachButton.isSelected = !inputContainerView.attachButton.isSelected
    
    if inputContainerView.attachButton.isSelected {
      mediaPickerController.inputContainerView = inputContainerView
      
      if inputContainerView.mediaPickerController == nil {
        inputContainerView.mediaPickerController = mediaPickerController
      }
      
      inputContainerView.inputTextView.inputView = mediaPickerController.view
      inputContainerView.inputTextView.reloadInputViews()
      inputContainerView.inputTextView.becomeFirstResponder()
      inputContainerView.inputTextView.addGestureRecognizer(inputTextViewTapGestureRecognizer)
    
    } else {
     
      inputContainerView.inputTextView.inputView = nil
      inputContainerView.inputTextView.reloadInputViews()
      inputContainerView.inputTextView.removeGestureRecognizer(inputTextViewTapGestureRecognizer)
    }
  }
}
