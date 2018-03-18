//
//  IncomingTextMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


class IncomingTextMessageCell: BaseMessageCell {
  
  let textView: FalconTextView = {
    let textView = FalconTextView()
    textView.font = UIFont.systemFont(ofSize: 13)
    textView.backgroundColor = .clear
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsetsMake(incomingTextViewTopInset, incomingTextViewLeftInset, incomingTextViewBottomInset, incomingTextViewRightInset)
    textView.dataDetectorTypes = .all
    textView.textColor = .darkText
    textView.linkTextAttributes = [NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue]
    
    return textView
  }()
  
  override func setupViews() {
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textView)
    textView.addSubview(nameLabel)
    bubbleView.image = grayBubbleImage
    bubbleView.frame.origin = CGPoint(x: 10, y: 0)
  }
  
  override func prepareViewsForReuse() {
    bubbleView.image = grayBubbleImage
    nameLabel.text = ""
    textView.textContainerInset = UIEdgeInsetsMake(10, 12, 10, 7)
  }
}
