//
//  TypingIndicatorManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 4/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


protocol TypingIndicatorDelegate: class {
  func typingIndicator(isActive: Bool, for chatID: String)
}

private let typingIndicatorDatabaseID = "typingIndicator"

let typingIndicatorManager = TypingIndicatorManager()

class TypingIndicatorManager: NSObject {
  
  weak var delegate: TypingIndicatorDelegate?
  
  var typingIndicatorReference: DatabaseReference!
  var groupTypingIndicatorReference: DatabaseReference!

  var typingChangesHandle = [(handle: DatabaseHandle, chatID: String)]()
  var groupTypingChangesHandle = [(handle: DatabaseHandle, chatID: String)]()
  
  func observeChangesForGroupTypingIndicator(with chatID: String) {
    
    guard let currentUserID = Auth.auth().currentUser?.uid, currentUserID != chatID else { return }
    groupTypingIndicatorReference = Database.database().reference().child("groupChatsTemp").child(chatID).child(typingIndicatorDatabaseID)
    let handle = DatabaseHandle()
    let element = (handle: handle, chatID: chatID)
    groupTypingChangesHandle.insert(element, at: 0)
    groupTypingChangesHandle[0].handle = groupTypingIndicatorReference.observe(.value, with: { (snapshot) in
   
      guard let dictionary = snapshot.value as? [String:AnyObject], let firstKey = dictionary.first?.key else {
        self.delegate?.typingIndicator(isActive: false, for: chatID)
        return
      }
      if firstKey == currentUserID && dictionary.count == 1 {
        self.delegate?.typingIndicator(isActive: false, for: chatID)
        return
      }
      self.delegate?.typingIndicator(isActive: true, for: chatID)
    })
  }
  
  func observeChangesForDefaultTypingIndicator(with chatID: String) {
    
    guard let currentUserID = Auth.auth().currentUser?.uid, currentUserID != chatID else { return }
    typingIndicatorReference = Database.database().reference().child("user-messages").child(chatID).child(currentUserID).child(typingIndicatorDatabaseID).child(chatID)
    let handle = DatabaseHandle()
    let element = (handle: handle, chatID: chatID)
    typingChangesHandle.insert(element, at: 0)
    typingChangesHandle[0].handle = typingIndicatorReference.observe(.value, with: { (snapshot) in

      guard let isParticipantTyping = snapshot.value! as? Bool, isParticipantTyping else {
        self.delegate?.typingIndicator(isActive: false, for: chatID)
        return
      }
      self.delegate?.typingIndicator(isActive: true, for: chatID)
    })
  }
  
  func removeTypingIndicator(for removedChatID: String) {
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    
    if typingIndicatorReference != nil {
			guard let index = typingChangesHandle.firstIndex(where: { (element) -> Bool in
        return element.chatID == removedChatID
      }) else { return }
  
      let chatID = typingChangesHandle[index].chatID
      typingIndicatorReference = Database.database().reference().child("user-messages").child(chatID).child(currentUserID).child(typingIndicatorDatabaseID).child(chatID)
      typingIndicatorReference.removeObserver(withHandle: typingChangesHandle[index].handle)
      typingChangesHandle.remove(at: index)
    }
    
    if groupTypingIndicatorReference != nil {
			guard let index = groupTypingChangesHandle.firstIndex(where: { (element) -> Bool in
        return element.chatID == removedChatID
      }) else { return }
   
      let chatID = groupTypingChangesHandle[index].chatID
      groupTypingIndicatorReference = Database.database().reference().child("groupChatsTemp").child(chatID).child(typingIndicatorDatabaseID)
      groupTypingIndicatorReference.removeObserver(withHandle: groupTypingChangesHandle[index].handle)
      groupTypingChangesHandle.remove(at: index)
      self.delegate?.typingIndicator(isActive: false, for: removedChatID)
    }
  }
}
