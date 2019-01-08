//
//  IncomingVoiceMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation

class IncomingVoiceMessageCell: BaseVoiceMessageCell {

  override func setupViews() {
    super.setupViews()
    bubbleView.addSubview(playerView)
    bubbleView.addSubview(nameLabel)
    bubbleView.addSubview(timeLabel)
    bubbleView.frame.origin = BaseMessageCell.incomingBubbleOrigin
    bubbleView.frame.size.width = 150
    timeLabel.backgroundColor = .clear
    timeLabel.textColor = UIColor.darkGray.withAlphaComponent(0.7)
    playerView.timerLabel.textColor = ThemeManager.currentTheme().incomingBubbleTextColor
    bubbleView.tintColor = ThemeManager.currentTheme().incomingBubbleTintColor
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    bubbleView.tintColor = ThemeManager.currentTheme().incomingBubbleTintColor
    playerView.timerLabel.textColor = ThemeManager.currentTheme().incomingBubbleTextColor
  }
  
  func setupData(message: Message, isGroupChat: Bool) {
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.sizeToFit()
      bubbleView.frame.size.height = frame.size.height.rounded()
      playerView.frame = CGRect(x: 10, y: 20, width: bubbleView.frame.width-20,
                                height: bubbleView.frame.height-BaseMessageCell.messageTimeHeight-15).integral
      
      if nameLabel.frame.size.width >= BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth {
        nameLabel.frame.size.width = playerView.frame.size.width - 24
      }
    } else {
      bubbleView.frame.size.height = frame.size.height.rounded()
      playerView.frame = CGRect(x: 7, y: 14, width: bubbleView.frame.width-17,
                                height: bubbleView.frame.height-BaseMessageCell.messageTimeHeight-19).integral
    }
    
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width-1,
                                     y: bubbleView.frame.height-timeLabel.frame.height-5)
    timeLabel.text = message.convertedTimestamp
    guard message.voiceEncodedString != nil else { return }

    playerView.timerLabel.text = message.voiceDuration
    playerView.startingTime = message.voiceStartTime.value ?? 0
    playerView.seconds = message.voiceStartTime.value ?? 0
    
    if let isCrooked = message.isCrooked.value, isCrooked {
      bubbleView.image = ThemeManager.currentTheme().incomingBubble
    } else {
      bubbleView.image = ThemeManager.currentTheme().incomingPartialBubble
    }
  }
}
