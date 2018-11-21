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
		guard let childRefKey = childRef.key else { return }
    
    guard let toId = chatID, let fromId = Auth.auth().currentUser?.uid else { return }

    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    let values: [String: AnyObject] = ["messageUID": childRefKey as AnyObject,
                                       "toId": toId as AnyObject,
                                       "status": defaultMessageStatus as AnyObject,
                                       "seen": false as AnyObject,
                                       "fromId": fromId as AnyObject,
                                       "timestamp": timestamp,
                                       "text": text as AnyObject,
                                       "isInformationMessage": true as AnyObject]
    childRef.updateChildValues(values) { (error, _) in
      
      guard error == nil else { return }
      
			guard let messageID = childRef.key else { return }
      let groupMessagesRef = Database.database().reference().child("groupChats").child(toId).child(userMessagesFirebaseFolder)
      groupMessagesRef.updateChildValues([messageID: fromId])
      
      //needed to update ui for current user as fast as possible
      //for other members this update handled by backend
      let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(userMessagesFirebaseFolder)
      userMessagesRef.updateChildValues([messageID: fromId])
      self.updateLastMessageForSelf(chatID: chatID, messageID: messageID)
    }
  }

  func updateLastMessageForSelf(chatID: String?, messageID: String) {
    guard let conversationID = chatID, let fromID = Auth.auth().currentUser?.uid else { return }
    let ref = Database.database().reference().child("user-messages").child(fromID).child(conversationID).child(messageMetaDataFirebaseFolder)
    let childValues: [String: Any] = ["lastMessageID": messageID]
    ref.updateChildValues(childValues)
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
