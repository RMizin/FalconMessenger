//
//  ChatLogViewController+DataSource.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos

extension ChatLogViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
   func numberOfSections(in collectionView: UICollectionView) -> Int {
    return groupedMessages.count + typingIndicatorSection.count
  }
  
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      if section == groupedMessages.count {
        return 1
      } else {
        return groupedMessages[section].count
      }
    }
  
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
  
   if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "lol",
                                                                   for: indexPath) as? ChatLogViewControllerSupplementaryView {
      guard groupedMessages.indices.contains(indexPath.section),
      groupedMessages[indexPath.section].indices.contains(indexPath.row) else { header.label.text = ""; return header }
    
      header.label.text = groupedMessages[indexPath.section][indexPath.row].shortConvertedTimestamp
      return header
    }
    return UICollectionReusableView()
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
    return section == groupedMessages.count ? CGSize(width: collectionView.bounds.width , height: 0) : CGSize(width: collectionView.bounds.width, height: 40)
  }
  
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard indexPath.section != groupedMessages.count else {print("getting data for indicator"); return showTypingIndicator(indexPath: indexPath)! as! TypingIndicatorCell }
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      return selectCell(for: indexPath, isGroupChat: true)!
    } else {
      return selectCell(for: indexPath, isGroupChat: false)!
    }
  }
  
  fileprivate func showTypingIndicator(indexPath: IndexPath) -> UICollectionViewCell? {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: typingIndicatorCellID, for: indexPath) as! TypingIndicatorCell
    cell.restart()
    
    return cell
  }
  
  fileprivate func selectCell(for indexPath: IndexPath, isGroupChat: Bool) -> UICollectionViewCell? {

    let message = groupedMessages[indexPath.section][indexPath.row] //sometimes crash

    let isTextMessage = message.text != nil
    let isPhotoVideoMessage = message.imageUrl != nil || message.localImage != nil
    let isVoiceMessage = message.voiceEncodedString != nil
    let isOutgoingMessage = message.fromId == Auth.auth().currentUser?.uid
    let isInformationMessage = message.isInformationMessage ?? false
    
    if isInformationMessage {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: informationMessageCellID, for: indexPath) as! InformationMessageCell
      cell.setupData(message: message)
      return cell
    } else
      
      if isTextMessage {
        switch isOutgoingMessage {
        case true:
          let cell = collectionView.dequeueReusableCell(withReuseIdentifier: outgoingTextMessageCellID, for: indexPath) as! OutgoingTextMessageCell
          cell.chatLogController = self
          cell.setupData(message: message)
          DispatchQueue.global(qos: .default).async { [unowned self] in
            cell.configureDeliveryStatus(at: indexPath, groupMessages: self.groupedMessages, message: message)
          }
          
          return cell
        case false:
          let cell = collectionView.dequeueReusableCell(withReuseIdentifier: incomingTextMessageCellID, for: indexPath) as! IncomingTextMessageCell
          cell.chatLogController = self
          cell.setupData(message: message, isGroupChat: isGroupChat)
          return cell
        }
      } else
        
        if isPhotoVideoMessage {
          switch isOutgoingMessage {
          case true:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoMessageCellID, for: indexPath) as! PhotoMessageCell
            cell.chatLogController = self
            cell.setupData(message: message)
            if let image = message.localImage {
              cell.setupImageFromLocalData(message: message, image: image)
              DispatchQueue.global(qos: .default).async { [unowned self] in
                cell.configureDeliveryStatus(at: indexPath, groupMessages: self.groupedMessages, message: message)
              }
  
              return cell
            }
            if let messageImageUrl = message.imageUrl {
              cell.setupImageFromURL(message: message, messageImageUrl: URL(string: messageImageUrl)!)
              DispatchQueue.global(qos: .default).async { [unowned self] in
                cell.configureDeliveryStatus(at: indexPath, groupMessages: self.groupedMessages, message: message)
              }
              
              return cell
            }
            break
          case false:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: incomingPhotoMessageCellID, for: indexPath) as! IncomingPhotoMessageCell
            cell.chatLogController = self
            cell.setupData(message: message, isGroupChat: isGroupChat)
            if let image = message.localImage {
              cell.setupImageFromLocalData(message: message, image: image)
              return cell
            }
            if let messageImageUrl = message.imageUrl {
              cell.setupImageFromURL(message: message, messageImageUrl: URL(string: messageImageUrl)!)
              return cell
            }
            break
          }
        } else
          
          if isVoiceMessage {
            switch isOutgoingMessage {
            case true:
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: outgoingVoiceMessageCellID, for: indexPath) as! OutgoingVoiceMessageCell
              cell.chatLogController = self
              cell.setupData(message: message)
              
              DispatchQueue.global(qos: .default).async { [unowned self] in
                cell.configureDeliveryStatus(at: indexPath, groupMessages: self.groupedMessages, message: message)
              }
              
              return cell
            case false:
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: incomingVoiceMessageCellID, for: indexPath) as! IncomingVoiceMessageCell
              cell.chatLogController = self
              cell.setupData(message: message, isGroupChat: isGroupChat)
              return cell
            }
    }
    return nil
  }
  
   func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    
    if let cell = cell as? OutgoingVoiceMessageCell {
      guard cell.isSelected, chatLogAudioPlayer != nil else { return }
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
      do {
        try AVAudioSession.sharedInstance().setActive(false)
      } catch {}
    } else if let cell = cell as? IncomingVoiceMessageCell {
      guard cell.isSelected, chatLogAudioPlayer != nil else { return }
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
      do {
        try AVAudioSession.sharedInstance().setActive(false)
      } catch {}
    }
  }
  
   func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseVoiceMessageCell, chatLogAudioPlayer != nil else { return }
    chatLogAudioPlayer.stop()
    cell.playerView.resetTimer()
    cell.playerView.play.isSelected = false
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {}
  }
  
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard groupedMessages.indices.contains(indexPath.section) else { return }
    let message = groupedMessages[indexPath.section][indexPath.item]
    guard let voiceEncodedString = message.voiceEncodedString else { return }
    guard let data = Data(base64Encoded: voiceEncodedString) else { return }
    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseVoiceMessageCell else { return }
    let isAlreadyPlaying = chatLogAudioPlayer != nil && chatLogAudioPlayer.isPlaying
    
    guard !isAlreadyPlaying else {
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
      do {
        try AVAudioSession.sharedInstance().setActive(false)
      } catch {}
      return
    }
    
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {}
    do {
      chatLogAudioPlayer = try AVAudioPlayer(data:  data)
      chatLogAudioPlayer.prepareToPlay()
      chatLogAudioPlayer.volume = 1.0
      chatLogAudioPlayer.play()
      cell.playerView.runTimer()
      cell.playerView.play.isSelected = true
    } catch {
      chatLogAudioPlayer = nil
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return selectSize(indexPath: indexPath)
  }
  
  func selectSize(indexPath: IndexPath) -> CGSize {
    guard indexPath.section != groupedMessages.count else {return CGSize(width: collectionView.frame.width, height: 30) }
    var cellHeight: CGFloat = 80
    let message = groupedMessages[indexPath.section][indexPath.item]
    let isTextMessage = message.text != nil
    let isPhotoVideoMessage = message.imageUrl != nil || message.localImage != nil
    let isVoiceMessage = message.voiceEncodedString != nil
    let isOutgoingMessage = message.fromId == Auth.auth().currentUser?.uid
    let isInformationMessage = message.isInformationMessage ?? false
    let isGroupChat = conversation!.isGroupChat ?? false
    
    guard !isInformationMessage else {
        guard let messagesFetcher = messagesFetcher else { return CGSize(width: 0, height: 0) }
      let infoMessageWidth = collectionView.frame.width
        guard let messageText = message.text else { return CGSize(width: 0, height: 0 ) }
      let infoMessageHeight = messagesFetcher.estimateFrameForText(width: infoMessageWidth, text: messageText, font: MessageFontsAppearance.defaultInformationMessageTextFont).height + 25
      return CGSize(width: infoMessageWidth, height: infoMessageHeight)
    }
    
    guard !isTextMessage else {

      let portraitHeight = setupCellHeight(isGroupChat: isGroupChat, isOutgoingMessage: isOutgoingMessage, frame: message.estimatedFrameForText, indexPath: indexPath)
      let landscapeHeight = setupCellHeight(isGroupChat: isGroupChat, isOutgoingMessage: isOutgoingMessage, frame: message.landscapeEstimatedFrameForText, indexPath: indexPath)
      
      switch UIDevice.current.orientation {
      case .landscapeRight, .landscapeLeft:
        cellHeight = landscapeHeight
        break
      default:
        cellHeight = portraitHeight
        break
      }
      
      return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
    
    guard !isPhotoVideoMessage else {
      
      if CGFloat(truncating: message.imageCellHeight!) < BaseMessageCell.minimumMediaCellHeight {
        if isGroupChat, !isOutgoingMessage {
          cellHeight = BaseMessageCell.incomingGroupMinimumMediaCellHeight
        } else {
          cellHeight = BaseMessageCell.minimumMediaCellHeight
        }
      } else {
        if isGroupChat, !isOutgoingMessage {
          cellHeight = CGFloat(truncating: message.imageCellHeight!) + BaseMessageCell.incomingGroupMessageAuthorNameLabelHeightWithInsets
        } else {
          cellHeight = CGFloat(truncating: message.imageCellHeight!)
        }
      }
      
      return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
  
    guard !isVoiceMessage else {
      if isGroupChat, !isOutgoingMessage {
        cellHeight = BaseMessageCell.groupIncomingVoiceMessageHeight + BaseMessageCell.messageTimeHeight
      } else {
        cellHeight = BaseMessageCell.defaultVoiceMessageHeight + BaseMessageCell.messageTimeHeight
      }
      return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
    return CGSize(width: collectionView.frame.width, height: cellHeight)
  }
  
  fileprivate func setupCellHeight(isGroupChat: Bool, isOutgoingMessage: Bool, frame: CGRect?, indexPath: IndexPath) -> CGFloat {
    guard let frame = frame else { return 0 }
 
    var timeHeight: CGFloat!
    let bubbleMaxWidth = UIDevice.current.orientation.isLandscape ? BaseMessageCell.landscapeBubbleViewMaxWidth : BaseMessageCell.bubbleViewMaxWidth
    if (frame.width + BaseMessageCell.messageTimeWidth <=  bubbleMaxWidth) ||
      frame.width < BaseMessageCell.messageTimeWidth {
      timeHeight = 0
    } else {
      timeHeight = BaseMessageCell.messageTimeHeight
    }
  
    if isGroupChat, !isOutgoingMessage {
    
      return frame.height + BaseMessageCell.groupTextMessageInsets + timeHeight
    } else {
      return frame.height + BaseMessageCell.defaultTextMessageInsets + timeHeight
    }
  }
}
