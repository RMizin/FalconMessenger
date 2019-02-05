//
//  MessagesFetcher.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos

protocol MessagesDelegate: class {
  func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation)
  func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference)
}

protocol CollectionDelegate: class {
  func collectionView(update message: Message, reference: DatabaseReference)
  func collectionView(updateStatus reference: DatabaseReference, message: Message)
}

class MessagesFetcher: NSObject {
  
  private var messages = [Message]()

  var userMessagesReference: DatabaseQuery!

  var messagesReference: DatabaseReference!
  
  private  let messagesToLoad = 50

  private var chatLogAudioPlayer: AVAudioPlayer!
  
  weak var delegate: MessagesDelegate?

  weak var collectionDelegate: CollectionDelegate?

  var isInitialChatMessagesLoad = true

  private var loadingMessagesGroup = DispatchGroup()

  private var loadingNamesGroup = DispatchGroup()

  func loadMessagesData(for conversation: Conversation) {
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID else { return }

    var isGroupChat = Bool()
    if let groupChat = conversation.isGroupChat, groupChat { isGroupChat = true } else { isGroupChat = false }
    let reference = Database.database().reference().child("user-messages")
      userMessagesReference = reference.child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder)
        .queryLimited(toLast: UInt(messagesToLoad))

    loadingMessagesGroup.enter()
    newLoadMessages(reference: userMessagesReference, isGroupChat: isGroupChat)

