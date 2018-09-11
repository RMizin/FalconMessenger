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
    if DeviceType.isIPad  {
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
    
    // observe if you banned somebody
    currentUserBanReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID)
      .child(messageMetaDataFirebaseFolder)
    
    currentUserBanAddedHandle = currentUserBanReference.observe(.childAdded) { (snapshot) in
      guard snapshot.key == "banned" else { return }
      guard let isBanned = snapshot.value as? Bool else { return }
      isYouBlockedSomebody = isBanned
      self.handleBlockUI(isYouHasBeenBlocked, isYouBlockedSomebody)
    }
    
   currentUserBanChangedHandle = currentUserBanReference.observe(.childChanged) { (snapshot) in
      guard snapshot.key == "banned" else { return }
      guard let isBanned = snapshot.value as? Bool else { return }
      isYouBlockedSomebody = isBanned
      self.handleBlockUI(isYouHasBeenBlocked, isYouBlockedSomebody)
    }
    
    //observe is you has been banned by somebody
    companionBanReference = Database.database().reference().child("user-messages").child(conversationID).child(currentUserID)
      .child(messageMetaDataFirebaseFolder)
    
   companionBanAddedHandle = companionBanReference.observe(.childAdded) { (snapshot) in
      guard snapshot.key == "banned" else { return }
      guard let isBanned = snapshot.value as? Bool else { return }
      isYouHasBeenBlocked = isBanned
      self.handleBlockUI(isYouHasBeenBlocked, isYouBlockedSomebody)
    }
    
    companionBanChangedHandle = companionBanReference.observe(.childChanged) { (snapshot) in
      guard snapshot.key == "banned" else { return }
      guard let isBanned = snapshot.value as? Bool else { return }
      isYouHasBeenBlocked = isBanned
      self.handleBlockUI(isYouHasBeenBlocked, isYouBlockedSomebody)
    }
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
