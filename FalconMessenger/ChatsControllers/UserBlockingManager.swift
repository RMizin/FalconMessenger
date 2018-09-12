//
//  UserBlockingManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/11/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

class UserBlockingManager: NSObject {
  
  func blockUser(userID: String) {
   changeBlockedState(to: true, userID: userID)
  }
  
  func unblockUser(userID: String) {
    changeBlockedState(to: false, userID: userID)
  }
  
  fileprivate func changeBlockedState(to state: Bool, userID: String) {
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    ARSLineProgress.show()
    let reference = Database.database().reference()
      .child("user-messages").child(currentUserID).child(userID)
      .child(messageMetaDataFirebaseFolder)//.child("banned")
    
    if state == true {
      updateBlacklist(add: true, userID: userID)
    } else {
      updateBlacklist(remove: true, userID: userID)
    }
    
    reference.updateChildValues(["banned": state]) { (error, _) in
      guard error == nil else {
        ARSLineProgress.showFail()
        return
      }
      ARSLineProgress.hide()
    }
  }
  
  fileprivate func updateBlacklist(remove: Bool = false, add: Bool = false, userID: String) {
    guard remove != false || add != false else { return }
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    
    // you banned your partner
    let currentUserBanned = Database
      .database(url: GlobalDataStorage.reportDatabaseURL).reference().child("blacklists").child(currentUserID).child("banned")
  
    let companionBannedBy = Database
      .database(url: GlobalDataStorage.reportDatabaseURL).reference().child("blacklists").child(userID).child("bannedBy")
    
    if remove == true {
      currentUserBanned.child(userID).removeValue()
      companionBannedBy.child(currentUserID).removeValue()
      return
    }
    
    if add == true {
      currentUserBanned.updateChildValues([userID: userID])
      companionBannedBy.updateChildValues([currentUserID: currentUserID])
      return
    }
  }
}
