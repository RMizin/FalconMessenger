//
//  BaseVoiceMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 4/6/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class BaseVoiceMessageCell: BaseMessageCell {
  
  var playerView: CellPlayerView = {
    var playerView = CellPlayerView()
    playerView.alpha = 1
    playerView.backgroundColor = .clear
    playerView.play.isSelected = false
    playerView.timerLabel.text = "00:00:00"
    playerView.startingTime = 0
    playerView.seconds = 0
    
    return playerView
  }()
  
  override func prepareViewsForReuse() {
    playerView.timerLabel.text = "00:00:00"
    playerView.seconds = 0
    playerView.startingTime = 0
    playerView.play.isSelected = false
  }
}
