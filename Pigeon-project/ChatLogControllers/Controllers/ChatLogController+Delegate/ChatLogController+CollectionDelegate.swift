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
  
  func collectionView(updateStatus reference: DatabaseReference, message: Message) {

    reference.observe(.childChanged, with: { (snapshot) in
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
  
  func collectionView(update message: Message, reference: DatabaseReference) {
    
    let insertionIndex = messages.insertionIndexOf(elem: message, isOrderedBefore: { (message1, message2) -> Bool in
      return Int(truncating: message1.timestamp!) < Int(truncating: message2.timestamp!)
    })
    self.messages.insert(message, at: insertionIndex)
    self.collectionView?.performBatchUpdates ({
      let indexPath = IndexPath(item: insertionIndex, section: 0)
      self.collectionView?.insertItems(at: [indexPath])
      
      if self.messages.count - 2 >= 0 {
        self.collectionView?.reloadItems(at: [IndexPath (row: self.messages.count - 2, section: 0)])
      }
      
      if self.messages.count - 1 >= 0 && self.isScrollViewAtTheBottom {
        let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
        
        DispatchQueue.main.async {
          self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
      }
    }, completion: { (_) in
      self.updateMessageStatus(messageRef: reference)
    })
  }
}
