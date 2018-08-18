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
    bubbleView.image = blueBubbleImage
    bubbleView.frame.size.width = 150
    playerView.playLeadingAnchor.constant = 12
    playerView.playWidthAnchor.constant = 20
    playerView.playHeightAnchor.constant = -5
    playerView.timelabelLeadingAnchor.constant = playerView.playWidthAnchor.constant + playerView.playLeadingAnchor.constant
    playerView.timerLabel.font = UIFont.systemFont(ofSize: 12)
    playerView.play.setImage(UIImage(named: "pause"), for: .selected)
    playerView.play.setImage(UIImage(named: "playWhite"), for: .normal)
    playerView.timerLabel.textColor = .white
  }

  func setupData(message: Message) {
    self.message = message
    bubbleView.frame.origin = CGPoint(x: (frame.width - 160).rounded(), y: 0)
    bubbleView.frame.size.height = frame.size.height.rounded()
    playerView.frame.size = CGSize(width: (bubbleView.frame.width).rounded(), height: ( bubbleView.frame.height).rounded())

    setupTimestampView(message: message, isOutgoing: true)
    guard message.voiceEncodedString != nil else { return }
    playerView.timerLabel.text = message.voiceDuration
    playerView.startingTime = message.voiceStartTime ?? 0
    playerView.seconds = message.voiceStartTime ?? 0
  }

  override func prepareViewsForReuse() {
    playerView.timerLabel.text = "00:00:00"
    playerView.seconds = 0
    playerView.startingTime = 0
    playerView.play.isSelected = false
    bubbleView.image = blueBubbleImage
  }
}
