//
//  VoiceRecordingContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class VoiceRecordingContainerView: UIView {
  
  var recordButton: UIButton = {
    var recordButton = UIButton()
		recordButton.translatesAutoresizingMaskIntoConstraints = false
		recordButton.setTitle("Record", for: .normal)

    return recordButton
  }()
  
  var stopButton: UIButton = {
    var stopButton = UIButton()
     stopButton.translatesAutoresizingMaskIntoConstraints = false
		 stopButton.setTitleColor(UIColor.red, for: .normal)
     stopButton.setTitle("Stop", for: .normal)
    
    return stopButton
  }()
  
  var statusLabel: UILabel = {
     var statusLabel = UILabel()
     statusLabel.text = "00:00:00"
     statusLabel.textColor = ThemeManager.currentTheme().generalTitleColor
     statusLabel.translatesAutoresizingMaskIntoConstraints = false
    
    return statusLabel
  }()
  
  var waveForm: WaveformView = {
    var waveForm = WaveformView()
    waveForm.translatesAutoresizingMaskIntoConstraints = false
    waveForm.amplitude = 0.0
    waveForm.backgroundColor = .clear
    
    return waveForm
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

		recordButton.setTitleColor(ThemeManager.currentTheme().tintColor, for: .normal)

    addSubview(recordButton)
    addSubview(stopButton)
    addSubview(statusLabel)
    addSubview(waveForm)
    
    recordButton.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
    recordButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
    recordButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    stopButton.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
    stopButton.leftAnchor.constraint(equalTo: recordButton.rightAnchor, constant: 10).isActive = true
    stopButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
    stopButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

    statusLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
   // statusLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
    statusLabel.widthAnchor.constraint(equalToConstant: 75).isActive = true
    statusLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
 
    waveForm.topAnchor.constraint(equalTo: recordButton.bottomAnchor).isActive = true
    
    if #available(iOS 11.0, *) {
      recordButton.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
      statusLabel.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
      waveForm.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
      waveForm.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
      waveForm.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
    } else {
      recordButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
      statusLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
      waveForm.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
      waveForm.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
      waveForm.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
