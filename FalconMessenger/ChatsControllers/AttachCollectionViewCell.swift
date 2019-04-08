//
//  AttachCollectionViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation

class AttachCollectionViewCell: UICollectionViewCell {
  
  weak var chatInputContainerView: InputContainerView!
  var isHeightCalculated: Bool = false
  var playerViewHeightAnchor: NSLayoutConstraint!
  
  var isVideo = false {
    didSet {
      reloadAccessoryViews()
    }
  }
  
  var image: UIImageView = {
    var image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    image.contentMode = .scaleAspectFill
    image.layer.masksToBounds = true
    image.layer.cornerRadius = 10
    image.backgroundColor = .clear
    image.isUserInteractionEnabled = true
    
    return image
  }()
  
  var remove: UIButton = {
    var remove = UIButton()
    remove.translatesAutoresizingMaskIntoConstraints = false
    remove.setImage(UIImage(named: "remove"), for: .normal)
    remove.imageView?.contentMode = .scaleAspectFit
    remove.addTarget(self, action: #selector(InputContainerView.removeButtonDidTap), for: .touchUpInside)
   
    return remove
  }()
  
  let videoIndicatorView: UIImageView = {
    let videoIndicatorView = UIImageView(image: UIImage(named: "ImageCell-Video"))
    videoIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    videoIndicatorView.backgroundColor = .clear
    return videoIndicatorView
  }()
  
  var playerView: PlayerView = {
    var playerView = PlayerView()
    playerView.translatesAutoresizingMaskIntoConstraints = false
    return playerView
  }()
  

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap(_:)))
    addGestureRecognizer(longGesture)
    
    addSubview(image)
    addSubview(remove)
    addSubview(videoIndicatorView)
    addSubview(playerView)
    
    playerViewHeightAnchor = playerView.heightAnchor.constraint(equalToConstant: 0)
    playerViewHeightAnchor.isActive = true
    
    NSLayoutConstraint.activate([
      playerView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
      playerView.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
      playerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
      
      image.leftAnchor.constraint(equalTo: leftAnchor),
      image.topAnchor.constraint(equalTo: topAnchor),
      image.rightAnchor.constraint(equalTo: rightAnchor),
      image.bottomAnchor.constraint(equalTo: playerView.topAnchor, constant: -3),
    
      remove.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      remove.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
      remove.widthAnchor.constraint(equalToConstant: 30),
      remove.heightAnchor.constraint(equalToConstant: 30),
      
      videoIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
      videoIndicatorView.leftAnchor.constraint(equalTo: leftAnchor, constant: 4),
      videoIndicatorView.widthAnchor.constraint(equalToConstant: videoIndicatorView.image!.size.width),
      videoIndicatorView.heightAnchor.constraint(equalToConstant: videoIndicatorView.image!.size.height)
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    isVideo = false
    image.contentMode = .scaleAspectFill
    image.layer.borderColor = nil
    image.layer.borderWidth = 0
    playerViewHeightAnchor.constant = 0
  }
  
  override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    
    if !isHeightCalculated {
      
      self.setNeedsLayout()
      self.layoutIfNeeded()
      
      let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
      var newFrame = layoutAttributes.frame
      newFrame.size.width = CGFloat(ceilf(Float(size.width)))
      layoutAttributes.frame = newFrame
      isHeightCalculated = true
    }
    
    return layoutAttributes
  }

  @objc func longTap(_ gestureReconizer: UILongPressGestureRecognizer) {

    let locationInView = gestureReconizer.location(in: chatInputContainerView.attachCollectionView)
    
    guard let indexPath = chatInputContainerView.attachCollectionView.indexPathForItem(at: locationInView) else {
      return
    }
    guard let data = chatInputContainerView.attachedMedia[indexPath.item].audioObject else {
      return
    }
    guard let cell = chatInputContainerView.attachCollectionView.cellForItem(at: indexPath) as? AttachCollectionViewCell else {
      return
    }
    
    if gestureReconizer.state == .began {
      print("press began")
    
      do {
        chatInputContainerView.audioPlayer = try AVAudioPlayer(data: data)
      } catch {
        print("error playing")
      }
      
      chatInputContainerView.audioPlayer.prepareToPlay()
      chatInputContainerView.audioPlayer.volume = 1.0
      chatInputContainerView.audioPlayer.play()
      cell.runTimer()
      UIView.animate(withDuration: 0.2, animations: {
          cell.playerView.alpha = 1
          cell.playerView.backgroundColor = .green
      })
      cell.playerView.play.setImage(UIImage(named: "pause"), for: .normal)
    }

    if gestureReconizer.state == .cancelled || gestureReconizer.state == .failed || gestureReconizer.state == .ended {
      
      print("press cancelled failed or ended")
      do {
        chatInputContainerView.audioPlayer = try AVAudioPlayer(data: data)
      } catch {
        print("error playing")
      }

      chatInputContainerView.audioPlayer.stop()
      cell.resetTimer()
      UIView.animate(withDuration: 0.2, animations: {
         cell.playerView.alpha = 0.85
         cell.playerView.backgroundColor = .black
      })
      cell.playerView.play.setImage(UIImage(named: "playWhite"), for: .normal)
    }
  }
  
  fileprivate func reloadAccessoryViews() {
    videoIndicatorView.isHidden = !isVideo
  }
}
