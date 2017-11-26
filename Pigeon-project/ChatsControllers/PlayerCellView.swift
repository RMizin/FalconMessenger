//
//  PlayerCellView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


class PlayerCellView: UIView {
  
  var startingTime = Int()
  var seconds = Int()
  var timer = Timer()
  
  var play: UIButton = {
    var play = UIButton()
    play.translatesAutoresizingMaskIntoConstraints = false
    play.setImage(UIImage(named: "play"), for: .normal)
    play.imageView?.contentMode = .scaleAspectFit
   
    return play
  }()
  
  var timerLabel: UILabel = {
    var timerLabel = UILabel()
    timerLabel.translatesAutoresizingMaskIntoConstraints = false
    timerLabel.textColor = .white
    timerLabel.text = "00:00"
    timerLabel.textAlignment = .center
    timerLabel.font = UIFont.systemFont(ofSize: 10)
    
    return timerLabel
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    layer.cornerRadius = 5.0
    backgroundColor = .black
    alpha = 0.7
    
    addSubview(play)
    addSubview(timerLabel)
    
    NSLayoutConstraint.activate([
      play.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
      play.centerYAnchor.constraint(equalTo: centerYAnchor),
      play.widthAnchor.constraint(equalToConstant: 20),
      play.heightAnchor.constraint(equalTo: heightAnchor, constant: -5),
      
      timerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      timerLabel.heightAnchor.constraint(equalTo: heightAnchor),
      timerLabel.leadingAnchor.constraint(equalTo: play.trailingAnchor),
      timerLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
      ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

