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
    button.addTarget(self, action: #selector(handleZoomTap(_:)), for: .touchUpInside)
    
    return button
  }()
  
  lazy var messageImageView: UIImageView = {
    let messageImageView = UIImageView()
    messageImageView.translatesAutoresizingMaskIntoConstraints = false
    messageImageView.layer.cornerRadius = 15
    messageImageView.layer.masksToBounds = true
    messageImageView.isUserInteractionEnabled = true
    messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
    
    return messageImageView
  }()
  
  lazy var progressView: CircleProgress = {
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
    let options: SDWebImageOptions = [.continueInBackground, .lowPriority, .scaleDownLargeImages]
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

  @objc func handleZoomTap(_ tapGesture: UITapGestureRecognizer) {
    guard let indexPath = chatLogController?.collectionView.indexPath(for: self) else { return }
    self.chatLogController?.handleOpen(madiaAt: indexPath)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    playButton.isHidden = true
    messageImageView.sd_cancelCurrentImageLoad()
    messageImageView.image = nil
    timeLabel.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    timeLabel.textColor = ThemeManager.currentTheme().generalTitleColor
  }
}
