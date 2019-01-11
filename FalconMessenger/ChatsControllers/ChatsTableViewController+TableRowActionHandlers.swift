//
//  ChatsTableViewController+TableRowActionHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/14/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

private let pinErrorTitle = "Error pinning/unpinning"
private let pinErrorMessage = "Changes won't be saved across app restarts. Check your internet connection, re-launch the app, and try again."
private let muteErrorTitle = "Error muting/unmuting"
private let muteErrorMessage = "Check your internet connection and try again."

extension ChatsTableViewController {
  
  func setupMuteAction(at indexPath: IndexPath) -> UITableViewRowAction {
    let mute = UITableViewRowAction(style: .default, title: "Mute") { _, _ in
			self.hapticFeedback()
      if indexPath.section == 0 {
        if #available(iOS 11.0, *) {} else {
          self.tableView.setEditing(false, animated: true)
        }
        self.delayWithSeconds(1, completion: {
          self.handleMuteConversation(section: indexPath.section, for: self.realmPinnedConversations[indexPath.row])
        })
      } else if indexPath.section == 1 {
        if #available(iOS 11.0, *) {} else {
          self.tableView.setEditing(false, animated: true)
        }
        self.delayWithSeconds(1, completion: {
          self.handleMuteConversation(section: indexPath.section, for: self.realmUnpinnedConversations[indexPath.row])
        })
      }
    }
    
    if indexPath.section == 0 {
      let isPinnedConversationMuted = realmPinnedConversations[indexPath.row].muted.value == true
      let muteTitle = isPinnedConversationMuted ? "Unmute" : "Mute"
      mute.title = muteTitle
    } else if indexPath.section == 1 {
      let isConversationMuted = realmUnpinnedConversations[indexPath.row].muted.value == true
      let muteTitle = isConversationMuted ? "Unmute" : "Mute"
      mute.title = muteTitle
    }
    mute.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
    return mute
  }
  
  func setupPinAction(at indexPath: IndexPath) -> UITableViewRowAction {
    let pin = UITableViewRowAction(style: .default, title: "Pin") { _, _ in
			self.hapticFeedback()
      if indexPath.section == 0 {
        self.unpinConversation(at: indexPath)
      } else if indexPath.section == 1 {
        self.pinConversation(at: indexPath)
      }
    }
    
    let pinTitle = indexPath.section == 0 ? "Unpin" : "Pin"
    pin.title = pinTitle
    pin.backgroundColor = UIColor(red: 0.18, green: 0.26, blue: 0.31, alpha: 1.0)
    return pin
  }
  
  func setupDeleteAction(at indexPath: IndexPath) -> UITableViewRowAction {
    let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
			self.hapticFeedback()
      self.deleteConversation(at: indexPath)
    }
    
    delete.backgroundColor = UIColor(red: 0.93, green: 0.11, blue: 0.15, alpha: 1.0)
    return delete
  }

  func unpinConversation(at indexPath: IndexPath) {
    let conversation = realmPinnedConversations[indexPath.row]
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID else { return }

		if !realmManager.realm.isInWriteTransaction {
			realmManager.realm.beginWrite()
			realmPinnedConversations[indexPath.row].pinned.value = false
					try! realmManager.realm.commitWrite(withoutNotifying: [unpinnedConversationsNotificationToken!, pinnedConversationsNotificationToken!])

			let indexToInsert = realmUnpinnedConversations.insertionIndex(of: conversation, using: { (conversation1, conversation2) -> Bool in
				return conversation1.lastMessage?.timestamp.value ?? 0 > conversation2.lastMessage?.timestamp.value ?? 0
			})

			let destinationIndexPath = IndexPath(row: indexToInsert, section: 1)

			tableView.beginUpdates()
			tableView.setEditing(false, animated: true)
			tableView.moveRow(at: indexPath, to: destinationIndexPath)
			tableView.endUpdates()
		}


    let metadataRef = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(messageMetaDataFirebaseFolder)
    metadataRef.updateChildValues(["pinned": false], withCompletionBlock: { (error, reference) in
      if error != nil {
        basicErrorAlertWith(title: pinErrorTitle , message: pinErrorMessage, controller: self)
        return
      }
    })
  }

  func pinConversation(at indexPath: IndexPath) {
    let conversation = realmUnpinnedConversations[indexPath.row]
   	guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID else { return }

		if !realmManager.realm.isInWriteTransaction {
			realmManager.realm.beginWrite()
			realmUnpinnedConversations[indexPath.row].pinned.value = true
			try! realmManager.realm.commitWrite(withoutNotifying: [unpinnedConversationsNotificationToken!, pinnedConversationsNotificationToken!])

			let indexToInsert = realmPinnedConversations.insertionIndex(of: conversation, using: { (conversation1, conversation2) -> Bool in
				return conversation1.lastMessage?.timestamp.value ?? 0 > conversation2.lastMessage?.timestamp.value ?? 0
			})

			let destinationIndexPath = IndexPath(row: indexToInsert, section: 0)

			tableView.beginUpdates()
			tableView.setEditing(false, animated: true)
			tableView.moveRow(at: indexPath, to: destinationIndexPath)
			tableView.endUpdates()
		}

    let metadataReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(messageMetaDataFirebaseFolder)
    metadataReference.updateChildValues(["pinned": true], withCompletionBlock: { (error, reference) in
      if error != nil {
        basicErrorAlertWith(title: pinErrorTitle, message: pinErrorMessage, controller: self)
        return
      }
    })
  }
  
  func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
      completion()
    }
  }

	fileprivate func hapticFeedback() {
		let generator = UIImpactFeedbackGenerator(style: .medium)
		generator.impactOccurred()
	}
  
  func deleteConversation(at indexPath: IndexPath) {
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: "Error", message: noInternetError, controller: self)
      return
    }

    let conversation = indexPath.section == 0 ? realmPinnedConversations[indexPath.row] : realmUnpinnedConversations[indexPath.row]
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID  else { return }

		if !realmManager.realm.isInWriteTransaction {
			realmManager.realm.beginWrite()
			let result = realmManager.realm.objects(Conversation.self).filter("chatID = '\(conversation.chatID!)'")
			let messagesResult = conversation.messages

			realmManager.realm.delete(messagesResult)
			realmManager.realm.delete(result)
			try! realmManager.realm.commitWrite()
		}


    Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(messageMetaDataFirebaseFolder).removeAllObservers()
    Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).removeValue()
    configureTabBarBadge()
    if realmAllConversations.count <= 0 {
      checkIfThereAnyActiveChats(isEmpty: true)
    }
  }
  
  fileprivate func updateMutedDatabaseValue(to state: Bool, currentUserID: String, conversationID: String) {
    let metadataReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(messageMetaDataFirebaseFolder)
    metadataReference.updateChildValues(["muted": state], withCompletionBlock: { (error, reference) in
      if error != nil {
        basicErrorAlertWith(title: muteErrorTitle, message: muteErrorMessage, controller: self)
      }
    })
  }
  
  func handleMuteConversation(section: Int, for conversation: Conversation) {
    
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID else { return }
    
    if section == 0 {
      guard conversation.muted.value != nil else {
        updateMutedDatabaseValue(to: true, currentUserID: currentUserID, conversationID: conversationID)
        return
      }
      guard conversation.muted.value! else {
        updateMutedDatabaseValue(to: true, currentUserID: currentUserID, conversationID: conversationID)
        return
      }
      updateMutedDatabaseValue(to: false, currentUserID: currentUserID, conversationID: conversationID)
      
    } else if section == 1 {
      guard conversation.muted.value != nil else {
        updateMutedDatabaseValue(to: true, currentUserID: currentUserID, conversationID: conversationID)
        return
      }
      guard conversation.muted.value! else {
        updateMutedDatabaseValue(to: true, currentUserID: currentUserID, conversationID: conversationID)
        return
      }
      updateMutedDatabaseValue(to: false, currentUserID: currentUserID, conversationID: conversationID)
    }
  }
}
