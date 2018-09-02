//
//  ChatLogController+CollectionDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension ChatLogViewController: CollectionDelegate {
  
  func collectionView(shouldRemoveMessage id: String) {
    guard let index = self.messages.index(where: { (message) -> Bool in
      return message.messageUID == id
    }) else { return }
    performBatchUpdates(for: index, id: id)
  }
  
  func performBatchUpdates(for index: Int, id: String) {
    guard let messagesFetcher = messagesFetcher else { return }
    let removedMessage = messages[index]
    messages.remove(at: index)
    messages = messagesFetcher.configureTails(for: messages, isGroupChat: nil)
 
    guard let indexPath = Message.get(indexPathOf: removedMessage, in: groupedMessages) else { return }
    
    let currentSectionsCount = groupedMessages.count
    groupedMessages = Message.groupedMessages(messages)
    
    collectionView.performBatchUpdates({
      if currentSectionsCount > self.groupedMessages.count {
         collectionView.deleteSections([indexPath.section])
      } else {
        collectionView.deleteItems(at: [indexPath])
      }
    }) { (_) in
      UIView.performWithoutAnimation {
        if currentSectionsCount > self.groupedMessages.count {
          guard indexPath.section-1 >= 0 else { return }
          self.collectionView.reloadSections([indexPath.section-1])
        } else {
          self.collectionView.reloadSections([indexPath.section])
        }
      }
      guard self.messages.count == 0 else { return }
      self.navigationController?.popViewController(animated: true)
    }
  }
  
  func collectionView(shouldUpdateOutgoingMessageStatusFrom reference: DatabaseReference, message: Message) {
    
    guard let messageID = message.messageUID else { return }
    let handle = DatabaseHandle()
    
    messageChangesHandles.insert((uid:messageID, handle:handle), at: 0)
    
    messageChangesHandles[0].handle = reference.observe(.childChanged, with: { (snapshot) in
      guard snapshot.exists(), snapshot.key == "status", let newMessageStatus = snapshot.value  else { return }
      message.status = newMessageStatus as? String
      self.updateMessageStatusUI(sentMessage: message)
    })
    
    self.updateMessageStatus(messageRef: reference)
    self.updateMessageStatusUI(sentMessage: message)
  }
  
  func sortedMessages(unsortedMessages: [Message]) -> [Message] {
    let sortedMessages = unsortedMessages.sorted(by: { (message1, message2) -> Bool in
      return message1.timestamp!.int32Value < message2.timestamp!.int32Value
    })
    return sortedMessages
  }
  
  func collectionView(shouldBeUpdatedWith message: Message, reference: DatabaseReference) {
    
    let insertionIndex = self.messages.insertionIndexOf(elem: message, isOrderedBefore: { (message1, message2) -> Bool in
      return message1.messageUID! < message2.messageUID!
    })
    
    guard let _ = self.messages.index(where: { (existentMessage) -> Bool in
      return existentMessage.messageUID == message.messageUID
    }) else {
      peformBatchUpdate(for: message, at: insertionIndex, reference: reference)
      return
    }
  }
  
  fileprivate func peformBatchUpdate(for message: Message, at insertionIndex: Int, reference: DatabaseReference) {
    messages.insert(message, at: insertionIndex)
    guard let messagesFetcher = messagesFetcher else { return }
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      messages = messagesFetcher.configureTails(for: messages, isGroupChat: true)
    } else {
      messages = messagesFetcher.configureTails(for: messages, isGroupChat: false)
    }
    
    let oldSections = groupedMessages.count
    groupedMessages = Message.groupedMessages(messages)
    guard let indexPath = Message.get(indexPathOf: message, in: groupedMessages) else { return }
    
    collectionView.performBatchUpdates({
      if oldSections < groupedMessages.count {
        collectionView.insertSections([indexPath.section])
        //TODO: scroll to bottom
      } else {
        collectionView.insertItems(at: [indexPath])
        //TODO: scroll to bottom
      }
      
    }) { (_) in
      self.updateMessageStatus(messageRef: reference)
      guard oldSections == self.groupedMessages.count else { return }
      UIView.performWithoutAnimation {
        self.collectionView.reloadSections([indexPath.section])
      }
      guard self.isScrollViewAtTheBottom() else { return }
      self.collectionView.scrollToBottom(animated: true)
    }
  }
}
