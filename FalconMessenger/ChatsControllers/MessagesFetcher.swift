//
//  MessagesFetcher.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Photos

protocol MessagesDelegate: class {
    func messages(shouldBeUpdatedTo messages: [Message], conversation:Conversation, controller: UIViewController)
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference, controller: UIViewController)
}

protocol CollectionDelegate: class {
  func collectionView(shouldBeUpdatedWith message: Message, reference: DatabaseReference)
  func collectionView(shouldRemoveMessage id: String)
  func collectionView(shouldUpdateOutgoingMessageStatusFrom reference: DatabaseReference, message: Message)
}

class MessagesFetcher: NSObject {

  private var messages = [Message]()
  
  var userMessagesReference: DatabaseQuery!
  var userMessagesHandle: DatabaseHandle!
  
  var manualRemovingReference: DatabaseReference!
  var manualRemovingHandle: DatabaseHandle!
  
  var messagesReference: DatabaseReference!
  
  private let messagesToLoad = 50

  weak var delegate: MessagesDelegate?
  weak var collectionDelegate: CollectionDelegate?
  
  var isInitialChatMessagesLoad = true
  
  private var loadingMessagesGroup = DispatchGroup()
  private var loadingNamesGroup = DispatchGroup()
	private var chatLogAudioPlayer: AVAudioPlayer!
  
  
  func cleanAllObservers() {
    if userMessagesReference != nil, userMessagesHandle != nil {
      userMessagesReference.removeObserver(withHandle: userMessagesHandle)
    }
    
    if manualRemovingReference != nil, userMessagesHandle != nil {
      manualRemovingReference.removeObserver(withHandle: manualRemovingHandle)
    }
  }
  
    func loadMessagesData(for conversation: Conversation, controller: UIViewController?) {
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID, let controller = controller else { return }
    
    var isGroupChat = Bool()
    if let groupChat = conversation.isGroupChat.value, groupChat { isGroupChat = true } else { isGroupChat = false }
    
    userMessagesReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(messagesToLoad))
    
    loadingMessagesGroup.enter()
		newLoadMessages(reference: userMessagesReference, isGroupChat: isGroupChat, conversation: conversation)
    observeManualRemoving(currentUserID: currentUserID, conversationID: conversationID)

