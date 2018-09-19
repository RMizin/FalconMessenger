//
//  ChatLogController+DataSource.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/19/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos
import FLAnimatedImage

extension ChatLogController: UICollectionViewDelegateFlowLayout {
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if section == 0 {
      return messages.count
    } else {
      return 1
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    guard indexPath.section == 0 else { return showTypingIndicator(indexPath: indexPath) }
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      return selectCell(for: indexPath, isGroupChat: true)!
    } else {
      return selectCell(for: indexPath, isGroupChat: false)!
    }
  }
  
  fileprivate func showTypingIndicator(indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: typingIndicatorCellID,
                                                   for: indexPath) as? TypingIndicatorCell ?? TypingIndicatorCell()
    guard let gifURL = ThemeManager.currentTheme().typingIndicatorURL else { return TypingIndicatorCell() }
    guard let gifData = NSData(contentsOf: gifURL) else { return TypingIndicatorCell() }
    cell.typingIndicator.animatedImage = FLAnimatedImage(animatedGIFData: gifData as Data)
    return cell
  }
  
  fileprivate func selectCell(for indexPath: IndexPath, isGroupChat: Bool) -> RevealableCollectionViewCell? {
    
    let message = messages[indexPath.item]
    let isTextMessage = message.text != nil
    let isPhotoVideoMessage = message.imageUrl != nil || message.localImage != nil
    let isVoiceMessage = message.voiceEncodedString != nil
    let isOutgoingMessage = message.fromId == Auth.auth().currentUser?.uid
    let isInformationMessage = message.isInformationMessage ?? false
    
    if isInformationMessage {
      let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: informationMessageCellID,
                                                     for: indexPath) as? InformationMessageCell ?? InformationMessageCell()
      cell.setupData(message: message)
      return cell
    } else
      
      if isTextMessage {
        switch isOutgoingMessage {
        case true:
          let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: outgoingTextMessageCellID,
                                                         for: indexPath) as? OutgoingTextMessageCell ?? OutgoingTextMessageCell()
          cell.chatLogController = self
          cell.setupData(message: message)
          DispatchQueue.global(qos: .background).async {
            cell.configureDeliveryStatus(at: indexPath, lastMessageIndex: self.messages.count-1, message: message)
          }
          
          return cell
        case false:
          let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingTextMessageCellID,
                                                         for: indexPath) as? IncomingTextMessageCell ?? IncomingTextMessageCell()
          cell.chatLogController = self
          cell.setupData(message: message, isGroupChat: isGroupChat)
          return cell
        }
      } else
        
        if isPhotoVideoMessage {
          switch isOutgoingMessage {
          case true:
            let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: photoMessageCellID,
                                                           for: indexPath) as? PhotoMessageCell ?? PhotoMessageCell()
            cell.chatLogController = self
            cell.setupData(message: message)
            if let image = message.localImage {
              cell.setupImageFromLocalData(message: message, image: image)
              DispatchQueue.global(qos: .background).async {
                cell.configureDeliveryStatus(at: indexPath, lastMessageIndex: self.messages.count-1, message: message)
              }
              return cell
            }
            if let messageImageUrl = message.imageUrl {
              cell.setupImageFromURL(message: message, messageImageUrl: URL(string: messageImageUrl)!)
              DispatchQueue.global(qos: .background).async {
                cell.configureDeliveryStatus(at: indexPath, lastMessageIndex: self.messages.count-1, message: message)
              }
              return cell
            }
            
          case false:
            let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingPhotoMessageCellID,
                                                           for: indexPath) as? IncomingPhotoMessageCell ?? IncomingPhotoMessageCell()
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
          }
        } else
          
          if isVoiceMessage {
            switch isOutgoingMessage {
            case true:
              let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: outgoingVoiceMessageCellID,
                                                             for: indexPath) as? OutgoingVoiceMessageCell ?? OutgoingVoiceMessageCell()
              cell.chatLogController = self
              cell.setupData(message: message)
              DispatchQueue.global(qos: .background).async {
                cell.configureDeliveryStatus(at: indexPath, lastMessageIndex: self.messages.count-1, message: message)
              }
              return cell
            case false:
              let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingVoiceMessageCellID,
                                                             for: indexPath) as? IncomingVoiceMessageCell ?? IncomingVoiceMessageCell()
              cell.chatLogController = self
              cell.setupData(message: message, isGroupChat: isGroupChat)
              return cell
            }
    }
    return nil
  }
  
  override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
    
    if let cell = cell as? OutgoingVoiceMessageCell {
      guard cell.isSelected, chatLogAudioPlayer != nil else { return }
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
    } else if let cell = cell as? IncomingVoiceMessageCell {
      guard cell.isSelected, chatLogAudioPlayer != nil else { return }
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseVoiceMessageCell, chatLogAudioPlayer != nil else {
      return
    }
    chatLogAudioPlayer.stop()
    cell.playerView.resetTimer()
    cell.playerView.play.isSelected = false
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    let message = messages[indexPath.item]
    guard let voiceEncodedString = message.voiceEncodedString else { return }
    guard let data = Data(base64Encoded: voiceEncodedString) else { return }
    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseVoiceMessageCell else { return }
    let isAlreadyPlaying = chatLogAudioPlayer != nil && chatLogAudioPlayer.isPlaying
    
    guard !isAlreadyPlaying else {
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
      return
    }
    
    do {
      chatLogAudioPlayer = try AVAudioPlayer(data: data)
      chatLogAudioPlayer.prepareToPlay()
      chatLogAudioPlayer.volume = 1.0
      chatLogAudioPlayer.play()
      cell.playerView.runTimer()
      cell.playerView.play.isSelected = true
    } catch {
      chatLogAudioPlayer = nil
      print(error.localizedDescription)
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return selectSize(indexPath: indexPath)
  }
  
  func selectSize(indexPath: IndexPath) -> CGSize {
    
    guard indexPath.section == 0 else {  return CGSize(width: self.collectionView!.frame.width, height: 40) }
    var cellHeight: CGFloat = 80
    let message = messages[indexPath.row]
    let isTextMessage = message.text != nil
    let isPhotoVideoMessage = message.imageUrl != nil || message.localImage != nil
    let isVoiceMessage = message.voiceEncodedString != nil
    let isOutgoingMessage = message.fromId == Auth.auth().currentUser?.uid
    let isInformationMessage = message.isInformationMessage ?? false
    let isGroupChat = conversation!.isGroupChat ?? false
    
    guard !isInformationMessage else {
      guard let infoMessageWidth = self.collectionView?.frame.width, let messageText = message.text else {
        return CGSize(width: 0, height: 0)
      }
      let infoMessageHeight = messagesFetcher.estimateFrameForText(width: infoMessageWidth, text: messageText,
                                                                   font: UIFont.systemFont(ofSize: 12)).height + 10
      return CGSize(width: infoMessageWidth, height: infoMessageHeight)
    }
    
    if isTextMessage {
      if let isInfoMessage = message.isInformationMessage, isInfoMessage {
        return CGSize(width: self.collectionView!.frame.width, height: 25)
      }
      
      if isGroupChat, !isOutgoingMessage {
        cellHeight = message.estimatedFrameForText!.height + 35
      } else {
        cellHeight = message.estimatedFrameForText!.height + 20
      }
    } else
      
      if isPhotoVideoMessage {
        if CGFloat(truncating: message.imageCellHeight!) < 66 {
          if isGroupChat, !isOutgoingMessage {
            cellHeight = 86
          } else {
            cellHeight = 66
          }
        } else {
          if isGroupChat, !isOutgoingMessage {
            cellHeight = CGFloat(truncating: message.imageCellHeight!) + 20
          } else {
            cellHeight = CGFloat(truncating: message.imageCellHeight!)
          }
        }
      } else
        
        if isVoiceMessage {
          if isGroupChat, !isOutgoingMessage {
            cellHeight = 55
          } else {
            cellHeight = 40
          }
    }
    
    return CGSize(width: self.collectionView!.frame.width, height: cellHeight)
  }
}
