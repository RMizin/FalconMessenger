//
//  CellPlayerView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/31/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class CellPlayerView: PlayerView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    play.setImage(UIImage(named: "play"), for: .normal)
    play.setImage(UIImage(named: "pause"), for: .selected)
    
    playWidthAnchor.constant = 34
    playHeightAnchor.constant = 34
    timerLabel.font = MessageFontsAppearance.defaultVoiceMessageTextFont
    timerLabel.textAlignment = .right
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
