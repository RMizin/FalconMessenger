//
//  ChatLogViewController+GroupMembersDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension ChatLogViewController: GroupMembersManagerDelegate {
  
  func updateName(name: String) {
		try! realm.safeWrite {
    	self.conversation?.chatName = name
		}
    if self.isCurrentUserMemberOfCurrentGroup() {
      self.configureTitleViewWithOnlineStatus()
    }
  }
  
  func updateAdmin(admin: String) {
		try! realm.safeWrite {
			 self.conversation?.admin = admin
		}

  }
  
  func addMember(id: String) {
    guard let members = self.conversation?.chatParticipantsIDs else { return }
		if let _ = members.firstIndex(where: { (memberID) -> Bool in
      return memberID == id }) {
    } else {

			try! realm.safeWrite {
				self.conversation?.chatParticipantsIDs.append(id)
			}

      self.changeUIAfterChildAddedIfNeeded()
    }
  }
  
  func removeMember(id: String) {
    guard let members = self.conversation?.chatParticipantsIDs else { return }
		guard let memberIndex = members.firstIndex(where: { (memberID) -> Bool in
      return memberID == id
    }) else { return }

		try! realm.safeWrite {
			self.conversation?.chatParticipantsIDs.remove(at: memberIndex)
		}
		
    self.changeUIAfterChildRemovedIfNeeded()
  }

  func isCurrentUserMemberOfCurrentGroup() -> Bool {
    guard let membersIDs = conversation?.chatParticipantsIDs,
          let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) else { return false }
    return true
  }
  
  fileprivate func changeUIAfterChildAddedIfNeeded() {
    if isCurrentUserMemberOfCurrentGroup() {
      configureTitleViewWithOnlineStatus()
      if typingIndicatorReference == nil {
        reloadInputViews()
        reloadInputView(view: inputContainerView)
        observeTypingIndicator()
        addChatsControllerTypingObserver()
        navigationItem.rightBarButtonItem?.isEnabled = true
      }
    }
  }
  
 fileprivate func changeUIAfterChildRemovedIfNeeded() {
    if isCurrentUserMemberOfCurrentGroup() {
      configureTitleViewWithOnlineStatus()
    } else {
      self.inputContainerView.resignAllResponders()
      handleTypingIndicatorAppearance(isEnabled: false)
      removeSubtitleInGroupChat()
      reloadInputViews()
      reloadInputView(view: inputBlockerContainerView)
      removeChatsControllerTypingObserver()
      navigationItem.rightBarButtonItem?.isEnabled = false
      if typingIndicatorReference != nil {
        typingIndicatorReference.removeObserver(withHandle: typingIndicatorHandle)
        typingIndicatorReference = nil
      }
      guard DeviceType.isIPad else { return }
      presentedViewController?.dismiss(animated: true, completion: nil)
    }
  }
  
  fileprivate func removeChatsControllerTypingObserver() {
    guard let chatID = conversation?.chatID else { return }
    typingIndicatorManager.removeTypingIndicator(for: chatID)
  }
  
  fileprivate func addChatsControllerTypingObserver() {
    guard let chatID = conversation?.chatID else { return }
    typingIndicatorManager.observeChangesForDefaultTypingIndicator(with: chatID)
    typingIndicatorManager.observeChangesForGroupTypingIndicator(with: chatID)
  }
  
  fileprivate func removeSubtitleInGroupChat() {
    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat, let title = conversation?.chatName {
      let subtitle = ""
      navigationItem.setTitle(title: title, subtitle: subtitle)
      return
    }
  }
}
