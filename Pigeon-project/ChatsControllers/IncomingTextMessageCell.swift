//
//  IncomingTextMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class IncomingTextMessageCell: BaseMessageCell {
  
  let textView: UITextView = {
    let textView = UITextView()
    textView.font = UIFont.systemFont(ofSize: 13)
    textView.backgroundColor = UIColor.clear
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsetsMake(10, 12, 10, 7)
    textView.dataDetectorTypes = .all
    textView.textColor = UIColor.darkText
    textView.linkTextAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
 
    return textView
  }()
  
  override func setupViews() {
    
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textView)
    bubbleView.image = BaseMessageCell.grayBubbleImage
    bubbleView.frame.origin = CGPoint(x: 10, y: 0)
  }
}
