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
    bubbleView.frame.origin = BaseMessageCell.incomingBubbleOrigin
    bubbleView.frame.size.width = 150
    playerView.playLeadingAnchor.constant = 15
    playerView.playWidthAnchor.constant = 20
    playerView.playHeightAnchor.constant = -5
    playerView.timelabelLeadingAnchor.constant = playerView.playWidthAnchor.constant + playerView.playLeadingAnchor.constant
    playerView.timerLabel.font = MessageFontsAppearance.defaultVoiceMessageTextFont
    playerView.play.setImage(UIImage(named: "pauseBlack"), for: .selected)
    playerView.play.setImage(UIImage(named: "playBlack"), for: .normal)
    playerView.timerLabel.textColor = .black
  }
  
  func setupData(message: Message, isGroupChat:Bool) {
    self.message = message
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.sizeToFit()
      playerView.frame.origin.y = 20
      bubbleView.frame.size.height = frame.size.height.rounded()
      playerView.frame.size = CGSize(width: (bubbleView.frame.width).rounded(), height: (bubbleView.frame.height - 20).rounded())
      
      if nameLabel.frame.size.width >= BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth {
        nameLabel.frame.size.width = playerView.frame.size.width - 24
      }
    } else {
      bubbleView.frame.size.height = frame.size.height.rounded()
      playerView.frame.size = CGSize(width: (bubbleView.frame.width).rounded(), height:(bubbleView.frame.height).rounded())
    }
  
    setupTimestampView(message: message, isOutgoing: false)
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
    playerView.play.setImage(UIImage(named: "pauseBlack"), for: .selected)
    playerView.play.setImage(UIImage(named: "playBlack"), for: .normal)
    playerView.play.isSelected = false
    bubbleView.image = nil
    nameLabel.text = ""
  }
}
