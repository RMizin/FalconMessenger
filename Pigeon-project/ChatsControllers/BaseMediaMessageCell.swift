//
//  BaseMediaMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class BaseMediaMessageCell: BaseMessageCell {
  
  weak var message: Message?
  
  weak var chatLogController: ChatLogController?
  
  lazy var playButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(named: "play")
    button.tintColor = UIColor.white
    button.isHidden = true
    button.setImage(image, for: UIControlState())
    button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
    
    return button
  }()
  
  lazy var messageImageView: UIImageView = {
    let messageImageView = UIImageView()
    messageImageView.translatesAutoresizingMaskIntoConstraints = false
    messageImageView.layer.cornerRadius = 15
    messageImageView.layer.masksToBounds = true
    //messageImageView.contentMode = .scaleAspectFill
    messageImageView.isUserInteractionEnabled = true
    
    messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(handleZoomTap)))
    
    return messageImageView
  }()
  
  var progressView: CircleProgressView = {
    let progressView = CircleProgressView()
    progressView.trackWidth = 5
    progressView.backgroundColor = .clear

    progressView.translatesAutoresizingMaskIntoConstraints = false
    
    return progressView
  }()

  
  override func prepareViewsForReuse() {
    
    messageImageView.image = nil
    playButton.isHidden = true
  }
  
  @objc func handlePlay() {
    
    var url: URL! = nil
    
    if message?.localVideoUrl != nil {
      let videoUrlString = message?.localVideoUrl
      url = URL(string: videoUrlString!)
      self.chatLogController?.performZoomInForVideo( url: url)
      return
    }
    
    if message?.videoUrl != nil {
      let videoUrlString = message?.videoUrl
      url =  URL(string: videoUrlString!)
      self.chatLogController?.performZoomInForVideo( url: url)
      return
    }
  }
  
  
  @objc func handleZoomTap(_ tapGesture: UITapGestureRecognizer) {
  
    if message?.videoUrl != nil || message?.localVideoUrl != nil {
      
     handlePlay()
      
      return
    }
    guard  let indexPath = chatLogController?.collectionView?.indexPath(for: self) else {
      return
    }
    self.chatLogController?.openSelectedPhoto(at: indexPath)
  }    
}
