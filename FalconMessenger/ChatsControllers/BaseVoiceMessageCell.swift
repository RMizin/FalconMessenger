//
//  BaseVoiceMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 4/6/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class BaseVoiceMessageCell: BaseMessageCell {
  
  lazy var playerView: CellPlayerView = {
    var playerView = CellPlayerView()
    playerView.alpha = 1
    playerView.backgroundColor = .clear
    
    return playerView
  }()
  
  override func prepareForReuse() {
    super.prepareForReuse()
    playerView.play.isSelected = false
    playerView.resetTimer()
  }
}
