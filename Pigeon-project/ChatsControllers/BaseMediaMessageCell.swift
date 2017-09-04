//
//  BaseMediaMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation


class BaseMediaMessageCell: BaseMessageCell {
  
  var message: Message?
  
  weak var chatLogController: ChatLogController?
  
  var playerLayer: AVPlayerLayer?
  
  var player: AVPlayer?
  
  let activityIndicatorView: UIActivityIndicatorView = {
    let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    aiv.translatesAutoresizingMaskIntoConstraints = false
    aiv.hidesWhenStopped = true
    
    return aiv
  }()
  
  lazy var playButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(named: "play")
    button.tintColor = UIColor.white
    button.setImage(image, for: UIControlState())
    button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
    
    return button
  }()
  
  lazy var messageImageView: UIImageView = {
    let messageImageView = UIImageView()
    messageImageView.translatesAutoresizingMaskIntoConstraints = false
    messageImageView.layer.cornerRadius = 15
    messageImageView.layer.masksToBounds = true
    messageImageView.contentMode = .scaleAspectFill
    messageImageView.isUserInteractionEnabled = true
    messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(handleZoomTap)))
    
    return messageImageView
  }()
  
  var progressView: CircleProgressView = {
    let progressView = CircleProgressView()
    progressView.trackWidth = 4
    progressView.backgroundColor = .clear
    progressView.centerFillColor = .clear
    progressView.trackBackgroundColor = .clear
    progressView.translatesAutoresizingMaskIntoConstraints = false
    
    return progressView
  }()

  override func prepareForReuse() {
    super.prepareForReuse()
    
    playerLayer?.removeFromSuperlayer()
    player?.pause()
    activityIndicatorView.stopAnimating()
    messageImageView.image = nil

  }
  
  
  func handlePlay() {
    if let videoUrlString = message?.videoUrl, let url = URL(string: videoUrlString) {
      player = AVPlayer(url: url)
      
      playerLayer = AVPlayerLayer(player: player)
      playerLayer?.frame = bubbleView.bounds
      bubbleView.layer.addSublayer(playerLayer!)
      
      player?.play()
      activityIndicatorView.startAnimating()
      playButton.isHidden = true
    }
  }
  
  
  func handleZoomTap(_ tapGesture: UITapGestureRecognizer) {
    if message?.videoUrl != nil {
      return
    }
    
    if let imageView = tapGesture.view as? UIImageView {
      //PRO Tip: don't perform a lot of custom logic inside of a view class
      self.chatLogController?.performZoomInForStartingImageView(imageView)
    }
  }

    
}