    loadingMessagesGroup.notify(queue: .main, execute: {
      print("loadingMessagesGroup finished")
      
      guard self.messages.count != 0 else {
         self.isInitialChatMessagesLoad = false
        self.delegate?.messages(shouldBeUpdatedTo: self.messages, conversation: conversation)
        return
      }

      self.loadingNamesGroup.enter()
      self.newLoadUserames()
      self.loadingNamesGroup.notify(queue: .main, execute: {
        print("loadingNamesGroup finished")
        self.messages = self.sortedMessages(unsortedMessages: self.messages)
        self.isInitialChatMessagesLoad = false
         self.delegate?.messages(shouldChangeMessageStatusToReadAt: self.messagesReference)
        self.delegate?.messages(shouldBeUpdatedTo: self.messages, conversation: conversation)
      })
    })
  }

  func newLoadMessages(reference: DatabaseQuery, isGroupChat: Bool) {
    var loadedMessages = [Message]()
    let loadedMessagesGroup = DispatchGroup()

    reference.observeSingleEvent(of: .value) { (snapshot) in
      for _ in 0 ..< snapshot.childrenCount { loadedMessagesGroup.enter() }

      loadedMessagesGroup.notify(queue: .main, execute: {
        print("loaded messages group finished initial loading messages")
        self.messages = loadedMessages
        self.loadingMessagesGroup.leave()
      })
      reference.observe(.childAdded, with: { (snapshot) in
        let messageUID = snapshot.key
        self.messagesReference = Database.database().reference().child("messages").child(messageUID)
        self.messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in

          guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
          dictionary.updateValue(messageUID as AnyObject, forKey: "messageUID")
          dictionary = self.preloadCellData(to: dictionary, isGroupChat: isGroupChat)

          guard self.isInitialChatMessagesLoad else {
            print("not initial")
            self.handleMessageInsertionInRuntime(newDictionary: dictionary)
            return
          }
          print("initial")
          loadedMessages.append(Message(dictionary: dictionary))
          loadedMessagesGroup.leave()
        })
      })
    }
  }

  func handleMessageInsertionInRuntime(newDictionary: [String:AnyObject]) {
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    let message = Message(dictionary: newDictionary)
    let isOutBoxMessage = message.fromId == currentUserID || message.fromId == message.toId

    self.loadUserNameForOneMessage(message: message) { [unowned self] (_, messageWithName) in
      if !isOutBoxMessage {
        self.collectionDelegate?.collectionView(update: messageWithName, reference: self.messagesReference)
      } else {
        if let isInformationMessage = message.isInformationMessage, isInformationMessage {
          self.collectionDelegate?.collectionView(update: messageWithName, reference: self.messagesReference)
        } else {
          self.collectionDelegate?.collectionView(updateStatus: self.messagesReference, message: messageWithName)
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
      print("names entering")
    }

    loadedUserNamesGroup.notify(queue: .main, execute: {
      print("loadedUserNamesGroup group finished ")
      self.loadingNamesGroup.leave()
    })

    for index in 0...messages.count - 1 {
      guard let senderID = messages[index].fromId else { print("continuing"); continue }
      let reference = Database.database().reference().child("users").child(senderID)//.child("name")
      reference.observeSingleEvent(of: .value, with: { (snapshot) in
        guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
        let user = User(dictionary: dictionary)
        guard let name = user.name else {  loadedUserNamesGroup.leave(); return }
        self.messages[index].senderName = name
        loadedUserNamesGroup.leave()
        print("names leaving")
      })
    }
  }

  func sortedMessages(unsortedMessages: [Message]) -> [Message] {
    let sortedMessages = unsortedMessages.sorted(by: { (message1, message2) -> Bool in
      return message1.timestamp!.int32Value < message2.timestamp!.int32Value
    })
    return sortedMessages
  }

  func preloadCellData(to dictionary: [String: AnyObject], isGroupChat: Bool) -> [String: AnyObject] {
    var dictionary = dictionary
    if let messageText = Message(dictionary: dictionary).text { /* pre-calculateCellSizes */
      dictionary.updateValue(estimateFrameForText(messageText) as AnyObject, forKey: "estimatedFrameForText" )
    } else if let imageWidth = Message(dictionary: dictionary).imageWidth?.floatValue,
      let imageHeight = Message(dictionary: dictionary).imageHeight?.floatValue {
      let cellHeight = CGFloat(imageHeight / imageWidth * 200).rounded()
      dictionary.updateValue(cellHeight as AnyObject, forKey: "imageCellHeight")
    }

    if let voiceEncodedString = Message(dictionary: dictionary).voiceEncodedString,
      let decoded = Data(base64Encoded: voiceEncodedString) { /* pre-encoding voice messages */
      let duration = self.getAudioDurationInHours(from: decoded) as AnyObject
      let startTime = self.getAudioDurationInSeconds(from: decoded) as AnyObject
      dictionary.updateValue(decoded as AnyObject, forKey: "voiceData")
      dictionary.updateValue(duration, forKey: "voiceDuration")
      dictionary.updateValue(startTime, forKey: "voiceStartTime")
    }

    if let messageTimestamp = Message(dictionary: dictionary).timestamp {  /* pre-converting timeintervals into dates */
      let date = Date(timeIntervalSince1970: TimeInterval(truncating: messageTimestamp))
      let convertedTimestamp = timestampOfChatLogMessage(date) as AnyObject
      dictionary.updateValue(convertedTimestamp, forKey: "convertedTimestamp")
    }

    return dictionary
  }

  func estimateFrameForText(_ text: String) -> CGRect {
    let size = CGSize(width: 200, height: 10000)
    let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
		let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)]
    return text.boundingRect(with: size, options: options, attributes: attributes, context: nil).integral
  }

  func estimateFrameForText(width: CGFloat, text: String, font: UIFont) -> CGRect {
    let size = CGSize(width: width, height: 10000)
    let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
		let attributes = [NSAttributedString.Key.font: font]
    return text.boundingRect(with: size, options: options, attributes: attributes, context: nil).integral
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
      print("error playing")
      return String(format: "%02i:%02i:%02i", 0, 0, 0)
    }
  }

  func getAudioDurationInSeconds(from data: Data) -> Int? {
    do {
      chatLogAudioPlayer = try AVAudioPlayer(data: data)
      let duration = Int(chatLogAudioPlayer.duration)
      return duration
    } catch {
      print("error playing")
      return nil
    }
  }
}
