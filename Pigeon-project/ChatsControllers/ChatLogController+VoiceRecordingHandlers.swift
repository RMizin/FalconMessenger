//
//  ChatLogController+VoiceRecordingHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit



extension ChatLogController {
  
  @objc func toggleVoiceRecording () {
    
    if voiceRecordingViewController == nil {
      voiceRecordingViewController = VoiceRecordingViewController()
    }

    inputContainerView.recordVoiceButton.isSelected = !inputContainerView.recordVoiceButton.isSelected
    
    if inputContainerView.recordVoiceButton.isSelected {
      voiceRecordingViewController.inputContainerView = inputContainerView
      inputContainerView.attachButton.isSelected = false
      inputContainerView.inputTextView.inputView = voiceRecordingViewController.view
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
