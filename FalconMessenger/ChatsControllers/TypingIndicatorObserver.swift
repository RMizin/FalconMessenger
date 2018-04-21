//
//  TypingIndicatorObserver.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 4/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


protocol TypingIndicatorDelegate: class {
  func typingIndicator(isActive: Bool, for conversation: Conversation)
}

class TypingIndicatorObserver: NSObject {
  
  var typingIndicatorReference = DatabaseReference()
  var typingIndicatorHandle = [DatabaseHandle]()
  
  var groupTypingIndicatorReference = DatabaseReference()
  var groupTypingIndicatorHandle = [DatabaseHandle]()
  
  let typingIndicatorDatabaseID = "typingIndicator"
  weak var delegate: TypingIndicatorDelegate?
  
  func observeTypingIndicator(conversations: [Conversation]?) {
   // removeTypingObservers()
   // removeGroupTypingObservers()
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversations = conversations else { return }
   
    for conversation in conversations {
      guard let conversationID = conversation.chatID, currentUserID != conversationID else { return }
      if let isGroupChat = conversation.isGroupChat, isGroupChat {
        self.handleGroupChatTypingIndicatorObserving(currentUserID: currentUserID, conversationID: conversationID, conversation: conversation)
      } else {
        self.handleDefaultChatTypingIndicatorObserving(currentUserID: currentUserID, conversationID: conversationID, conversation: conversation)
      }
    }
  }
  
//  func observeTypingIndicator(forSingle conversation: Conversation?) {
//     guard let currentUserID = Auth.auth().currentUser?.uid, let conversation = conversation else { return }
//     guard let conversationID = conversation.chatID, currentUserID != conversationID else { return }
//      if let isGroupChat = conversation.isGroupChat, isGroupChat {
//        self.handleGroupChatTypingIndicatorObserving(currentUserID: currentUserID, conversationID: conversationID, conversation: conversation)
//      } else {
//        self.handleDefaultChatTypingIndicatorObserving(currentUserID: currentUserID, conversationID: conversationID, conversation: conversation)
//      }
//  }
  
  func handleGroupChatTypingIndicatorObserving(currentUserID: String, conversationID: String, conversation: Conversation) {
   
    groupTypingIndicatorReference = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID)
    let handle = DatabaseHandle()
    groupTypingIndicatorHandle.insert(handle, at: 0)
    groupTypingIndicatorHandle[0] = groupTypingIndicatorReference.observe(.value, with: { (snapshot) in
      guard let dictionary = snapshot.value as? [String:AnyObject], let firstKey = dictionary.first?.key else {
        self.delegate?.typingIndicator(isActive: false, for: conversation)
        return
      }
      
      if firstKey == currentUserID && dictionary.count == 1 {
        self.delegate?.typingIndicator(isActive: false, for: conversation)
        return
      }
      self.delegate?.typingIndicator(isActive: true, for: conversation)
    })
  }
  
  func handleDefaultChatTypingIndicatorObserving(currentUserID: String, conversationID: String, conversation: Conversation) {
   
    typingIndicatorReference = Database.database().reference().child("user-messages").child(conversationID).child(currentUserID)
      .child(typingIndicatorDatabaseID).child(conversationID)

    let handle = DatabaseHandle()
    typingIndicatorHandle.insert(handle, at: 0)
    typingIndicatorHandle[0] = typingIndicatorReference.observe(.value, with: { (isTyping) in
      
      guard let isParticipantTyping = isTyping.value! as? Bool, isParticipantTyping else {
        self.delegate?.typingIndicator(isActive: false, for: conversation)
        return
      }
      self.delegate?.typingIndicator(isActive: true, for: conversation)
    })
  }
  
//  func removeTypingObservers() {
//    //guard typingIndicatorReference != nil else { return }
//   // for handle in typingIndicatorHandle {
//      typingIndicatorReference.removeAllObservers()//removeObserver(withHandle: handle)
//   // }
//    typingIndicatorHandle.removeAll()
//
//  }
//  
//  func removeGroupTypingObservers() {
//   // guard groupTypingIndicatorReference != nil else { return }
//   // for handle in groupTypingIndicatorHandle {
//      groupTypingIndicatorReference.removeAllObservers()//removeObserver(withHandle: handle)
//  //  }
//    groupTypingIndicatorHandle.removeAll()
//  }
  
  
  deinit {
    print("\nTyping observer deinit\n")
  }
}
