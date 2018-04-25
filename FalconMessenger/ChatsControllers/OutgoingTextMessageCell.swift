//
//  OutgoingTextMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


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
  }
  
  override func setupViews() {
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textView)
    contentView.addSubview(deliveryStatus)
    bubbleView.image = blueBubbleImage
  }
  
  override func prepareViewsForReuse() {
     bubbleView.image = blueBubbleImage
  }
}

