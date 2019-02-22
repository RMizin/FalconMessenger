//
//  VerificationContainerView+Timer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/24/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

extension VerificationContainerView {

  typealias CompletionHandler = (_ success: Bool) -> Void

  func runTimer() {
    resend.isEnabled = false
    timerLabel.isHidden = false
    timer = Timer.scheduledTimer(timeInterval: 1,
                                 target: self,
                                 selector: (#selector(updateTimer)),
                                 userInfo: nil,
                                 repeats: true)
  }
  
  @objc func updateTimer() {
    if seconds < 1 {
      resetTimer()
      timerLabel.isHidden = true
      resend.isEnabled = true
    } else {
      seconds -= 1
      timerLabel.text =  "The message has been sent!\nYou can try again in \(timeString(time: TimeInterval(seconds)))"
    }
  }

  func resetTimer() {
    timer.invalidate()
    seconds = 120
    timerLabel.text =  "The message has been sent!\nYou can try again in \(timeString(time: TimeInterval(seconds)))"
  }

  func timeString(time: TimeInterval) -> String {
    let hours = Int(time) / 3600
    let minutes = Int(time) / 60 % 60
    let seconds = Int(time) % 60
    return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
  }
}
