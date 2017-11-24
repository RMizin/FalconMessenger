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
    
  
    if inputContainerView.attachButton.isSelected {
      self.inputContainerView.inputTextView.inputView = nil
      self.inputContainerView.inputTextView.reloadInputViews()
    } else {
      UIView.performWithoutAnimation {
        self.inputContainerView.inputTextView.inputView = nil
        self.inputContainerView.inputTextView.reloadInputViews()
        self.inputContainerView.inputTextView.resignFirstResponder()
      }
      self.inputContainerView.inputTextView.becomeFirstResponder()
    }
    
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
              self.inputContainerView.mediaPickerController?.imageManager = PHCachingImageManager()
              self.inputContainerView.mediaPickerController?.fetchAssets()
              self.inputContainerView.mediaPickerController?.collectionView.reloadData()
            break
        case .denied, .restricted, .notDetermined:
          break
        }
      }
    }
    
    if mediaPickerController == nil {
      mediaPickerController = MediaPickerControllerNew()
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
