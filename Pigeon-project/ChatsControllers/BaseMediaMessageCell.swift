//
//  BaseMediaMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

class BaseMediaMessageCell: BaseMessageCell {
  
  lazy var playButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(named: "play")
    button.isHidden = true
    button.setImage(image, for: .normal)
    button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
    
    return button
  }()
  
  lazy var messageImageView: UIImageView = {
    let messageImageView = UIImageView()
    messageImageView.translatesAutoresizingMaskIntoConstraints = false
    messageImageView.layer.cornerRadius = 15
    messageImageView.layer.masksToBounds = true
    messageImageView.isUserInteractionEnabled = true
    messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(handleZoomTap)))
    
    return messageImageView
  }()
  
  var progressView: CircleProgress = {
    let progressView = CircleProgress()
    progressView.translatesAutoresizingMaskIntoConstraints = false
    
    return progressView
  }()
  
  func setupImageFromLocalData(message: Message, image: UIImage) {
    messageImageView.image = image
    progressView.isHidden = true
    messageImageView.isUserInteractionEnabled = true
    playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
  }
  
  func setupImageFromURL(message: Message, messageImageUrl: URL) {
    progressView.startLoading()
    progressView.isHidden = false
    let options:SDWebImageOptions = [.continueInBackground, .lowPriority, .scaleDownLargeImages]
    messageImageView.sd_setImage(with: messageImageUrl, placeholderImage: nil, options: options, progress: { (_, _, _) in
      
      DispatchQueue.main.async {
        self.progressView.progress = self.messageImageView.sd_imageProgress.fractionCompleted
      }
      
    }, completed: { (_, error, _, _) in
      
      if error != nil {
        self.progressView.isHidden = false
        self.messageImageView.isUserInteractionEnabled = false
        self.playButton.isHidden = true
        return
      }
      self.progressView.isHidden = true
      self.messageImageView.isUserInteractionEnabled = true
      self.playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
    })
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
    guard let indexPath = chatLogController?.collectionView?.indexPath(for: self) else { return }
    self.chatLogController?.openSelectedPhoto(at: indexPath)
  }    
}
