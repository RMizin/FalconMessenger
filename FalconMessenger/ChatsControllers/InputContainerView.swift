//
//  InputContainerView.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation

final class InputContainerView: UIControl {

  var audioPlayer: AVAudioPlayer!
  
  weak var mediaPickerController: MediaPickerControllerNew?
  weak var trayDelegate: ImagePickerTrayControllerDelegate?
  var attachedMedia = [MediaObject]()
  fileprivate var tap = UITapGestureRecognizer()
  static let commentOrSendPlaceholder = "Comment or Send"
  static let messagePlaceholder = "Message"

  weak var chatLogController: ChatLogViewController? {
    didSet {
      sendButton.addTarget(chatLogController, action: #selector(ChatLogViewController.sendMessage), for: .touchUpInside)
    }
  }
  
  lazy var inputTextView: InputTextView = {
    let textView = InputTextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.delegate = self
    
    return textView
  }()
  
  lazy var attachCollectionView: AttachCollectionView = {
    let attachCollectionView = AttachCollectionView()

    return attachCollectionView
  }()
  
  let placeholderLabel: UILabel = {
    let placeholderLabel = UILabel()
    placeholderLabel.text = messagePlaceholder
    placeholderLabel.sizeToFit()
    placeholderLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    
    return placeholderLabel
  }()

  var attachButton: MediaPickerRespondingButton = {
    var attachButton = MediaPickerRespondingButton()
    attachButton.addTarget(self, action: #selector(togglePhoto), for: .touchDown)
    
    return attachButton
  }()
  
  var recordVoiceButton: VoiceRecorderRespondingButton = {
    var recordVoiceButton = VoiceRecorderRespondingButton()
    recordVoiceButton.addTarget(self, action: #selector(toggleVoiceRecording), for: .touchDown)
    
    return recordVoiceButton
  }()

  let sendButton: UIButton = {
    let sendButton = UIButton(type: .custom)
    sendButton.setImage(UIImage(named: "send"), for: .normal)
    sendButton.translatesAutoresizingMaskIntoConstraints = false
    sendButton.isEnabled = false
	 	sendButton.backgroundColor = .white
    
    return sendButton
  }()
  
  private var heightConstraint: NSLayoutConstraint!

  private func addHeightConstraints() {
    heightConstraint = heightAnchor.constraint(equalToConstant: InputTextViewLayout.minHeight)
    heightConstraint.isActive = true
  }

  func confirugeHeightConstraint() {
    let size = inputTextView.sizeThatFits(CGSize(width: inputTextView.bounds.size.width, height: .infinity))
    let height = size.height + 12
    heightConstraint.constant = height < InputTextViewLayout.maxHeight() ? height : InputTextViewLayout.maxHeight()
    let maxHeight: CGFloat = InputTextViewLayout.maxHeight()
    guard height >= maxHeight else { inputTextView.isScrollEnabled = false; return }
    inputTextView.isScrollEnabled = true
  }
  
  func handleRotation() {
    attachCollectionView.collectionViewLayout.invalidateLayout()
    DispatchQueue.main.async { [weak self] in
			guard let width = self?.inputTextView.frame.width else { return }
      self?.attachCollectionView.frame.size.width = width//self?.inputTextView.frame.width
      self?.attachCollectionView.reloadData()
      self?.confirugeHeightConstraint()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme),
                                           name: .themeUpdated, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(inputViewResigned),
                                           name: .inputViewResigned, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(inputViewResponded),
                                           name: .inputViewResponded, object: nil)
    addHeightConstraints()
    backgroundColor = ThemeManager.currentTheme().barBackgroundColor
	//	sendButton.tintColor = ThemeManager.generalTintColor
    addSubview(attachButton)
    addSubview(recordVoiceButton)
    addSubview(inputTextView)
    addSubview(sendButton)
    addSubview(placeholderLabel)
    inputTextView.addSubview(attachCollectionView)
		sendButton.layer.cornerRadius = 15
		sendButton.clipsToBounds = true

    tap = UITapGestureRecognizer(target: self, action: #selector(toggleTextView))
    tap.delegate = self

    if #available(iOS 11.0, *) {
      attachButton.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 5).isActive = true
      inputTextView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
    } else {
      attachButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
      inputTextView.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
    }
    
    attachButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    attachButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    attachButton.widthAnchor.constraint(equalToConstant: 35).isActive = true

    recordVoiceButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    recordVoiceButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    recordVoiceButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
    recordVoiceButton.leftAnchor.constraint(equalTo: attachButton.rightAnchor, constant: 0).isActive = true

    inputTextView.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
    inputTextView.leftAnchor.constraint(equalTo: recordVoiceButton.rightAnchor, constant: 3).isActive = true
    inputTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true
    
    placeholderLabel.font = UIFont.systemFont(ofSize: (inputTextView.font!.pointSize))
    placeholderLabel.isHidden = !inputTextView.text.isEmpty
    placeholderLabel.leftAnchor.constraint(equalTo: inputTextView.leftAnchor, constant: 12).isActive = true
    placeholderLabel.rightAnchor.constraint(equalTo: inputTextView.rightAnchor).isActive = true
    placeholderLabel.topAnchor.constraint(equalTo: attachCollectionView.bottomAnchor,
                                          constant: inputTextView.font!.pointSize / 2.3).isActive = true
    placeholderLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    
    sendButton.rightAnchor.constraint(equalTo: inputTextView.rightAnchor, constant: -4).isActive = true
    sendButton.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: -4).isActive = true
    sendButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
    sendButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    configureAttachCollectionView()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc func changeTheme() {
    backgroundColor = ThemeManager.currentTheme().barBackgroundColor
    inputTextView.changeTheme()
    attachButton.changeTheme()
    recordVoiceButton.changeTheme()
  }
  
  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc func toggleTextView () {
    print("toggling")
    inputTextView.inputView = nil
    inputTextView.reloadInputViews()
    UIView.performWithoutAnimation {
      inputTextView.resignFirstResponder()
      inputTextView.becomeFirstResponder()
    }
  }
  
  @objc fileprivate func inputViewResigned() {
    inputTextView.removeGestureRecognizer(tap)
  }

  @objc fileprivate func inputViewResponded() {
    guard let recognizers = inputTextView.gestureRecognizers else { return }
    guard !recognizers.contains(tap) else { return }
    inputTextView.addGestureRecognizer(tap)
  }

  @objc func togglePhoto () {

    checkAuthorisationStatus()
    UIView.performWithoutAnimation {
      _ = recordVoiceButton.resignFirstResponder()
    }
    if attachButton.isFirstResponder {
    _ = attachButton.resignFirstResponder()
    } else {

			if attachButton.controller == nil {
				attachButton.controller = MediaPickerControllerNew()
				mediaPickerController = attachButton.controller
				mediaPickerController?.mediaPickerDelegate = self
			}

			_ = attachButton.becomeFirstResponder()
    //  inputTextView.addGestureRecognizer(tap)
    }
  }
  
  @objc func toggleVoiceRecording () {
    UIView.performWithoutAnimation {
       _ = attachButton.resignFirstResponder()
    }

    if recordVoiceButton.isFirstResponder {
      _ = recordVoiceButton.resignFirstResponder()
    } else {

			if recordVoiceButton.controller == nil {
				recordVoiceButton.controller = VoiceRecordingViewController()
				recordVoiceButton.controller?.mediaPickerDelegate = self
			}

      _ = recordVoiceButton.becomeFirstResponder()
     // inputTextView.addGestureRecognizer(tap)
    }
  }

  func resignAllResponders() {
    inputTextView.resignFirstResponder()
    _ = attachButton.resignFirstResponder()
    _ = recordVoiceButton.resignFirstResponder()
  }
}

extension InputContainerView {
  
