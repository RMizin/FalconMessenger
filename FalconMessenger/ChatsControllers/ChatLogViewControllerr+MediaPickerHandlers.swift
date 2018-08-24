//
//  ChatLogController+MediaPickerHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos


extension ChatLogViewController {
  
  @objc func toggleTextView () {
    
    if inputContainerView.attachButton.isSelected || inputContainerView.recordVoiceButton.isSelected {
      inputContainerView.inputTextView.inputView = nil
      inputContainerView.inputTextView.reloadInputViews()
    } else {
      guard !inputContainerView.inputTextView.isFirstResponder else { return }
      inputContainerView.inputTextView.becomeFirstResponder()
    }
    setRecordVoiceButtonSelected(isSelected: false)
    setAttachButtonSelected(isSelected: false)
  }
  
  @objc func togglePhoto () {
    
    checkAuthorisationStatus()
    if mediaPickerController == nil { mediaPickerController = MediaPickerControllerNew() }
    if  inputContainerView.attachButton.isSelected {
      setAttachButtonSelected(isSelected: false)
    } else {
      setAttachButtonSelected(isSelected: true)
    }
    
    guard inputContainerView.attachButton.isSelected else {
      inputContainerView.inputTextView.inputView = nil
      inputContainerView.inputTextView.reloadInputViews()
      inputContainerView.inputTextView.removeGestureRecognizer(inputTextViewTapGestureRecognizer)
      return
    }

    mediaPickerController.inputContainerView = inputContainerView
    if inputContainerView.mediaPickerController == nil {
      inputContainerView.mediaPickerController = mediaPickerController
    }
    
    setRecordVoiceButtonSelected(isSelected: false)
    inputContainerView.inputTextView.inputView = mediaPickerController.view
    inputContainerView.inputTextView.reloadInputViews()
    inputContainerView.inputTextView.becomeFirstResponder()
    inputContainerView.inputTextView.addGestureRecognizer(inputTextViewTapGestureRecognizer)
  }
  
  func setRecordVoiceButtonSelected(isSelected: Bool) {
    UIView.transition(with: inputContainerView.recordVoiceButton, duration: 0.2, options: .transitionCrossDissolve,
                      animations: { self.inputContainerView.recordVoiceButton.isSelected = isSelected }, completion: nil)
  }
  
  func setAttachButtonSelected(isSelected: Bool) {
    
    UIView.transition(with: inputContainerView.attachButton, duration: 0.2, options: .transitionCrossDissolve,
                      animations: { self.inputContainerView.attachButton.isSelected = isSelected }, completion: nil)
  }
  
  func checkAuthorisationStatus() {
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .authorized:
      break
    case .denied, .restricted:
      break
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization { status in
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
  }
}
