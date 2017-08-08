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
    textView.font = UIFont.systemFont(ofSize: 14)
    textView.backgroundColor = UIColor.clear
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsetsMake(10, 12, 10, 7)
    textView.dataDetectorTypes = .all
    textView.textColor = UIColor.darkText
    textView.linkTextAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
    textView.translatesAutoresizingMaskIntoConstraints = false
    return textView
  }()
  
  override func setupViews() {
    
    addSubview(bubbleView)
    bubbleView.addSubview(textView)
    bubbleView.addSubview(deliveryStatus)
    bubbleView.image = BaseMessageCell.grayBubbleImage
    
//    textView.frame.size = CGSize(width: bubbleView.frame.width,
//                                 height: bubbleView.frame.height)
    
  
    NSLayoutConstraint.activate([
      
      textView.topAnchor.constraint(equalTo: bubbleView.topAnchor),
      textView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
      textView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
      
      deliveryStatus.topAnchor.constraint(equalTo: bottomAnchor),
      deliveryStatus.heightAnchor.constraint(equalToConstant: 20),
      deliveryStatus.rightAnchor.constraint(equalTo: rightAnchor, constant: -10)
      ])
  }
  
  override func prepareViewsForReuse() {
   // textView.text = nil
   // bubbleView.image = nil
  }
    
}
