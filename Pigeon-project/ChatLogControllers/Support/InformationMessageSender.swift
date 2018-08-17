//
//  InformationMessageSender.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/25/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

class InformationMessageSender: NSObject {
  
  func sendInformatoinMessage(chatID: String?, membersIDs: [String], text: String) {
    
    let ref = Database.database().reference().child("messages")
    let childRef = ref.childByAutoId()
    let defaultMessageStatus = messageStatusDelivered
    
    guard let toId = chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    let values: [String: AnyObject] = ["messageUID": childRef.key as AnyObject, "toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "text": text as AnyObject, "isInformationMessage": true as AnyObject]
    childRef.updateChildValues(values) { (error, ref) in
      
      guard error == nil else { return }
      
      let messageId = childRef.key
      
      for memberID in membersIDs {
        let userMessagesRef = Database.database().reference().child("user-messages").child(memberID).child(toId).child(userMessagesFirebaseFolder)
        userMessagesRef.updateChildValues([messageId: 1])
      }
      
      self.incrementBadgeForReciever(conversationID: chatID, participantsIDs: membersIDs)
      self.setupMetadataForSender(chatID: chatID)
      self.updateLastMessageForParticipants(chatID: chatID, participantsIDs: membersIDs, messageID: messageId)
    }
  }

  func updateLastMessageForParticipants(chatID: String?, participantsIDs: [String], messageID: String) {
    guard let conversationID = chatID else { return }
    for memberID in participantsIDs {
      let ref = Database.database().reference().child("user-messages").child(memberID).child(conversationID).child(messageMetaDataFirebaseFolder)
      let childValues: [String: Any] = ["lastMessageID": messageID]
      ref.updateChildValues(childValues)
    }
  }

  func setupMetadataForSender(chatID: String?) {
    guard let toId = chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    var ref = Database.database().reference().child("user-messages").child(fromId).child(toId)
    ref.observeSingleEvent(of: .value, with: { (snapshot) in
      guard !snapshot.hasChild(messageMetaDataFirebaseFolder) else { return }
      ref = ref.child(messageMetaDataFirebaseFolder)
      ref.updateChildValues(["badge": 0])
    })
  }

  func incrementBadgeForReciever(conversationID: String?, participantsIDs: [String]) {
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversationID else { return }
    for participantID in participantsIDs {
      if participantID != currentUserID {
        runTransaction(firstChild: participantID, secondChild: conversationID)
      }
    }
  }
}

public func runTransaction(firstChild: String, secondChild: String) {
  
  var ref = Database.database().reference().child("user-messages").child(firstChild).child(secondChild)
  ref.observeSingleEvent(of: .value, with: { (snapshot) in
    
    guard snapshot.hasChild(messageMetaDataFirebaseFolder) else {
      ref = ref.child(messageMetaDataFirebaseFolder)
      ref.updateChildValues(["badge": 1])
      return
    }
    ref = ref.child(messageMetaDataFirebaseFolder).child("badge")
    ref.runTransactionBlock({ (mutableData) -> TransactionResult in
      var value = mutableData.value as? Int
      if value == nil { value = 0 }
      mutableData.value = value! + 1
      return TransactionResult.success(withValue: mutableData)
    })
  })
}

