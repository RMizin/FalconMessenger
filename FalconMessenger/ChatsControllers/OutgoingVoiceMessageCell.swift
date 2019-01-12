//
//  OutgoingVoiceMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation

class OutgoingVoiceMessageCell: BaseVoiceMessageCell {
  
  override func setupViews() {
    super.setupViews()
    bubbleView.addSubview(playerView)
    contentView.addSubview(deliveryStatus)
		addSubview(resendButton)
    bubbleView.addSubview(timeLabel)
    bubbleView.frame.size.width = 150
    playerView.timerLabel.textColor = ThemeManager.currentTheme().outgoingBubbleTextColor
    timeLabel.backgroundColor = .clear
    timeLabel.textColor = UIColor.white.withAlphaComponent(0.7)
    bubbleView.tintColor = ThemeManager.currentTheme().outgoingBubbleTintColor
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    bubbleView.tintColor = ThemeManager.currentTheme().outgoingBubbleTintColor
    playerView.timerLabel.textColor = ThemeManager.currentTheme().outgoingBubbleTextColor
  }
  
  func setupData(message: Message) {
		resendButtonFrame(message: message)
    let x = (frame.width - bubbleView.frame.size.width - BaseMessageCell.scrollIndicatorInset).rounded()
    bubbleView.frame.origin = CGPoint(x: x - resendButtonWidth(), y: 0)
    bubbleView.frame.size.height = frame.size.height.rounded()
    playerView.frame = CGRect(x: 3, y: 14, width: bubbleView.frame.width-17,
                              height: bubbleView.frame.height-BaseMessageCell.messageTimeHeight-19).integral
    playerView.timerLabel.text = message.voiceDuration
    playerView.startingTime = message.voiceStartTime.value ?? 0
    playerView.seconds = message.voiceStartTime.value ?? 0
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width-5,
                                     y: bubbleView.frame.height-timeLabel.frame.height-5)
    timeLabel.text = message.convertedTimestamp
    guard message.voiceEncodedString != nil else { return }
  
    if let isCrooked = message.isCrooked.value, isCrooked {
      bubbleView.image = ThemeManager.currentTheme().outgoingBubble
    } else {
      bubbleView.image = ThemeManager.currentTheme().outgoingPartialBubble
    }
  }
}
