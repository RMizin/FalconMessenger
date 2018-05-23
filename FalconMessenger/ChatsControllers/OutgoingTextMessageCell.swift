//
//  OutgoingTextMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SafariServices


class OutgoingTextMessageCell: BaseMessageCell {
  
  let textView: FalconTextView = {
    let textView = FalconTextView()
    textView.font = MessageFontsAppearance.defaultMessageTextFont
    textView.backgroundColor = .clear
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsetsMake(textViewTopInset, outgoingTextViewLeftInset, textViewBottomInset, outgoingTextViewRightInset)
    textView.dataDetectorTypes = .all
    textView.textColor = .white
    textView.linkTextAttributes = [NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue]

    return textView
  }()
  
  func setupData(message: Message) {
    
    self.message = message
    guard let messageText = message.text else { return }
    textView.text = messageText
    
    let x = frame.width - message.estimatedFrameForText!.width - BaseMessageCell.outgoingMessageHorisontalInsets - BaseMessageCell.scrollIndicatorInset
    bubbleView.frame = CGRect(x: x, y: 0, width: message.estimatedFrameForText!.width + BaseMessageCell.outgoingMessageHorisontalInsets, height: frame.size.height).integral
    textView.frame.size = CGSize(width: bubbleView.frame.width, height: bubbleView.frame.height)
    
    setupTimestampView(message: message, isOutgoing: true)
    
    if let isCrooked = self.message?.isCrooked, isCrooked {
       bubbleView.image = ThemeManager.currentTheme().outgoingBubble//blueBubbleImage
    } else {
       bubbleView.image = ThemeManager.currentTheme().outgoingPartialBubble
    }
  }
  
  override func setupViews() {
    textView.delegate = self
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textView)
    contentView.addSubview(deliveryStatus)
  }
  
  override func prepareViewsForReuse() {
     bubbleView.image = nil
  }
}

extension OutgoingTextMessageCell: UITextViewDelegate {
  
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    guard interaction != .preview else { return false }
    var svc = SFSafariViewController(url: URL as URL)
    
    if #available(iOS 11.0, *) {
      let configuration = SFSafariViewController.Configuration()
      configuration.entersReaderIfAvailable = true
      svc = SFSafariViewController(url: URL as URL, configuration: configuration)
    }
    
    svc.preferredControlTintColor = FalconPalette.defaultBlue
    svc.preferredBarTintColor = ThemeManager.currentTheme().generalBackgroundColor
    chatLogController?.present(svc, animated: true, completion: nil)
    
    return false
  }
}
