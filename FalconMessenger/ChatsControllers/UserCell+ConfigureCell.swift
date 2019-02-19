//
//  ChatsTableViewController+ConfigureCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/14/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

extension UserCell {
  
  func configureCell(for indexPath: IndexPath, conversations: Results<Conversation>) {
    let isPersonalStorage = conversations[indexPath.row].chatID == Auth.auth().currentUser?.uid
    let isConversationMuted = conversations[indexPath.row].muted.value != nil && conversations[indexPath.row].muted.value!
		let chatName = conversations[indexPath.row].chatName
    let isGroupChat = conversations[indexPath.row].isGroupChat.value ?? false
    
    var placeHolderImage = isGroupChat ? UIImage(named: "GroupIcon") : UIImage(named: "UserpicIcon")
    placeHolderImage = isPersonalStorage ? UIImage(named: "PersonalStorage") : placeHolderImage

		if let url = conversations[indexPath.row].chatThumbnailPhotoURL, !isPersonalStorage, url != "" {
			profileImageView.sd_setImage(with: URL(string: url), placeholderImage: nil, options:
			[.continueInBackground, .scaleDownLargeImages]) { (image, error, cacheType, url) in

				guard error == nil else {
					self.profileImageView.image = placeHolderImage
					return
				}
			}
		} else {
			profileImageView.image = placeHolderImage
		}

    nameLabel.text = chatName
    muteIndicator.isHidden = !isConversationMuted || isPersonalStorage
    
    if let isTyping = conversations[indexPath.row].isTyping.value, isTyping {
      messageLabel.text = "typing"
      typingIndicatorTimer = Timer.scheduledTimer(timeInterval: 0.15,
																									target: self,
																									selector: #selector(updateTypingIndicatorTimer),
																									userInfo: nil,
																									repeats: true)
			RunLoop.main.add(self.typingIndicatorTimer!, forMode: RunLoop.Mode.common)
    } else {
      typingIndicatorTimer?.invalidate()
      messageLabel.text = conversations[indexPath.row].messageText()
    }

    if let lastMessage = conversations[indexPath.row].lastMessage {
			let date = Date(timeIntervalSince1970: TimeInterval(exactly: lastMessage.timestamp.value!)!)
      timeLabel.text = timestampOfLastMessage(date)
      timeLabelWidthAnchor.constant = timeLabelWidth(text: timeLabel.text ?? "")
    }

		let badgeString = conversations[indexPath.row].badge.value?.toString()
    let badgeInt = conversations[indexPath.row].badge.value ?? 0
    
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
