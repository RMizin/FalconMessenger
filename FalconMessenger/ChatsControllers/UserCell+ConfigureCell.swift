//
//  ChatsTableViewController+ConfigureCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/14/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

extension UserCell {
  
  func configureCell(for indexPath: IndexPath, conversations: [Conversation]) {
    
    let isPersonalStorage = conversations[indexPath.row].chatID == Auth.auth().currentUser?.uid
    let isConversationMuted = conversations[indexPath.row].muted != nil && conversations[indexPath.row].muted!
    let chatName = isPersonalStorage ? NameConstants.personalStorage : conversations[indexPath.row].chatName
    let isGroupChat = conversations[indexPath.row].isGroupChat ?? false
    
    var placeHolderImage = isGroupChat ? UIImage(named: "GroupIcon") : UIImage(named: "UserpicIcon")
    placeHolderImage = isPersonalStorage ? UIImage(named: "PersonalStorage") : placeHolderImage
    
    nameLabel.text = chatName
    muteIndicator.isHidden = !isConversationMuted
    
    if let isTyping = conversations[indexPath.row].isTyping, isTyping {
      messageLabel.text = "typing"
      typingIndicatorTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(updateTypingIndicatorTimer), userInfo: nil, repeats: true)
      RunLoop.main.add(self.typingIndicatorTimer!, forMode: .commonModes)
    } else {
      typingIndicatorTimer?.invalidate()
      messageLabel.text = conversations[indexPath.row].messageText()
    }
    
    if let lastMessage = conversations[indexPath.row].lastMessage {
      let date = Date(timeIntervalSince1970: lastMessage.timestamp as! TimeInterval)
      timeLabel.text = timestampOfLastMessage(date)
      timeLabelWidthAnchor.constant = timeLabelWidth(text: timeLabel.text ?? "")
    }
  
    profileImageView.image = placeHolderImage
    
    if let url = conversations[indexPath.row].chatThumbnailPhotoURL, !isPersonalStorage, url != "" {
      profileImageView.sd_setImage(with: URL(string: url), placeholderImage: placeHolderImage, options:
      [.continueInBackground, .scaleDownLargeImages, .avoidAutoSetImage]) { (image, error, cacheType, url) in
        guard image != nil, cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
          self.profileImageView.image = image
          return
        }
        
        UIView.transition(with: self.profileImageView, duration: 0.2, options: .transitionCrossDissolve,
                          animations: { self.profileImageView.image = image }, completion: nil)
      }
    }

    let badgeString = conversations[indexPath.row].badge?.toString()
    let badgeInt = conversations[indexPath.row].badge ?? 0
    
    guard badgeInt > 0, conversations[indexPath.row].lastMessage?.fromId != Auth.auth().currentUser?.uid else {
      badgeLabel.isHidden = true
      messageLabelRightConstraint.constant = 0
      badgeLabelWidthConstraint.constant = 0
      return
    }
    
    badgeLabel.text = badgeString
    badgeLabel.isHidden = false
    badgeLabelWidthConstraint.constant = badgeLabelWidthConstant
    messageLabelRightConstraint.constant = messageLabelRightConstant
    return
  }
}
