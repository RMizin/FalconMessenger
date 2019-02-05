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
		textView.textColor = .darkText
		textView.textContainerInset = UIEdgeInsets(top: incomingTextViewTopInset,
																							 left: incomingTextViewLeftInset,
																							 bottom: incomingTextViewBottomInset,
																							 right: incomingTextViewRightInset)
    return textView
  }()

  
  func setupData(message: Message, isGroupChat: Bool) {
    
    self.message = message
    guard let messageText = message.text else { return }
    textView.text = messageText
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.frame.size.height = 10
      nameLabel.sizeToFit()
      nameLabel.frame.origin = CGPoint(x: textView.textContainerInset.left+5, y: textView.textContainerInset.top)
      
      if message.estimatedFrameForText!.width < nameLabel.frame.size.width {
        if nameLabel.frame.size.width >= 170 {
          nameLabel.frame.size.width = 170
          bubbleView.frame.size = CGSize(width: 200, height: frame.size.height.rounded())
        } else {
          bubbleView.frame.size = CGSize(width: (nameLabel.frame.size.width + 30).rounded(), height: frame.size.height.rounded())
        }
      } else {
        bubbleView.frame.size = CGSize(width: (message.estimatedFrameForText!.width + 30).rounded(), height: frame.size.height.rounded())
      }

      textView.textContainerInset.top = 25
      textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: bubbleView.frame.height.rounded())

    } else {
      bubbleView.frame.size = CGSize(width: (message.estimatedFrameForText!.width + 30).rounded(), height: frame.size.height.rounded())
      textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: bubbleView.frame.height.rounded())
    }
    setupTimestampView(message: message, isOutgoing: false)
  }

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
		textView.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 7)
  }
}
