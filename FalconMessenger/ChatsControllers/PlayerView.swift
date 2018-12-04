//
//  PlayerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


class PlayerView: UIView {
  
  var startingTime = Int()
  var seconds = Int()
  var timer:Timer? = Timer()
  
  var play: UIButton = {
    var play = UIButton()
    play.translatesAutoresizingMaskIntoConstraints = false
    play.imageView?.contentMode = .scaleAspectFit

    return play
  }()
  
  var timerLabel: UILabel = {
    var timerLabel = UILabel()
    timerLabel.translatesAutoresizingMaskIntoConstraints = false
    timerLabel.textColor = .white
    timerLabel.text = "00:00:00"
    timerLabel.textAlignment = .center
    timerLabel.font = UIFont.systemFont(ofSize: 13)
    
    return timerLabel
  }()
  
  var playLeadingAnchor: NSLayoutConstraint!
  var playWidthAnchor: NSLayoutConstraint!
  var playHeightAnchor: NSLayoutConstraint!
  var timelabelLeadingAnchor: NSLayoutConstraint!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    layer.cornerRadius = 5.0
    backgroundColor = .black
    alpha = 0.85
    addSubview(play)
    addSubview(timerLabel)
    playLeadingAnchor = play.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3)
    playLeadingAnchor.isActive = true
    playWidthAnchor = play.widthAnchor.constraint(equalToConstant: 0)
    playWidthAnchor.isActive = true
    playHeightAnchor = play.heightAnchor.constraint(equalTo: heightAnchor, constant: 0)
    playHeightAnchor.isActive = true
    
    timelabelLeadingAnchor = timerLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
    timelabelLeadingAnchor.isActive = true
    
    play.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    
    NSLayoutConstraint.activate([
      timerLabel.centerYAnchor.constraint(equalTo: play.centerYAnchor),
      timerLabel.heightAnchor.constraint(equalTo: play.heightAnchor),
      timerLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func runTimer() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: 1, target: self,  selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
		RunLoop.main.add(timer!, forMode: RunLoop.Mode.common)
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
  
  func timeString(time: TimeInterval) -> String {
    let hours = Int(time) / 3600
    let minutes = Int(time) / 60 % 60
    let seconds = Int(time) % 60
    return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
  }
}
