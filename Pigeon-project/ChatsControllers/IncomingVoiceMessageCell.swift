//
//  IncomingVoiceMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation

class IncomingVoiceMessageCell: BaseMessageCell {
  
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
    bubbleView.image = BaseMessageCell.grayBubbleImage
    bubbleView.frame.origin = CGPoint(x: 10, y: 0)
    bubbleView.frame.size.width = 200
  }
  
  override func prepareViewsForReuse() {
    playerView.seconds = 0
    playerView.startingTime = 0
    playerView.play.setImage(UIImage(named: "play"), for: .normal)
    playerView.play.setImage(UIImage(named: "pause"), for: .selected)
    playerView.play.isSelected = false
  }
}