    loadingMessagesGroup.notify(queue: .main, execute: {
      guard self.messages.count != 0 else {
        if self.isInitialChatMessagesLoad {
          self.messages = self.sortedMessages(unsortedMessages: self.messages)
        }
        self.isInitialChatMessagesLoad = false
        self.delegate?.messages(shouldBeUpdatedTo: self.messages, conversation: conversation, controller: controller)
        return
      }
      
      self.loadingNamesGroup.enter()
      self.newLoadUserames()
      self.loadingNamesGroup.notify(queue: .main, execute: {
        if self.isInitialChatMessagesLoad {
          self.messages = self.sortedMessages(unsortedMessages: self.messages)
        }
       // self.messages = self.configureTails(for: self.messages, isGroupChat: isGroupChat)
        self.isInitialChatMessagesLoad = false
        self.delegate?.messages(shouldChangeMessageStatusToReadAt: self.messagesReference, controller: controller)
        self.delegate?.messages(shouldBeUpdatedTo: self.messages, conversation: conversation, controller: controller)
      })

    })
  }
  
  func observeManualRemoving(currentUserID: String, conversationID: String) {
    guard manualRemovingReference == nil else { return }
    
    manualRemovingReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder)
    manualRemovingHandle = manualRemovingReference.observe(.childRemoved, with: { (snapshot) in
      let removedMessageID = snapshot.key
      self.collectionDelegate?.collectionView(shouldRemoveMessage: removedMessageID)
    })
  }
  
	func newLoadMessages(reference: DatabaseQuery, isGroupChat: Bool, conversation: Conversation) {
    var loadedMessages = [Message]()
    let loadedMessagesGroup = DispatchGroup()
    
    reference.observeSingleEvent(of: .value) { (snapshot) in
      for _ in 0 ..< snapshot.childrenCount { loadedMessagesGroup.enter() }
      
      loadedMessagesGroup.notify(queue: .main, execute: {
        self.messages = loadedMessages
        self.loadingMessagesGroup.leave()
      })
      
      self.userMessagesHandle = reference.observe(.childAdded, with: { (snapshot) in
        let messageUID = snapshot.key
        self.messagesReference = Database.database().reference().child("messages").child(messageUID)
        self.messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
          
          guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
          dictionary.updateValue(messageUID as AnyObject, forKey: "messageUID")
          dictionary = self.preloadCellData(to: dictionary, isGroupChat: isGroupChat)

          guard self.isInitialChatMessagesLoad else {
            self.handleMessageInsertionInRuntime(newDictionary: dictionary)
            return
          }

					let message = Message(dictionary: dictionary)
					message.conversation = conversation
					prefetchThumbnail(from: message.thumbnailImageUrl)


					if message.timestamp.value ?? 0 >= self.messages.first?.timestamp.value ?? 0 {
						loadedMessages.append(message)
					}

          loadedMessagesGroup.leave()
        })
      })
    }
  }
	
  func handleMessageInsertionInRuntime(newDictionary : [String: AnyObject]) {
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    let message = Message(dictionary: newDictionary)

		prefetchThumbnail(from: message.thumbnailImageUrl)
    let isOutBoxMessage = message.fromId == currentUserID || message.fromId == message.toId
    
    self.loadUserNameForOneMessage(message: message) { [unowned self] (_, messageWithName) in
      if !isOutBoxMessage {
        self.collectionDelegate?.collectionView(shouldBeUpdatedWith: messageWithName, reference: self.messagesReference)
      } else {
        if let isInformationMessage = message.isInformationMessage.value, isInformationMessage {
          self.collectionDelegate?.collectionView(shouldBeUpdatedWith: messageWithName,
                                                  reference: self.messagesReference)
        } else {
          self.collectionDelegate?.collectionView(shouldUpdateOutgoingMessageStatusFrom: self.messagesReference,
                                                  message: messageWithName)
        }
      }
    }
  }

  typealias LoadNameCompletionHandler = (_ success: Bool, _ message: Message) -> Void
  func loadUserNameForOneMessage(message: Message, completion: @escaping LoadNameCompletionHandler) {
    
    guard let senderID = message.fromId else { completion(true, message); return }
    
    let reference = Database.database().reference().child("users").child(senderID)//.child("name")
    reference.observeSingleEvent(of: .value, with: { (snapshot) in
      guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
      let user = User(dictionary: dictionary)
      guard let name = user.name else { completion(true, message); return }
			message.senderName = name
      completion(true, message)
    })
  }

  func newLoadUserames() {
    let loadedUserNamesGroup = DispatchGroup()
    
    for _ in messages {
      loadedUserNamesGroup.enter()
    }

    loadedUserNamesGroup.notify(queue: .main, execute: {
      self.loadingNamesGroup.leave()
    })

		for index in 0...messages.count - 1 {
			guard let senderID = messages[index].fromId else { print("continuing");loadedUserNamesGroup.leave(); continue }
			let reference = Database.database().reference().child("users").child(senderID)
			reference.observeSingleEvent(of: .value, with: { (snapshot) in
				guard let dictionary = snapshot.value as? [String: AnyObject] else { loadedUserNamesGroup.leave(); return }
				let user = User(dictionary: dictionary)
				guard let name = user.name else { loadedUserNamesGroup.leave(); return }
				self.messages[index].senderName = name
				loadedUserNamesGroup.leave()
			})
		}
  }
  
  func sortedMessages(unsortedMessages: [Message]) -> [Message] {
    let sortedMessages = unsortedMessages.sorted(by: { (message1, message2) -> Bool in
			return message1.timestamp.value! < message2.timestamp.value!
    })
    return sortedMessages
  }

  func preloadCellData(to dictionary: [String: AnyObject], isGroupChat: Bool) -> [String: AnyObject] {
    var dictionary = dictionary

    if let messageText = dictionary["text"] as? String { /* pre-calculateCellSizes */

			let rect = RealmCGRect(estimateFrameForText(messageText, orientation: .portrait), id: dictionary["messageUID"] as? String ?? "")
			let lrect = RealmCGRect(estimateFrameForText(messageText, orientation: .landscapeLeft),
															id: (dictionary["messageUID"] as? String ?? "") + "landscape")
      dictionary.updateValue(rect as AnyObject, forKey: "estimatedFrameForText")
      dictionary.updateValue(lrect as AnyObject, forKey: "landscapeEstimatedFrameForText")
		} else if let imageWidth = dictionary["imageWidth"] as? Double, let imageHeight = dictionary["imageHeight"] as? Double {

      let aspect = CGFloat(imageHeight / imageWidth)
      let maxWidth = BaseMessageCell.mediaMaxWidth
      let cellHeight = aspect * maxWidth
      dictionary.updateValue(cellHeight as AnyObject, forKey: "imageCellHeight")
    }

    if let voiceEncodedString = dictionary["voiceEncodedString"] as? String { /* pre-encoding voice messages */
      let decoded = Data(base64Encoded: voiceEncodedString) as AnyObject
      let duration = self.getAudioDurationInHours(from: decoded as! Data) as AnyObject
      let startTime = self.getAudioDurationInSeconds(from: decoded as! Data) as AnyObject
      dictionary.updateValue(decoded, forKey: "voiceData")
      dictionary.updateValue(duration, forKey: "voiceDuration")
      dictionary.updateValue(startTime, forKey: "voiceStartTime")
    }

    if let messageTimestamp = dictionary["timestamp"] as? Int64 {  /* pre-converting timeintervals into dates */
			let date = Date(timeIntervalSince1970: TimeInterval(messageTimestamp))
      let convertedTimestamp = timestampOfChatLogMessage(date) as AnyObject
      let shortConvertedTimestamp = date.getShortDateStringFromUTC() as AnyObject

      dictionary.updateValue(convertedTimestamp, forKey: "convertedTimestamp")
      dictionary.updateValue(shortConvertedTimestamp, forKey: "shortConvertedTimestamp")
    }

    return dictionary
  }
  
  func estimateFrameForText(_ text: String, orientation: UIDeviceOrientation) -> CGRect {
    var size = CGSize()
    let portraitSize = CGSize(width: BaseMessageCell.bubbleViewMaxWidth, height: BaseMessageCell.bubbleViewMaxHeight)
    let landscapeSize = CGSize(width: BaseMessageCell.landscapeBubbleViewMaxWidth,
                               height: BaseMessageCell.bubbleViewMaxHeight)

    switch orientation {
    case .landscapeRight, .landscapeLeft:
      size = landscapeSize
      break
    default:
      size = portraitSize
    }
    let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
    return NSString(string: text).boundingRect(with: size,
                                               options: options,
																							 attributes: [NSAttributedString.Key.font: MessageFontsAppearance.defaultMessageTextFont],
                                               context: nil).integral
  }
  
  func estimateFrameForText(width: CGFloat, text: String, font: UIFont) -> CGRect { /* information messages only */
    let size = CGSize(width: width, height: BaseMessageCell.bubbleViewMaxHeight)
    let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
    return NSString(string: text).boundingRect(with: size,
                                               options: options,
																							 attributes: [NSAttributedString.Key.font: font],
                                               context: nil).integral
  }
  
  func getAudioDurationInHours(from data: Data) -> String? {
    do {
      chatLogAudioPlayer = try AVAudioPlayer(data: data)
      let duration = Int(chatLogAudioPlayer.duration)
      let hours = Int(duration) / 3600
      let minutes = Int(duration) / 60 % 60
      let seconds = Int(duration) % 60
      return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    } catch {
      return String(format: "%02i:%02i:%02i", 0, 0, 0)
    }
  }

  func getAudioDurationInSeconds(from data: Data) -> Int? {
    do {
      chatLogAudioPlayer = try AVAudioPlayer(data: data)
      let duration = Int(chatLogAudioPlayer.duration)
      return duration
    } catch {
      return nil
    }
  }
}
