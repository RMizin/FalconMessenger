//
//  PhotoMessageCell.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class PhotoMessageCell: BaseMediaMessageCell {

  override func setupViews() {
    
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(messageImageView)
    bubbleView.frame.size.width = BaseMessageCell.mediaMaxWidth
    progressView.strokeColor = .white
    
    contentView.addSubview(deliveryStatus)
    messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0).isActive = true
    messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0).isActive = true
    messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0).isActive = true
    messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -5).isActive = true
    
    bubbleView.addSubview(playButton)
    playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
    playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    bubbleView.addSubview(progressView)
    progressView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    progressView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    progressView.widthAnchor.constraint(equalToConstant: 60).isActive = true
    progressView.heightAnchor.constraint(equalToConstant: 60).isActive = true
    
    bubbleView.addSubview(timeLabel)
  }
  
  func setupData(message: Message) {
    self.message = message
    let x = (frame.width - bubbleView.frame.size.width - BaseMessageCell.scrollIndicatorInset).rounded()
    bubbleView.frame.origin = CGPoint(x: x, y: 0)
    bubbleView.frame.size.height = frame.size.height.rounded()
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width-10, y: bubbleView.frame.height-timeLabel.frame.height-5)
    timeLabel.text = self.message?.convertedTimestamp
    messageImageView.isUserInteractionEnabled = false
    bubbleView.image = ThemeManager.currentTheme().outgoingPartialBubble
  }

  override func prepareViewsForReuse() {
     super.prepareViewsForReuse()
    bubbleView.image = nil
    playButton.isHidden = true
    messageImageView.sd_cancelCurrentImageLoad()
    messageImageView.image = nil
    timeLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    timeLabel.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
  }
}
