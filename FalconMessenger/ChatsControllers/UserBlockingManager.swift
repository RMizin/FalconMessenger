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
    reference.updateChildValues(["banned": state]) { (error, _) in
      guard error == nil else {
        ARSLineProgress.showFail()
        return
      }
      ARSLineProgress.hide()
    }
  }
}