  func prepareForSend() {
    inputTextView.text = ""
    sendButton.isEnabled = false
    placeholderLabel.isHidden = false
    inputTextView.isScrollEnabled = false
    attachedMedia.removeAll()
    attachCollectionView.reloadData()
    resetChatInputConntainerViewSettings()
  }

  func resetChatInputConntainerViewSettings() {
    guard attachedMedia.isEmpty else { return }
    attachCollectionView.frame = CGRect(x: 0, y: 0, width: inputTextView.frame.width, height: 0)
    inputTextView.textContainerInset = InputTextViewLayout.defaultInsets
    placeholderLabel.text = InputContainerView.messagePlaceholder
    sendButton.isEnabled = !inputTextView.text.isEmpty
    confirugeHeightConstraint()
  }

  func expandCollection() {
    sendButton.isEnabled = (!inputTextView.text.isEmpty || !attachedMedia.isEmpty)
    placeholderLabel.text = InputContainerView.commentOrSendPlaceholder
    attachCollectionView.frame = CGRect(x: 0, y: 3,
                                        width: inputTextView.frame.width, height: AttachCollectionView.height)
    inputTextView.textContainerInset = InputTextViewLayout.extendedInsets
    confirugeHeightConstraint()
  }
}

extension InputContainerView: UIGestureRecognizerDelegate {
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard attachCollectionView.bounds.contains(touch.location(in: attachCollectionView)) else { return true }
      return false
  }
}

extension InputContainerView: UITextViewDelegate {

 private func handleSendButtonState() {
    let whiteSpaceIsEmpty = inputTextView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
    if (attachedMedia.count > 0 && !whiteSpaceIsEmpty) || (inputTextView.text != "" && !whiteSpaceIsEmpty) {
      sendButton.isEnabled = true
    } else {
      sendButton.isEnabled = false
    }
  }

  func textViewDidChange(_ textView: UITextView) {
    confirugeHeightConstraint()
    placeholderLabel.isHidden = !textView.text.isEmpty
    chatLogController?.isTyping = !textView.text.isEmpty
    handleSendButtonState()
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    if chatLogController?.chatLogAudioPlayer != nil {
      chatLogController?.chatLogAudioPlayer.stop()
      chatLogController?.chatLogAudioPlayer = nil
    }
  }

  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    guard text == "\n", let chatLogController = self.chatLogController else { return true }
    if chatLogController.isScrollViewAtTheBottom() {
			chatLogController.collectionView.scrollToBottom(animated: false)
    }
    return true
  }
}
