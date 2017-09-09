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
  
    contentView.addSubview(bubbleView)
    
    bubbleView.addSubview(messageImageView)
    
    bubbleView.frame.origin = CGPoint(x: (frame.width - 210).rounded(), y: 0)
    
    bubbleView.frame.size.width = 200
    
    
    bubbleView.image = BaseMessageCell.blueBubbleImage
    
    progressView.trackFillColor = .white
    
    progressView.trackBorderColor = .white
    
    progressView.trackBorderWidth = 2
    
    contentView.addSubview(deliveryStatus)

    messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4).isActive = true
    messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4).isActive = true
    messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 4).isActive = true
    messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -9).isActive = true
    
    bubbleView.addSubview(playButton)
    playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
    playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    bubbleView.addSubview(progressView)
    progressView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    progressView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    progressView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    progressView.heightAnchor.constraint(equalToConstant: 100).isActive = true

  }
}
