//
//  RespondingButton.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/21/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class RespondingButton: UIButton, UIKeyInput {
  
  var mediaInputViewController: UIViewController?
  
  var hasText: Bool = true
  func insertText(_ text: String) {}
  func deleteBackward() {}
  
  init(controller: UIViewController) {
    super.init(frame: .zero)
    mediaInputViewController = controller
    changeTheme()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var canBecomeFirstResponder: Bool {
    return true
  }

  override func resignFirstResponder() -> Bool {
    NotificationCenter.default.post(name: .inputViewResigned, object: nil)
    isSelected = false
    resetVoice()
    return super.resignFirstResponder()
  }
  
  override func becomeFirstResponder() -> Bool {
    NotificationCenter.default.post(name: .inputViewResponded, object: nil)
    isSelected = true
    return super.becomeFirstResponder()
  }
  
  override var inputView: UIView? {
    get {
      return mediaInputViewController?.view
    }
  }

  func reset() {
    guard let voiceController = mediaInputViewController as? VoiceRecordingViewController else {
      guard let mediaController = mediaInputViewController as? MediaPickerControllerNew else { return }
      mediaController.collectionView.deselectAllItems()
      return
    }
  
      guard voiceController.recorder != nil else { return }
      voiceController.stop()
      voiceController.deleteAllRecordings()
  }
  
  fileprivate func resetVoice() {
    guard let voiceController = mediaInputViewController as? VoiceRecordingViewController else { return }
    guard voiceController.recorder != nil else { return }
    voiceController.stop()
  }
  
  func changeTheme() {
    inputView?.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
  }
}
