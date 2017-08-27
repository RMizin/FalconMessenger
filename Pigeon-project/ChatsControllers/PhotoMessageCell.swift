//
//  PhotoMessageCell.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit
import AVFoundation

class PhotoMessageCell: BaseMessageCell {
  
  var message: Message?
  
  var chatLogController: ChatLogController?
  
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
    progressView.translatesAutoresizingMaskIntoConstraints = false
  //  progressView.isHidden = true
 //   progressView.trackFillColor = .clear
    progressView.trackWidth = 4
    progressView.backgroundColor = .clear
    progressView.centerFillColor = .clear
    progressView.trackBackgroundColor = .clear
   
   // progressView.trackBackgroundC
    
    
  
    return progressView
  }()
  
  
  override func setupViews() {
  
  contentView.addSubview(bubbleView)
    bubbleView.addSubview(messageImageView)
    messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
    messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
    messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
    messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
    
    bubbleView.addSubview(playButton)
    playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
    playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    bubbleView.addSubview(activityIndicatorView)
    activityIndicatorView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    activityIndicatorView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    activityIndicatorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
    activityIndicatorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    contentView.addSubview(deliveryStatus)
    
    bubbleView.addSubview(progressView)
    progressView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    progressView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    progressView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    progressView.heightAnchor.constraint(equalToConstant: 100).isActive = true
    
  
  }
  
  
  override func prepareViewsForReuse() {
    playerLayer?.removeFromSuperlayer()
    player?.pause()
    activityIndicatorView.stopAnimating()
    messageImageView.image = nil
    bubbleView.image = nil
 
    
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
