//
//  ChatInputContainerView.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit


class ChatInputContainerView: UIView, UITextViewDelegate {
  
  weak var chatLogController: ChatLogController? {
    didSet {
      sendButton.addTarget(chatLogController, action: #selector(ChatLogController.handleSend), for: .touchUpInside)
      //uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: chatLogController, action: #selector(ChatLogController.handleUploadTap)))
    }
  }
  
  func textViewDidBeginEditing(_ textView: UITextView) {
    chatLogController?.collectionView?.scrollToBottom()
  }
  
  var maxTextViewHeight: CGFloat = 0.0
  
  override var intrinsicContentSize: CGSize {
    get {
      let textSize = self.inputTextView.sizeThatFits(CGSize(width: self.inputTextView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
      
      if textSize.height > 150 {
        inputTextView.isScrollEnabled = true
      } else {
        inputTextView.isScrollEnabled = false
        maxTextViewHeight = textSize.height +  12
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
    placeholderLabel.text = "Сообщение"
    placeholderLabel.sizeToFit()
    placeholderLabel.textColor = UIColor.lightGray
    
    return placeholderLabel
  }()
  
  let uploadImageView: UIImageView = {
    let uploadImageView = UIImageView()
    uploadImageView.isUserInteractionEnabled = true
    uploadImageView.contentMode = .scaleAspectFit
    uploadImageView.layer.masksToBounds = true
    uploadImageView.image = UIImage(named: "ConversationAttach")
    uploadImageView.translatesAutoresizingMaskIntoConstraints = false
    
    return uploadImageView
  }()
  
  let sendButton = UIButton(type: .system)
  
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .white
    self.autoresizingMask = UIViewAutoresizing.flexibleHeight
    self.inputTextView.delegate = self
    
    sendButton.setImage(UIImage(named: "send"), for: UIControlState())
    sendButton.translatesAutoresizingMaskIntoConstraints = false
    sendButton.isEnabled = false
    
    addSubview(uploadImageView)
    uploadImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
    uploadImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    uploadImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
    
    addSubview(inputTextView)
    inputTextView.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
    inputTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true
    inputTextView.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 15).isActive = true
    inputTextView.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
    
    inputTextView.addSubview(placeholderLabel)
    placeholderLabel.font = UIFont.systemFont(ofSize: (inputTextView.font?.pointSize)!)
    placeholderLabel.frame.origin = CGPoint(x: 12, y: (inputTextView.font?.pointSize)! / 2)
    placeholderLabel.isHidden = !inputTextView.text.isEmpty
    
    addSubview(sendButton)
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
