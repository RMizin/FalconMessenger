//
//  ChatLogController+GroupMembersDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension ChatLogController: GroupMembersManagerDelegate {
  
  func updateName(name: String) {
    self.conversation?.chatName = name
    if self.isCurrentUserMemberOfCurrentGroup() {
      self.configureTitleViewWithOnlineStatus()
    }
  }
  
  func updateAdmin(admin: String) {
    self.conversation?.admin = admin
  }
  
  func addMember(id: String) {
    guard let members = self.conversation?.chatParticipantsIDs else { return }
    
		if let _ = members.firstIndex(where: { (memberID) -> Bool in
      return memberID == id }) {
    } else {
      self.conversation?.chatParticipantsIDs?.append(id)
      self.changeUIAfterChildAddedIfNeeded()
    }
  }
  
  func removeMember(id: String) {
    guard let members = self.conversation?.chatParticipantsIDs else { return }
    
		guard let memberIndex = members.firstIndex(where: { (memberID) -> Bool in
      return memberID == id
    }) else { return }
    
    
    self.conversation?.chatParticipantsIDs?.remove(at: memberIndex)
    self.changeUIAfterChildRemovedIfNeeded()
  }
  
  
  func isCurrentUserMemberOfCurrentGroup() -> Bool {
    guard let membersIDs = conversation?.chatParticipantsIDs,
      let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) else { return false }
    return true
  }
  
  func changeUIAfterChildAddedIfNeeded() {
    if isCurrentUserMemberOfCurrentGroup() {
      configureTitleViewWithOnlineStatus()
      if typingIndicatorReference == nil {
        reloadInputViews()
        observeTypingIndicator()
        navigationItem.rightBarButtonItem?.isEnabled = true
      }
    }
  }
  
  func changeUIAfterChildRemovedIfNeeded() {
    if isCurrentUserMemberOfCurrentGroup() {
      configureTitleViewWithOnlineStatus()
    } else {
      inputContainerView.inputTextView.resignFirstResponder()
      handleTypingIndicatorAppearance(isEnabled: false)
      removeSubtitleInGroupChat()
      reloadInputViews()
      navigationItem.rightBarButtonItem?.isEnabled = false
      guard typingIndicatorReference != nil else { return }
      typingIndicatorReference.removeAllObservers()
      typingIndicatorReference = nil
    }
  }
  
  fileprivate func removeSubtitleInGroupChat() {
    if let isGroupChat = conversation?.isGroupChat, isGroupChat, let title = conversation?.chatName {
      let subtitle = ""
      navigationItem.setTitle(title: title, subtitle: subtitle)
      return
    }
  }
}
