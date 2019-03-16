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
        return groupedMessages[section].messages.count
      }
    }
  
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
  
   if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "lol",
																																	for: indexPath) as? ChatLogViewControllerSupplementaryView {
      guard groupedMessages.indices.contains(indexPath.section),
      groupedMessages[indexPath.section].messages.indices.contains(indexPath.row) else { header.label.text = ""; return header }
      header.label.text = groupedMessages[indexPath.section].messages[indexPath.row].shortConvertedTimestamp
      return header
    }
    return UICollectionReusableView()
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
    return section == groupedMessages.count ? CGSize(width: collectionView.bounds.width , height: 0) : CGSize(width: collectionView.bounds.width, height: 40)
  }
  
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard indexPath.section != groupedMessages.count else { return showTypingIndicator(indexPath: indexPath)! as! TypingIndicatorCell }
    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
      return selectCell(for: indexPath, isGroupChat: true)!
    } else {
      return selectCell(for: indexPath, isGroupChat: false)!
    }
  }
  
  fileprivate func showTypingIndicator(indexPath: IndexPath) -> UICollectionViewCell? {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionView.typingIndicatorCellID, for: indexPath) as! TypingIndicatorCell
    cell.restart()
    return cell
  }
  
  fileprivate func selectCell(for indexPath: IndexPath, isGroupChat: Bool) -> UICollectionViewCell? {
    let message = groupedMessages[indexPath.section].messages[indexPath.row]
    let isTextMessage = message.text != nil
    let isPhotoVideoMessage = message.imageUrl != nil || message.localImage != nil
    let isVoiceMessage = message.voiceEncodedString != nil
    let isOutgoingMessage = message.fromId == Auth.auth().currentUser?.uid
    let isInformationMessage = message.isInformationMessage.value ?? false
    
    if isInformationMessage {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionView.informationMessageCellID, for: indexPath) as! InformationMessageCell
      cell.setupData(message: message)
      return cell
    } else if isTextMessage {
			switch isOutgoingMessage {
			case true:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionView.outgoingTextMessageCellID, for: indexPath) as! OutgoingTextMessageCell
				cell.chatLogController = self
				cell.setupData(message: message)
				cell.configureDeliveryStatus(at: indexPath, groupMessages: self.groupedMessages, message: message)
				return cell
			case false:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionView.incomingTextMessageCellID, for: indexPath) as! IncomingTextMessageCell
				cell.chatLogController = self
				cell.setupData(message: message, isGroupChat: isGroupChat)
				return cell
			}
		} else if isPhotoVideoMessage {
			switch isOutgoingMessage {
			case true:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionView.photoMessageCellID, for: indexPath) as! PhotoMessageCell
				cell.chatLogController = self
				cell.setupData(message: message)
				cell.setupImageFromURL(message: message, indexPath: indexPath)
				cell.configureDeliveryStatus(at: indexPath, groupMessages: self.groupedMessages, message: message)
				return cell
			case false:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionView.incomingPhotoMessageCellID, for: indexPath) as! IncomingPhotoMessageCell
				cell.chatLogController = self
				cell.setupData(message: message, isGroupChat: isGroupChat)
				cell.setupImageFromURL(message: message, indexPath: indexPath)
				return cell
			}
		} else if isVoiceMessage {
			switch isOutgoingMessage {
			case true:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionView.outgoingVoiceMessageCellID, for: indexPath) as! OutgoingVoiceMessageCell
				cell.chatLogController = self
				cell.setupData(message: message)
				cell.configureDeliveryStatus(at: indexPath, groupMessages: self.groupedMessages, message: message)
				return cell
			case false:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionView.incomingVoiceMessageCellID, for: indexPath) as! IncomingVoiceMessageCell
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
    let message = groupedMessages[indexPath.section].messages[indexPath.item]
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
			try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {}
    do {
      chatLogAudioPlayer = try AVAudioPlayer(data: data)
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
    guard indexPath.section != groupedMessages.count else { return CGSize(width: collectionView.frame.width, height: 30) }
    var cellHeight: CGFloat = 80
    let message = groupedMessages[indexPath.section].messages[indexPath.item]
		let isInformationMessage = message.isInformationMessage.value ?? false
		let isTextMessage = message.text != nil && !isInformationMessage
		let isPhotoVideoMessage = message.imageUrl != nil || message.localImage != nil
		let isVoiceMessage = message.voiceEncodedString != nil
    let isOutgoingMessage = message.fromId == Auth.auth().currentUser?.uid

    let isGroupChat = conversation!.isGroupChat.value ?? false

		guard !isTextMessage else {
			if UIDevice.current.orientation.isLandscape {
				return CGSize(width: collectionView.frame.width,
											height: collectionView.setupCellHeight(isGroupChat: isGroupChat,
																														 isOutgoingMessage: isOutgoingMessage,
																														 frame: message.landscapeEstimatedFrameForText,
																														 indexPath: indexPath))
			} else {
				return CGSize(width: collectionView.frame.width,
											height: collectionView.setupCellHeight(isGroupChat: isGroupChat,
																														 isOutgoingMessage: isOutgoingMessage,
																														 frame: message.estimatedFrameForText,
																														 indexPath: indexPath))
			}
		}

		guard !isPhotoVideoMessage else {
			if CGFloat(message.imageCellHeight.value!) < BaseMessageCell.minimumMediaCellHeight {
				if isGroupChat, !isOutgoingMessage {
					cellHeight = BaseMessageCell.incomingGroupMinimumMediaCellHeight
				} else {
					cellHeight = BaseMessageCell.minimumMediaCellHeight
				}
			} else {
				if isGroupChat, !isOutgoingMessage {
					cellHeight = CGFloat(message.imageCellHeight.value!) + BaseMessageCell.incomingGroupMessageAuthorNameLabelHeightWithInsets
				} else {
					cellHeight = CGFloat(message.imageCellHeight.value!)
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
		
		guard !isInformationMessage else {
			guard let messagesFetcher = messagesFetcher else { return CGSize(width: 0, height: 0) }
			let infoMessageWidth = collectionView.frame.width
			guard let messageText = message.text else { return CGSize(width: 0, height: 0 ) }
			let infoMessageHeight = messagesFetcher.estimateFrameForText(width: infoMessageWidth,
																																	 text: messageText,
																																	 font: MessageFontsAppearance.defaultInformationMessageTextFont).height + 25
			return CGSize(width: infoMessageWidth, height: infoMessageHeight)
		}

    return CGSize(width: collectionView.frame.width, height: cellHeight)
  }
}
