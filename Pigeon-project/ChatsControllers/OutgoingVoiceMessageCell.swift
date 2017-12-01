//
//  OutgoingVoiceMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation

class OutgoingVoiceMessageCell: BaseMessageCell {
  
  var playerView: PlayerCellView = {
    var playerView = PlayerCellView()
    playerView.alpha = 1
    playerView.backgroundColor = .clear
    playerView.play.setImage(UIImage(named: "pause"), for: .selected)
    playerView.play.setImage(UIImage(named: "play"), for: .normal)
    playerView.play.isSelected = false
    playerView.timerLabel.text = "00:00:00"
    playerView.startingTime = 0
    playerView.seconds = 0
    
    return playerView
  }()
    
  override func setupViews() {
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(playerView)
    contentView.addSubview(deliveryStatus)
    bubbleView.image = blueBubbleImage
    bubbleView.frame.size.width = 150
    playerView.playLeadingAnchor.constant = 12
    playerView.timerLabel.font = UIFont.systemFont(ofSize: 12)
    setCellSize()
  }
  
  override func prepareViewsForReuse() {
    setCellSize()
    playerView.timerLabel.text = "00:00:00"
    playerView.seconds = 0
    playerView.startingTime = 0
    playerView.play.isSelected = false
  }
  
  fileprivate func setCellSize() {
    bubbleView.frame.origin = CGPoint(x: (frame.width - 160).rounded(), y: 0)
    bubbleView.frame.size.height = frame.size.height.rounded()
    playerView.frame.size = CGSize(width: (bubbleView.frame.width).rounded(),
                                   height:(bubbleView.frame.height).rounded())
    deliveryStatus.frame = CGRect(x: frame.width - 80, y: bubbleView.frame.height + 2, width: 70, height: 10).integral
  }
}
