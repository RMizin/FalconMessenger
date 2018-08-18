//
//  IncomingPhotoMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


class IncomingPhotoMessageCell: BaseMediaMessageCell {
  

  var messageImageViewTopAnchor: NSLayoutConstraint!
  override func setupViews() {
    
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    
    contentView.addSubview(bubbleView)
    
    bubbleView.addSubview(messageImageView)
    
    bubbleView.addSubview(nameLabel)
    
    bubbleView.frame.origin = CGPoint(x: 10, y: 0)
    
    bubbleView.frame.size.width = 200
    
    progressView.strokeColor = .black
   
    bubbleView.image = grayBubbleImage

    messageImageViewTopAnchor = messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4)
    messageImageViewTopAnchor.isActive = true

    messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4).isActive = true
    messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 9).isActive = true
    messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -4).isActive = true
    
    bubbleView.addSubview(playButton)
    playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
    playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

    bubbleView.addSubview(progressView)
    progressView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    progressView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    progressView.widthAnchor.constraint(equalToConstant: 60).isActive = true
    progressView.heightAnchor.constraint(equalToConstant: 60).isActive = true
  }
  
  func setupData(message: Message, isGroupChat: Bool) {
    self.message = message
    bubbleView.frame.size.height = frame.size.height.rounded()
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.frame.size.height = 10
      nameLabel.sizeToFit()
      nameLabel.frame.origin = CGPoint(x: BaseMessageCell.incomingTextViewLeftInset+5, y: BaseMessageCell.incomingTextViewTopInset)
      messageImageViewTopAnchor.constant = 34
      if nameLabel.frame.size.width >= 170 {
        nameLabel.frame.size.width = 170
      }
    }
    messageImageView.isUserInteractionEnabled = false
    setupTimestampView(message: message, isOutgoing: false)
  }

  override func prepareViewsForReuse() {
     super.prepareViewsForReuse()
    bubbleView.image = grayBubbleImage
    playButton.isHidden = true
    messageImageView.sd_cancelCurrentImageLoad()
    messageImageView.image = nil
    messageImageViewTopAnchor.constant = 4
  }
}
