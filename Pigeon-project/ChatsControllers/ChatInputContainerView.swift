//
//  ChatInputContainerView.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit


class ChatInputContainerView: UIView, UITextViewDelegate, UIGestureRecognizerDelegate {
  
  weak var chatLogController: ChatLogController? {
    didSet {
      sendButton.addTarget(chatLogController, action: #selector(ChatLogController.handleSend), for: .touchUpInside)
      attachButton.addTarget(chatLogController, action: #selector(ChatLogController.togglePhoto), for: .touchDown)
    }
  }
  
  func textViewDidBeginEditing(_ textView: UITextView) {
    print("didbegin editing")
    chatLogController?.collectionView?.scrollToBottom()
    
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    
    return true
  }

  var maxTextViewHeight: CGFloat = 0.0
  
  override var intrinsicContentSize: CGSize {
    get {
      let textSize = self.inputTextView.sizeThatFits(CGSize(width: self.inputTextView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
      
          
      if textSize.height > 200 {
        maxTextViewHeight = 200
        inputTextView.isScrollEnabled = true
      } else {
        inputTextView.isScrollEnabled = false
        
        maxTextViewHeight = textSize.height + 12
      }
          
      return CGSize(width: self.bounds.width, height: maxTextViewHeight )
    }
  }
  
  func textViewDidChange(_ textView: UITextView) {
    
    placeholderLabel.isHidden = !textView.text.isEmpty
    
    if textView.text == nil || textView.text == "" {
      sendButton.isEnabled = false
    } else {
      sendButton.isEnabled = true
    }
    chatLogController?.isTyping = textView.text != ""
    
    if textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
      sendButton.isEnabled = false
    }
    
    self.invalidateIntrinsicContentSize()
    chatLogController?.collectionView?.scrollToBottom()
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    attachButton.isSelected = false
  }

  
  lazy var inputTextView: UITextView = {
    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.delegate = self
    textView.font = UIFont.systemFont(ofSize: 16)
    textView.sizeToFit()
    textView.isScrollEnabled = false
    textView.layer.borderColor = UIColor.lightGray.cgColor
    textView.layer.borderWidth = 0.3
    textView.layer.cornerRadius = 16
    textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 8, right: 30)
    textView.backgroundColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
 
    return textView
  }()
  
  let placeholderLabel: UILabel = {
    let placeholderLabel = UILabel()
    placeholderLabel.text = "Message"
    placeholderLabel.sizeToFit()
    placeholderLabel.textColor = UIColor.lightGray
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    
    return placeholderLabel
  }()
  
  let attachButton: UIButton = {
    let attachButton = UIButton()
    attachButton.tintColor = PigeonPalette.pigeonPaletteBlue
    attachButton.translatesAutoresizingMaskIntoConstraints = false
    attachButton.setImage(UIImage(named: "ConversationAttach"), for: .normal)
    attachButton.setImage(UIImage(named: "SelectedModernConversationAttach"), for: .selected)
   
    return attachButton
  }()
  
  let sendButton = UIButton(type: .system)
  
  let attachedImages: UICollectionView = {
    let attachedImages = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    attachedImages.backgroundColor = .clear

    return attachedImages
  }()
  
  let separator: UIView = {
    let separator = UIView()
    separator.translatesAutoresizingMaskIntoConstraints = false
    separator.backgroundColor = UIColor.lightGray
    separator.isHidden = false
    
    return separator
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
       
    backgroundColor = .white
    self.autoresizingMask = UIViewAutoresizing.flexibleHeight
    self.inputTextView.delegate = self
    
    sendButton.setImage(UIImage(named: "send"), for: UIControlState())
    sendButton.translatesAutoresizingMaskIntoConstraints = false
    sendButton.isEnabled = false
    
    addSubview(attachButton)
    addSubview(inputTextView)
    addSubview(sendButton)
    addSubview(placeholderLabel)
    inputTextView.addSubview(attachedImages)
    inputTextView.addSubview(separator)
    
    separator.translatesAutoresizingMaskIntoConstraints = false
    separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    separator.leadingAnchor.constraint(equalTo: attachedImages.leadingAnchor).isActive = true
    separator.trailingAnchor.constraint(equalTo: attachedImages.trailingAnchor).isActive = true
    separator.bottomAnchor.constraint(equalTo: attachedImages.bottomAnchor).isActive = true
    
    attachButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
    attachButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    attachButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    attachButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
    
    inputTextView.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
    inputTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true
    inputTextView.leftAnchor.constraint(equalTo: attachButton.rightAnchor, constant: 15).isActive = true
    inputTextView.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
    
    placeholderLabel.font = UIFont.systemFont(ofSize: (inputTextView.font?.pointSize)!)
    placeholderLabel.isHidden = !inputTextView.text.isEmpty
    placeholderLabel.leftAnchor.constraint(equalTo: inputTextView.leftAnchor, constant: 12).isActive = true
    placeholderLabel.rightAnchor.constraint(equalTo: inputTextView.rightAnchor).isActive = true
    placeholderLabel.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: -(inputTextView.font?.pointSize)! / 2).isActive = true
    placeholderLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    
    sendButton.rightAnchor.constraint(equalTo: inputTextView.rightAnchor, constant: -5).isActive = true
    sendButton.bottomAnchor.constraint(equalTo:  inputTextView.bottomAnchor, constant: -5).isActive = true
    sendButton.widthAnchor.constraint(equalToConstant: 27).isActive = true
    sendButton.heightAnchor.constraint(equalToConstant: 27).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension ChatInputContainerView: UITextFieldDelegate {
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    chatLogController?.handleSend()
    return true
  }
  
}

extension UIColor {
  
  convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
    self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
  }
}
