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
  
  fileprivate func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
      completion()
    }
  }
  
  func setupMuteAction(at indexPath: IndexPath) -> UITableViewRowAction {
    let mute = UITableViewRowAction(style: .default, title: "Mute") { _, _ in
      if indexPath.section == 0 {
        if #available(iOS 11.0, *) {} else {
          self.tableView.setEditing(false, animated: true)
        }
        self.delayWithSeconds(1, completion: {
          self.handleMuteConversation(section: indexPath.section, for: self.filteredPinnedConversations[indexPath.row])
        })
      } else if indexPath.section == 1 {
        if #available(iOS 11.0, *) {} else {
          self.tableView.setEditing(false, animated: true)
        }
        self.delayWithSeconds(1, completion: {
          self.handleMuteConversation(section: indexPath.section, for: self.filtededConversations[indexPath.row])
        })
      }
    }
    
    if indexPath.section == 0 {
      let isPinnedConversationMuted = filteredPinnedConversations[indexPath.row].muted == true
      let muteTitle = isPinnedConversationMuted ? "Unmute" : "Mute"
      mute.title = muteTitle
    } else if indexPath.section == 1 {
      let isConversationMuted = filtededConversations[indexPath.row].muted == true
      let muteTitle = isConversationMuted ? "Unmute" : "Mute"
      mute.title = muteTitle
    }
    mute.backgroundColor = UIColor(red:0.56, green:0.64, blue:0.68, alpha:1.0)
    return mute
  }
  
  func setupPinAction(at indexPath: IndexPath) -> UITableViewRowAction {
    let pin = UITableViewRowAction(style: .default, title: "Pin") { _, _ in
      if indexPath.section == 0 {
        self.unpinConversation(at: indexPath)
      } else if indexPath.section == 1 {
        self.pinConversation(at: indexPath)
      }
    }
    
    let pinTitle = indexPath.section == 0 ? "Unpin" : "Pin"
    pin.title = pinTitle
    pin.backgroundColor = UIColor(red:0.96, green:0.49, blue:0.00, alpha:1.0)
    return pin
  }
  
  func setupDeleteAction(at indexPath: IndexPath) -> UITableViewRowAction {
    
    let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
      if self.currentReachabilityStatus == .notReachable {
        basicErrorAlertWith(title: "Error deleting message", message: noInternetError, controller: self)
        return
      }
      if indexPath.section == 0 {
        self.deletePinnedConversation(at: indexPath)
      } else if indexPath.section == 1 {
        self.deleteUnPinnedConversation(at: indexPath)
      }
    }
    
    delete.backgroundColor = UIColor(red:0.90, green:0.22, blue:0.21, alpha:1.0)
    return delete
  }
  func unpinConversation(at indexPath: IndexPath) {
    let conversation = self.filteredPinnedConversations[indexPath.row]
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID else { return }
    
		guard let index = self.pinnedConversations.firstIndex(where: { (conversation) -> Bool in
      return conversation.chatID == self.filteredPinnedConversations[indexPath.row].chatID
    }) else { return }
    
    self.tableView.beginUpdates()
    let pinnedElement = self.filteredPinnedConversations[indexPath.row]
    
    let filteredIndexToInsert = self.filtededConversations.insertionIndex(of: pinnedElement, using: { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
    })
    
    let unfilteredIndexToInsert = self.conversations.insertionIndex(of: pinnedElement, using: { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
    })
    
    self.filtededConversations.insert(pinnedElement, at: filteredIndexToInsert)
    self.conversations.insert(pinnedElement, at: unfilteredIndexToInsert)
    self.filteredPinnedConversations.remove(at: indexPath.row)
    self.pinnedConversations.remove(at: index)
    let destinationIndexPath = IndexPath(row: filteredIndexToInsert, section: 1)
    
    self.tableView.deleteRows(at: [indexPath], with: .bottom)
    self.tableView.insertRows(at: [destinationIndexPath], with: .bottom)
    self.tableView.endUpdates()
    
    let metadataRef = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(messageMetaDataFirebaseFolder)
    metadataRef.updateChildValues(["pinned": false], withCompletionBlock: { (error, reference) in
      if error != nil {
        basicErrorAlertWith(title: pinErrorTitle , message: pinErrorMessage, controller: self)
        return
      }
    })
  }
  
  func pinConversation(at indexPath: IndexPath) {
    
    let conversation = self.filtededConversations[indexPath.row]
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID else { return }
    
		guard let index = self.conversations.firstIndex(where: { (conversation) -> Bool in
      return conversation.chatID == self.filtededConversations[indexPath.row].chatID
    }) else { return }
    
    self.tableView.beginUpdates()
    let elementToPin = self.filtededConversations[indexPath.row]
    
    let filteredIndexToInsert = self.filteredPinnedConversations.insertionIndex(of: elementToPin, using: { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
    })
    
    let unfilteredIndexToInsert = self.pinnedConversations.insertionIndex(of: elementToPin, using: { (conversation1, conversation2) -> Bool in
      return conversation1.lastMessage?.timestamp?.int32Value > conversation2.lastMessage?.timestamp?.int32Value
    })
    
    self.filteredPinnedConversations.insert(elementToPin, at: filteredIndexToInsert)
    self.pinnedConversations.insert(elementToPin, at: unfilteredIndexToInsert)
    self.filtededConversations.remove(at: indexPath.row)
    self.conversations.remove(at: index)
    let destinationIndexPath = IndexPath(row: filteredIndexToInsert, section: 0)
    
    self.tableView.deleteRows(at: [indexPath], with: .top)
    self.tableView.insertRows(at: [destinationIndexPath], with: .top)
    self.tableView.endUpdates()
    
    let metadataReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(messageMetaDataFirebaseFolder)
    metadataReference.updateChildValues(["pinned": true], withCompletionBlock: { (error, reference) in
      if error != nil {
        basicErrorAlertWith(title: pinErrorTitle, message: pinErrorMessage, controller: self)
        return
      }
    })
  }
  
  func deletePinnedConversation(at indexPath: IndexPath) {
    let conversation = self.filteredPinnedConversations[indexPath.row]
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID  else { return }
    
		guard let index = self.pinnedConversations.firstIndex(where: { (conversation) -> Bool in
      return conversation.chatID == self.filteredPinnedConversations[indexPath.row].chatID
    }) else { return }
    
    self.tableView.beginUpdates()
    self.filteredPinnedConversations.remove(at: indexPath.row)
    self.pinnedConversations.remove(at: index)
    self.tableView.deleteRows(at: [indexPath], with: .left)
    self.tableView.endUpdates()
    
    Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(messageMetaDataFirebaseFolder).removeAllObservers()
    Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).removeValue()
    configureTabBarBadge()
     if self.conversations.count <= 0 && self.pinnedConversations.count <= 0 {
      DispatchQueue.main.async {
        self.checkIfThereAnyActiveChats(isEmpty: true)
      }
    }
  }
  
  func deleteUnPinnedConversation(at indexPath: IndexPath) {
    let conversation = self.filtededConversations[indexPath.row]
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation.chatID  else { return }
    
		guard let index = self.conversations.firstIndex(where: { (conversation) -> Bool in
      return conversation.chatID == self.filtededConversations[indexPath.row].chatID
    }) else { return }
    
    self.tableView.beginUpdates()
    self.filtededConversations.remove(at: indexPath.row)
    self.conversations.remove(at: index)
    self.tableView.deleteRows(at: [indexPath], with: .left)
    self.tableView.endUpdates()
    
    Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(messageMetaDataFirebaseFolder).removeAllObservers()
    Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).removeValue()
   
    configureTabBarBadge()
    if self.conversations.count <= 0 && self.pinnedConversations.count <= 0 {
      DispatchQueue.main.async {
         self.checkIfThereAnyActiveChats(isEmpty: true)
      }
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
      guard conversation.muted != nil else {
        updateMutedDatabaseValue(to: true, currentUserID: currentUserID, conversationID: conversationID)
        return
      }
      guard conversation.muted! else {
        updateMutedDatabaseValue(to: true, currentUserID: currentUserID, conversationID: conversationID)
        return
      }
      updateMutedDatabaseValue(to: false, currentUserID: currentUserID, conversationID: conversationID)
      
    } else if section == 1 {
      guard conversation.muted != nil else {
        updateMutedDatabaseValue(to: true, currentUserID: currentUserID, conversationID: conversationID)
        return
      }
      guard conversation.muted! else {
        updateMutedDatabaseValue(to: true, currentUserID: currentUserID, conversationID: conversationID)
        return
      }
      updateMutedDatabaseValue(to: false, currentUserID: currentUserID, conversationID: conversationID)
    }
  }
}
