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
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(playerView)
    bubbleView.addSubview(nameLabel)
    bubbleView.addSubview(timeLabel)
    bubbleView.frame.origin = BaseMessageCell.incomingBubbleOrigin
    bubbleView.frame.size.width = 150
    playerView.timerLabel.textColor = .black
    timeLabel.backgroundColor = .clear
    timeLabel.textColor = .black
  }
  
  func setupData(message: Message, isGroupChat:Bool) {
    self.message = message
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.sizeToFit()
      bubbleView.frame.size.height = frame.size.height.rounded()
      playerView.frame = CGRect(x: 10, y: 20, width: bubbleView.frame.width-20, height: bubbleView.frame.height-BaseMessageCell.messageTimeHeight-15)
      
      if nameLabel.frame.size.width >= BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth {
        nameLabel.frame.size.width = playerView.frame.size.width - 24
      }
    } else {
      bubbleView.frame.size.height = frame.size.height.rounded()
      playerView.frame = CGRect(x: 5, y: 10, width: bubbleView.frame.width-15, height: bubbleView.frame.height-BaseMessageCell.messageTimeHeight-15)
    }
    
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width-1, y: bubbleView.frame.height-timeLabel.frame.height-5)
    timeLabel.text = self.message?.convertedTimestamp
    guard message.voiceEncodedString != nil else { return }

    playerView.timerLabel.text = message.voiceDuration
    playerView.startingTime = message.voiceStartTime ?? 0
    playerView.seconds = message.voiceStartTime ?? 0
    
    if let isCrooked = self.message?.isCrooked, isCrooked {
      bubbleView.image = ThemeManager.currentTheme().incomingBubble
    } else {
      bubbleView.image = ThemeManager.currentTheme().incomingPartialBubble
    }
  }
  
  override func prepareViewsForReuse() {
    playerView.seconds = 0
    playerView.startingTime = 0
    playerView.play.isSelected = false
    bubbleView.image = nil
    nameLabel.text = ""
  }
}
