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
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(playerView)
    contentView.addSubview(deliveryStatus)
    bubbleView.addSubview(timeLabel)
    bubbleView.frame.size.width = 150
    playerView.timerLabel.textColor = .white
    timeLabel.backgroundColor = .clear
    timeLabel.textColor = .white
  }
  
  func setupData(message: Message) {
    self.message = message
    let x = (frame.width - bubbleView.frame.size.width - BaseMessageCell.scrollIndicatorInset).rounded()
    bubbleView.frame.origin = CGPoint(x: x, y: 0)
    bubbleView.frame.size.height = frame.size.height.rounded()
    playerView.frame = CGRect(x: 1, y: 10, width: bubbleView.frame.width-15, height: bubbleView.frame.height-BaseMessageCell.messageTimeHeight-15)
    playerView.timerLabel.text = message.voiceDuration
    playerView.startingTime = message.voiceStartTime ?? 0
    playerView.seconds = message.voiceStartTime ?? 0
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width-5, y: bubbleView.frame.height-timeLabel.frame.height)
    timeLabel.text = self.message?.convertedTimestamp
    guard message.voiceEncodedString != nil else { return }
  
    if let isCrooked = self.message?.isCrooked, isCrooked {
      bubbleView.image = ThemeManager.currentTheme().outgoingBubble
    } else {
      bubbleView.image = ThemeManager.currentTheme().outgoingPartialBubble
    }
  }
  
  override func prepareViewsForReuse() {
    playerView.timerLabel.text = "00:00:00"
    playerView.seconds = 0
    playerView.startingTime = 0
    playerView.play.isSelected = false
    bubbleView.image = nil
  }
}
