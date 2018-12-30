//
//  ChatsTableViewController+TableRowActionHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/14/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

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
    pin.backgroundColor = UIColor(red:0.18, green:0.26, blue:0.31, alpha:1.0)
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
    
//    guard let index = pinnedConversations.index(where: { (conversation) -> Bool in
//      return conversation.chatID == filteredPinnedConversations[indexPath.row].chatID
//    }) else { return }

//		chatsTableViewRealmObserver.move(realmPinnedConversations[indexPath.row],
//																		 at: indexPath,
//																		 from: realmPinnedConversations,
//																		 to: realmUnpinnedConversations)

 //   let pinnedElement = realmPinnedConversations[indexPath.row]
//	//	pinnedConversationsNotificationToken?.invalidate()
//	//	pinnedConversationsNotificationToken
//		//	realmManager.realm.beginWrite()
//		realmPinnedConversations[indexPath.row].pinned.value = false
//		chatsTableViewRealmObserver.update(type: .reloadRow, conversation: realmPinnedConversations[indexPath.row])
//		///	try! realmManager.realm.commitWrite()
//
//
//		let conversationToInsert = realmPinnedConversations[indexPath.row]//.mutableCopy() as! Conversation
//		conversationToInsert.pinned.value = false
//
//		realmManager.delete(conversation: realmPinnedConversations[indexPath.row])
//		realmManager.update(conversation: conversationToInsert)
//    let filteredIndexToInsert = filtededConversations.insertionIndex(of: pinnedElement, using: { (conversation1, conversation2) -> Bool in
//      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
//    })
//
//    let indexToInsert = realmUnpinnedConversations.insertionIndex(of: pinnedElement, using: { (conversation1, conversation2) -> Bool in
//      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
//    })
//
//
//    realmUnpinnedConversations.insert(pinnedElement, at: indexToInsert)
//    conversations.insert(pinnedElement, at: unfilteredIndexToInsert)
//    realmPinnedConversations.remove(at: indexPath.row)
//    pinnedConversations.remove(at: index)
//    let destinationIndexPath = IndexPath(row: indexToInsert, section: 1)
//
//    tableView.beginUpdates()
//    if #available(iOS 11.0, *) {
//    } else {
//      tableView.setEditing(false, animated: true)
//    }
////    tableView.moveRow(at: indexPath, to: destinationIndexPath)
////
//   tableView.endUpdates()

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

//		realmManager.realm.beginWrite()
//		realmUnpinnedConversations[indexPath.row].pinned.value = true
//		try! realmManager.realm.commitWrite()

	//	let conversationToInsert = realmUnpinnedConversations[indexPath.row]//.mutableCopy() as! Conversation
		//conversationToInsert.pinned.value = true



	//	realmManager.delete(conversation: realmUnpinnedConversations[indexPath.row])
	//	realmManager.update(conversation: conversationToInsert)
//
//    guard let index = conversations.index(where: { (conversation) -> Bool in
//      return conversation.chatID == filtededConversations[indexPath.row].chatID
//    }) else { return }
////
//    let elementToPin = realmUnpinnedConversations[indexPath.row]
////
//    let filteredIndexToInsert = realmPinnedConversations.insertionIndex(of: elementToPin, using: { (conversation1, conversation2) -> Bool in
//			return conversation1.lastMessage?.timestamp.value! > conversation2.lastMessage?.timestamp.value!
//    })

//		chatsTableViewRealmObserver.move(realmUnpinnedConversations[indexPath.row],
//																		 at: indexPath,
//																		 from: realmUnpinnedConversations,
//																		 to: realmPinnedConversations)
//    let unfilteredIndexToInsert = pinnedConversations.insertionIndex(of: elementToPin, using: { (conversation1, conversation2) -> Bool in
//      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
//    })
//
//    filteredPinnedConversations.insert(elementToPin, at: filteredIndexToInsert)
//    pinnedConversations.insert(elementToPin, at: unfilteredIndexToInsert)
//    filtededConversations.remove(at: indexPath.row)
//    conversations.remove(at: index)
//   let destinationIndexPath = IndexPath(row: filteredIndexToInsert, section: 0)
//		pinnedConversationsNotificationToken?.invalidate()
//		unpinnedConversationsNotificationToken?.invalidate()
//
//    tableView.beginUpdates()
//    tableView.moveRow(at: indexPath, to: destinationIndexPath)
//
//		realmManager.realm.beginWrite()
//
//		realmManager.delete(conversation: realmUnpinnedConversations[indexPath.row])
//		realmUnpinnedConversations[indexPath.row].pinned.value = true
//		realmManager.update(conversation: realmUnpinnedConversations[indexPath.row])
//		try! realmManager.realm.commitWrite()
//    if #available(iOS 11.0, *) {
//    } else {
//      tableView.setEditing(false, animated: true)
//    }
   // tableView.endUpdates()
		//observeDataSourceChanges()


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
	//	chatsTableViewRealmObserver.delete(at: indexPath)

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
