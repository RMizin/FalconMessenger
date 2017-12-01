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
  var timer:Timer? = Timer()
  
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
    timerLabel.text = "00:00:00"
    timerLabel.textAlignment = .center
    timerLabel.font = UIFont.systemFont(ofSize: 10)
    
    return timerLabel
  }()
  
  var playLeadingAnchor: NSLayoutConstraint!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    layer.cornerRadius = 5.0
    backgroundColor = .black
    alpha = 0.7
    addSubview(play)
    addSubview(timerLabel)
    playLeadingAnchor = play.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3)
    playLeadingAnchor.isActive = true
    NSLayoutConstraint.activate([
    
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
  
  
  func runTimer() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: 1, target: self,  selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
  }
  
  @objc func updateTimer() {
    if seconds < 1 {
      resetTimer()
    } else {
      seconds -= 1
      timerLabel.text = timeString(time: TimeInterval(seconds))
    }
  }
  
  func resetTimer() {
    play.isSelected = false
    timer?.invalidate()
    seconds = startingTime
    
    timerLabel.text = timeString(time: TimeInterval(seconds))
  }
  
  func timeString(time:TimeInterval) -> String {
    let hours = Int(time) / 3600
    let minutes = Int(time) / 60 % 60
    let seconds = Int(time) % 60
    return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
  }
}

