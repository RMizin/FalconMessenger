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
    super.setupViews()
    bubbleView.addSubview(messageImageView)
    bubbleView.addSubview(nameLabel)
    bubbleView.frame.origin = BaseMessageCell.incomingBubbleOrigin
    bubbleView.frame.size.width = BaseMessageCell.mediaMaxWidth
    bubbleView.tintColor = ThemeManager.currentTheme().incomingBubbleTintColor
    progressView.strokeColor = ThemeManager.currentTheme().incomingProgressStrokeColor

    messageImageViewTopAnchor = messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0)
    messageImageViewTopAnchor.isActive = true
    
    messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0).isActive = true
    messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 5.3).isActive = true
    messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -0.8).isActive = true
    
    bubbleView.addSubview(progressView)
    progressView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    progressView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    progressView.widthAnchor.constraint(equalToConstant: 60).isActive = true
    progressView.heightAnchor.constraint(equalToConstant: 60).isActive = true

		bubbleView.addSubview(playButton)
		playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
		playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
		playButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
		playButton.heightAnchor.constraint(equalToConstant: 60).isActive = true

		bubbleView.addSubview(loadButton)
		loadButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
		loadButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
		loadButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
		loadButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
    
    bubbleView.addSubview(timeLabel)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    messageImageViewTopAnchor.constant = 0
    bubbleView.tintColor = ThemeManager.currentTheme().incomingBubbleTintColor
    progressView.strokeColor = ThemeManager.currentTheme().incomingProgressStrokeColor
  }
  
  func setupData(message: Message, isGroupChat: Bool) {
    bubbleView.frame.size.height = frame.size.height.rounded()
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width-5,
                                     y: bubbleView.frame.height-timeLabel.frame.height-5)

    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.sizeToFit()
      messageImageViewTopAnchor.constant = BaseMessageCell.incomingGroupMessageAuthorNameLabelHeight + BaseMessageCell.textViewTopInset
      if nameLabel.frame.size.width >= BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth {
        nameLabel.frame.size.width = BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth
      }
    }
    messageImageView.isUserInteractionEnabled = false
    timeLabel.text = message.convertedTimestamp
    bubbleView.image = ThemeManager.currentTheme().incomingPartialBubble
  }
}
