//
//  ChatLogController+CollectionDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension ChatLogController: CollectionDelegate {
  
  func collectionView(shouldRemoveMessage id: String) {
    
    guard let index = self.messages.index(where: { (message) -> Bool in
      return message.messageUID == id
    }) else { return }
    
    performBatchUpdates(for: index)
  }
  
  func performBatchUpdates(for index: Int) {
    
    messages.remove(at: index)
    
  //  if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      messages = messagesFetcher.configureMessageTails(messages: messages, isGroupChat: nil)
 //   } else {
  //    messages = messagesFetcher.configureMessageTails(messages: messages, isGroupChat: false)
 //   }
    
    collectionView?.performBatchUpdates ({
      collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
    }, completion: { (completed) in
      
      let startIndex = index - 2
      let endIndex = index + 2
      var indexPaths = [IndexPath]()
      
      for indexToUpdate in startIndex...endIndex {
        if self.messages.indices.contains(indexToUpdate) /*&& indexToUpdate != index */{
          let indexPath = IndexPath(item: indexToUpdate, section: 0)
          indexPaths.append(indexPath)
        }
      }
      
      UIView.performWithoutAnimation {
        self.collectionView?.reloadItems(at: indexPaths)
        guard self.messages.count == 0 else { return }
        self.navigationController?.popViewController(animated: true)
      }
    })
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
    
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      messages = messagesFetcher.configureMessageTails(messages: messages, isGroupChat: true)
    } else {
      messages = messagesFetcher.configureMessageTails(messages: messages, isGroupChat: false)
    }
    
    collectionView?.performBatchUpdates ({
      let indexPath = IndexPath(item: insertionIndex, section: 0)
      
      collectionView?.insertItems(at: [indexPath])
      
      if messages.count - 1 >= 0 && isScrollViewAtTheBottom {
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        DispatchQueue.main.async { [unowned self] in
          self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
      }
    }, completion: { (true) in
      
      UIView.performWithoutAnimation {
        var indexPaths = [IndexPath]()
        for index in 2..<10 {
          if self.messages.indices.contains(self.messages.count-index) {
            let indexPath = IndexPath(item: self.messages.count-index, section: 0)
            indexPaths.append(indexPath)
          }
        }
        self.collectionView?.reloadItems(at: indexPaths)
      }
      
      self.updateMessageStatus(messageRef: reference)
    })
  }
}
