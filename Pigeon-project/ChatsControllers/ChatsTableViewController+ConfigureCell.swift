//
//  ChatsTableViewController+ConfigureCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/14/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension ChatsTableViewController {
  
  func configurePinnedCell(for indexPath: IndexPath) -> UserCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as! UserCell
    
    // chat title
    if filteredPinnedConversations[indexPath.row].chatID == Auth.auth().currentUser?.uid {
      cell.nameLabel.text = NameConstants.personalStorage
    } else {
      cell.nameLabel.text = filteredPinnedConversations[indexPath.row].chatName
    }
    
    // mute indicator
    if filteredPinnedConversations[indexPath.row].muted != nil && filteredPinnedConversations[indexPath.row].muted! {
      cell.muteIndicator.isHidden = false
    } else {
      cell.muteIndicator.isHidden = true
    }
    
    // last message text
    if (filteredPinnedConversations[indexPath.row].lastMessage?.imageUrl != nil ||
      filteredPinnedConversations[indexPath.row].lastMessage?.localImage != nil) &&
      filteredPinnedConversations[indexPath.row].lastMessage?.videoUrl == nil {
      cell.messageLabel.text = MessageSubtitle.image
    } else if (filteredPinnedConversations[indexPath.row].lastMessage?.imageUrl != nil ||
      filteredPinnedConversations[indexPath.row].lastMessage?.localImage != nil) &&
      filteredPinnedConversations[indexPath.row].lastMessage?.videoUrl != nil {
      cell.messageLabel.text = MessageSubtitle.video
    } else if filteredPinnedConversations[indexPath.row].lastMessage?.voiceEncodedString != nil {
      cell.messageLabel.text = MessageSubtitle.audio
    } else {
      if filteredPinnedConversations[indexPath.row].lastMessage?.text == nil {
        cell.messageLabel.text = "No messages here yet."
      } else {
        cell.messageLabel.text = filteredPinnedConversations[indexPath.row].lastMessage?.text
      }
    }
    
    // last message date
    if let lastMessage = filteredPinnedConversations[indexPath.row].lastMessage {
      let date = Date(timeIntervalSince1970: lastMessage.timestamp as! TimeInterval)
      cell.timeLabel.text = timestampOfLastMessage(date)
    }
    
    // chat avatar
    if filteredPinnedConversations[indexPath.row].chatID == Auth.auth().currentUser?.uid {
      cell.profileImageView.image = UIImage(named: "PersonalStorage")
    } else if let url = filteredPinnedConversations[indexPath.row].chatThumbnailPhotoURL {
  
      if let isGroupChat = filteredPinnedConversations[indexPath.row].isGroupChat, isGroupChat {
        cell.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "GroupIcon"), options: [.continueInBackground, .scaleDownLargeImages], completed: nil)
      } else {
        //GroupIcon
        cell.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "UserpicIcon"), options: [.continueInBackground, .scaleDownLargeImages], completed: nil)
      }
    } else {
      if let isGroupChat = filteredPinnedConversations[indexPath.row].isGroupChat, isGroupChat {
        cell.profileImageView.image = UIImage(named: "GroupIcon")
      } else {
        cell.profileImageView.image = UIImage(named: "UserpicIcon")
      }
    }
    
    // badge
    let badgeString = filteredPinnedConversations[indexPath.row].badge?.toString()
    let badgeInt = filteredPinnedConversations[indexPath.row].badge ?? 0
    
    guard badgeInt > 0, filteredPinnedConversations[indexPath.row].lastMessage?.fromId != Auth.auth().currentUser?.uid else {
      cell.newMessageIndicator.isHidden = true
      cell.badgeLabel.isHidden = true
      cell.badgeLabelRightConstraint.constant = 0
      cell.badgeLabelWidthConstraint.constant = cell.badgeLabelRightConstantForHidden
      return cell
    }
    
    cell.badgeLabel.text = badgeString
    cell.badgeLabel.isHidden = false
    cell.badgeLabelWidthConstraint.constant = cell.badgeLabelWidthConstant
    cell.badgeLabelRightConstraint.constant = cell.badgeLabelRightConstant
    cell.newMessageIndicator.isHidden = false
    return cell
  }
  
  func configuredCell(for indexPath: IndexPath) -> UserCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as! UserCell
    
    // chat title
    if filtededConversations[indexPath.row].chatID == Auth.auth().currentUser?.uid {
      cell.nameLabel.text = NameConstants.personalStorage
    } else {
      cell.nameLabel.text = filtededConversations[indexPath.row].chatName
    }
    
    // mute indicator
    if filtededConversations[indexPath.row].muted != nil && filtededConversations[indexPath.row].muted! {
      cell.muteIndicator.isHidden = false
    } else {
      cell.muteIndicator.isHidden = true
    }
    
    // last message text
    if (filtededConversations[indexPath.row].lastMessage?.imageUrl != nil ||
      filtededConversations[indexPath.row].lastMessage?.localImage != nil) &&
      filtededConversations[indexPath.row].lastMessage?.videoUrl == nil {
      cell.messageLabel.text = MessageSubtitle.image
    } else if (filtededConversations[indexPath.row].lastMessage?.imageUrl != nil ||
      filtededConversations[indexPath.row].lastMessage?.localImage != nil) &&
      filtededConversations[indexPath.row].lastMessage?.videoUrl != nil {
      cell.messageLabel.text = MessageSubtitle.video
    } else if filtededConversations[indexPath.row].lastMessage?.voiceEncodedString != nil {
      cell.messageLabel.text = MessageSubtitle.audio
    } else {
      if filtededConversations[indexPath.row].lastMessage == nil {
        cell.messageLabel.text = "No messages here yet."
      } else {
        cell.messageLabel.text = filtededConversations[indexPath.row].lastMessage?.text
      }
    }
    
    // last message date
    if let lastMessage = filtededConversations[indexPath.row].lastMessage {
      let date = Date(timeIntervalSince1970: lastMessage.timestamp as! TimeInterval)
      cell.timeLabel.text = timestampOfLastMessage(date)
    }
    
    // chat avatar
    if filtededConversations[indexPath.row].chatID == Auth.auth().currentUser?.uid {
      cell.profileImageView.image = UIImage(named: "PersonalStorage")
    } else if let url = filtededConversations[indexPath.row].chatThumbnailPhotoURL {
      if let isGroupChat = filtededConversations[indexPath.row].isGroupChat, isGroupChat {
          cell.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "GroupIcon"), options: [.continueInBackground, .scaleDownLargeImages], completed: nil)
      } else {
        //GroupIcon
        cell.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "UserpicIcon"), options: [.continueInBackground, .scaleDownLargeImages], completed: nil)
      }
    } else {
      if let isGroupChat = filtededConversations[indexPath.row].isGroupChat, isGroupChat {
        cell.profileImageView.image = UIImage(named: "GroupIcon")
      } else {
        cell.profileImageView.image = UIImage(named: "UserpicIcon")
      }
    }
    
    // badge
    let badgeString = filtededConversations[indexPath.row].badge?.toString()
    let badgeInt = filtededConversations[indexPath.row].badge ?? 0
    
    guard badgeInt > 0, filtededConversations[indexPath.row].lastMessage?.fromId != Auth.auth().currentUser?.uid  else {
      cell.newMessageIndicator.isHidden = true
      cell.badgeLabel.isHidden = true
      cell.badgeLabelRightConstraint.constant = 0
      cell.badgeLabelWidthConstraint.constant = cell.badgeLabelRightConstantForHidden
      return cell
    }
    
    cell.badgeLabel.text = badgeString
    cell.badgeLabel.isHidden = false
    cell.badgeLabelWidthConstraint.constant = cell.badgeLabelWidthConstant
    cell.badgeLabelRightConstraint.constant = cell.badgeLabelRightConstant
    cell.newMessageIndicator.isHidden = false
    return cell
  }
}
