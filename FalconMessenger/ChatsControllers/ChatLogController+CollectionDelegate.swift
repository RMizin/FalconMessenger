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

   // print("\nINDEX IS \(index) - REMOVING \n")
    performBatchUpdates(for: index)
  }
  
  func performBatchUpdates(for index: Int) {
    
    UIView.performWithoutAnimation {
      
      messages.remove(at: index)
      if let isGroupChat = conversation?.isGroupChat, isGroupChat {
        messages = messagesFetcher.configureMessageTails(messages: messages, isGroupChat: true)
      } else {
        messages = messagesFetcher.configureMessageTails(messages: messages, isGroupChat: false)
      }
      
      self.collectionView?.performBatchUpdates ({
        self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
        
        let startIndex = index - 2
        let endIndex = index + 2
        var indexPaths = [IndexPath]()
        for indexToUpdate in startIndex...endIndex {
          if self.messages.indices.contains(indexToUpdate) && indexToUpdate != index {
            let indexPath = IndexPath(item: indexToUpdate, section: 0)
            indexPaths.append(indexPath)
          }
        }
        self.collectionView?.reloadItems(at: indexPaths)
        
      }, completion: { (completed) in
        guard self.messages.count == 0 else {
         //  guard shouldReloadMessageStatus, let lastMessage = self.chatLogController?.messages.last else { return }
        //  self.chatLogController?.updateMessageStatusUIAfterDeletion(sentMessage: lastMessage)
          return
        }
        self.navigationController?.popViewController(animated: true)
      })
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
  
  func collectionView(shouldBeUpdatedWith message: Message,reference: DatabaseReference) {
    
    let insertionIndex = self.messages.insertionIndexOf(elem: message, isOrderedBefore: { (message1, message2) -> Bool in
      return Int(truncating: message1.timestamp!) < Int(truncating: message2.timestamp!)
    })
    
     self.messages.insert(message, at: insertionIndex)
    
    if let isGroupChat = self.conversation?.isGroupChat, isGroupChat {
      self.messages = self.messagesFetcher.configureMessageTails(messages: self.messages, isGroupChat: true)
    } else {
      self.messages = self.messagesFetcher.configureMessageTails(messages: self.messages, isGroupChat: false)
    }
    
    self.collectionView?.performBatchUpdates ({
     
      let indexPath = IndexPath(item: insertionIndex, section: 0)
    
      self.collectionView?.insertItems(at: [indexPath])
      
      var indexPaths = [IndexPath]()
      for index in 2..<10 {
        if self.messages.indices.contains(self.messages.count-index) {
          let indexPath = IndexPath(item: self.messages.count-index, section: 0)
          indexPaths.append(indexPath)
        }
      }
      self.collectionView?.reloadItems(at: indexPaths)
    
      if self.messages.count - 1 >= 0 && self.isScrollViewAtTheBottom {
        let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
        
        DispatchQueue.main.async {
          self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
      }
    }, completion: { (true) in
      self.updateMessageStatus(messageRef: reference)
    })
  }
}


