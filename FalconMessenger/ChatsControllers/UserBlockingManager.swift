//
//  UserBlockingManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/11/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import ARSLineProgress

class UserBlockingManager: NSObject {
  
  func blockUser(userID: String) {
   changeBlockedState(to: true, userID: userID)
  }
  
  func unblockUser(userID: String) {
    changeBlockedState(to: false, userID: userID)
  }
  
  fileprivate func changeBlockedState(to state: Bool, userID: String) {
    if state == true {
      updateBlacklist(add: true, userID: userID)
    } else {
      updateBlacklist(remove: true, userID: userID)
    }
  }
  
  fileprivate func updateBlacklist(remove: Bool = false, add: Bool = false, userID: String) {
    guard remove != false || add != false else { return }
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    ARSLineProgress.show()
    // you banned your partner
    let currentUserBanned = Database.database(url: globalVariables.reportDatabaseURL).reference()
      .child("blacklists").child(currentUserID).child("banned")
  
    let companionBannedBy = Database.database(url: globalVariables.reportDatabaseURL).reference()
      .child("blacklists").child(userID).child("bannedBy")
    
    if remove == true {
      let removingGroup = DispatchGroup()
      removingGroup.enter(); removingGroup.enter()
      removingGroup.notify(queue: .main) {
        ARSLineProgress.hide()
      }
      currentUserBanned.child(userID).removeValue { (error, _) in
        removingGroup.leave()
      }
      companionBannedBy.child(currentUserID).removeValue { (_, _) in
        removingGroup.leave()
      }
      return
    }
    
    if add == true {
      let addingGroup = DispatchGroup()
      addingGroup.enter(); addingGroup.enter()
      addingGroup.notify(queue: .main) {
        ARSLineProgress.hide()
      }
      currentUserBanned.updateChildValues([userID: userID]) { (_, _) in
        addingGroup.leave()
      }
      companionBannedBy.updateChildValues([currentUserID: currentUserID]) { (_, _) in
        addingGroup.leave()
      }
      return
    }
  }
}
