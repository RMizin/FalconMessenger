//
//  ChatLogViewController+UserBlockDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/11/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension ChatLogViewController: UserBlockDelegate {
  
  func blockUser(with uid: String) {
    if DeviceType.isIPad {
      presentedViewController?.dismiss(animated: true, completion: nil)
    } else {
      navigationController?.popViewController(animated: true)
    }
    userBlockingManager.blockUser(userID: uid)
  }
  
  @objc func unblock() {
    guard let userID = conversation?.chatID else { return }
    userBlockingManager.unblockUser(userID: userID)
  }
  
  func removeBanObservers() {
    if currentUserBanReference != nil && currentUserBanAddedHandle != nil &&  currentUserBanChangedHandle != nil {
      currentUserBanReference.removeObserver(withHandle: currentUserBanAddedHandle)
      currentUserBanReference.removeObserver(withHandle: currentUserBanChangedHandle)
    }
    
    if companionBanReference != nil && companionBanAddedHandle != nil && companionBanChangedHandle != nil {
      companionBanReference.removeObserver(withHandle: companionBanAddedHandle)
      companionBanReference.removeObserver(withHandle: companionBanChangedHandle)
    }
  }
  
  func observeBlockChanges() {
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID else { return }
    
    var isYouHasBeenBlocked = false
    var isYouBlockedSomebody = false

    let reference = Database.database(url: globalVariables.reportDatabaseURL).reference()
    currentUserBanReference = reference.child("blacklists").child(currentUserID).child("banned")
    companionBanReference = reference.child("blacklists").child(currentUserID).child("bannedBy")
  
    currentUserBanAddedHandle = currentUserBanReference.observe(.childAdded, with: { (snapshot) in
      if snapshot.key == conversationID {
        isYouBlockedSomebody = true
        self.handleBlockUI(isYouHasBeenBlocked, isYouBlockedSomebody)
      }
    })
    
    currentUserBanChangedHandle = currentUserBanReference.observe(.childRemoved, with: { (snapshot) in
       if snapshot.key == conversationID {
        isYouBlockedSomebody = false
        self.handleBlockUI(isYouHasBeenBlocked, isYouBlockedSomebody)
      }
    })
    
    companionBanAddedHandle = companionBanReference.observe(.childAdded, with: { (snapshot) in
      print("shild added \(snapshot.key)")
      if snapshot.key == conversationID {
        isYouHasBeenBlocked = true
        self.handleBlockUI(isYouHasBeenBlocked, isYouBlockedSomebody)
      }
    })
    
    companionBanChangedHandle = companionBanReference.observe(.childRemoved, with: { (snapshot) in
       print("shild removed \(snapshot.key)")
      if snapshot.key == conversationID {
        isYouHasBeenBlocked = false
        self.handleBlockUI(isYouHasBeenBlocked, isYouBlockedSomebody)
      }
    })
  }
  
  fileprivate func handleBlockUI(_ isYouHasBeenBlocked: Bool, _ isYouBlockedSomebody: Bool) {
    self.reloadInputViews()
    if isYouHasBeenBlocked && isYouBlockedSomebody || isYouBlockedSomebody && !isYouHasBeenBlocked {
      reloadInputView(view: unblockContainerView)
      navigationItem.rightBarButtonItem?.isEnabled = false
      isTyping = false
    } else if isYouHasBeenBlocked && !isYouBlockedSomebody {
      reloadInputView(view: userBlockedContainerView)
      navigationItem.rightBarButtonItem?.isEnabled = false
      isTyping = false
    } else if !isYouHasBeenBlocked && !isYouBlockedSomebody {
      reloadInputView(view: inputContainerView)
      navigationItem.rightBarButtonItem?.isEnabled = true
    }
  }
}
