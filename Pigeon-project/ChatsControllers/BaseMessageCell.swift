//
//  BaseMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FTPopOverMenu_Swift

class BaseMessageCell: RevealableCollectionViewCell {
  
  weak var chatLogController: ChatLogController?
  let grayBubbleImage = ThemeManager.currentTheme().incomingBubble
  let blueBubbleImage = ThemeManager.currentTheme().outgoingBubble
  
  let bubbleView: UIImageView = {
    let bubbleView = UIImageView()
    bubbleView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    bubbleView.isUserInteractionEnabled = true
    
    return bubbleView
  }()
  
  var deliveryStatus: UILabel = {
    var deliveryStatus = UILabel()
    deliveryStatus.text = "status"
    deliveryStatus.font = UIFont.boldSystemFont(ofSize: 10)
    deliveryStatus.textColor =  ThemeManager.currentTheme().generalSubtitleColor
    deliveryStatus.isHidden = true
    deliveryStatus.textAlignment = .right
    
    return deliveryStatus
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame.integral)
    
    setupViews()
  }
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
 @objc func handleLongTap(_ longPressGesture: UILongPressGestureRecognizer) {
    let config = FTConfiguration.shared
    config.menuWidth = 100
    var contextMenuItems = ["Copy"]
    guard let indexPath = self.chatLogController?.collectionView?.indexPath(for: self) else { return }
    if let _ = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? OutgoingVoiceMessageCell { return }
    if let _ = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? IncomingVoiceMessageCell { return }
    if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? PhotoMessageCell {
      if !cell.playButton.isHidden {
        contextMenuItems = ["Copy image preview"]
        config.menuWidth = 150
      }
    }
    if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? IncomingPhotoMessageCell {
      if !cell.playButton.isHidden {
        contextMenuItems = ["Copy image preview"]
        config.menuWidth = 150
      }
    }
  
    FTPopOverMenu.showForSender(sender: bubbleView, with: contextMenuItems, done: { (selectedIndex) in
      // TODO: CHANGE BUBBLE VIEW IMAGE TO IMAGE WITH DARKER BACKGROUND
      if selectedIndex == 0 {
        if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? PhotoMessageCell {
          UIPasteboard.general.image = cell.messageImageView.image
        } else if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? IncomingPhotoMessageCell {
          UIPasteboard.general.image = cell.messageImageView.image
        } else if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? OutgoingTextMessageCell {
          UIPasteboard.general.string = cell.textView.text
        } else if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? IncomingTextMessageCell {
          UIPasteboard.general.string = cell.textView.text
        }
      }
    }) {
        // TODO: CHANGE BUBBLE VIEW IMAGE TO DEFAULT IMAGE
    }
  }
  
  func setupViews() {
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  func prepareViewsForReuse() {}
  
  override func prepareForReuse() {
    super.prepareForReuse()
    prepareViewsForReuse()
  }
}
