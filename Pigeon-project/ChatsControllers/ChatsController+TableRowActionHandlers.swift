//
//  ChatsController+TableRowActionHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/19/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
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

extension ChatsController {
  
  func unpinConversation(at indexPath: IndexPath) {
    guard let uid = Auth.auth().currentUser?.uid else  { return }
    let conversation = self.filteredPinnedConversations[indexPath.row]
    guard let chatPartnerId = conversation.message?.chatPartnerId() else { return }
    guard let index = self.pinnedConversations.index(where: { (conversation) -> Bool in
      return conversation.user?.id == self.filteredPinnedConversations[indexPath.row].user?.id
    }) else { return }
    
    self.tableView.beginUpdates()
    let pinnedElement = self.filteredPinnedConversations[indexPath.row]
    
    let filteredIndexToInsert = self.filtededConversations.insertionIndex(of: pinnedElement, using: { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    })
    
    let unfilteredIndexToInsert = self.conversations.insertionIndex(of: pinnedElement, using: { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    })
    
    self.filtededConversations.insert(pinnedElement, at: filteredIndexToInsert)
    self.conversations.insert(pinnedElement, at: unfilteredIndexToInsert)
    self.filteredPinnedConversations.remove(at: indexPath.row)
    self.pinnedConversations.remove(at: index)
    let destinationIndexPath = IndexPath(row: filteredIndexToInsert, section: 1)
  
    self.tableView.deleteRows(at: [indexPath], with: .bottom)
    self.tableView.insertRows(at: [destinationIndexPath], with: .bottom)
    self.tableView.endUpdates()
    
    let metadataRef = Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).child(messageMetaDataFirebaseFolder)
    metadataRef.updateChildValues(["pinned": false], withCompletionBlock: { (error, reference) in
      if error != nil {
        basicErrorAlertWith(title: "Error pinning/unpinning", message: "Changes won't be saved across app restarts. Check your internet connection, re-launch the app, and try again.", controller: self)
        print(error?.localizedDescription ?? "")
        return
      }
    })
  }
  
  
  func pinConversation(at indexPath: IndexPath) {
    guard let uid = Auth.auth().currentUser?.uid else  { return }
    let conversation = self.filtededConversations[indexPath.row]
    guard let chatPartnerId = conversation.message?.chatPartnerId() else { return }
    guard let index = self.conversations.index(where: { (conversation) -> Bool in
      return conversation.user?.id == self.filtededConversations[indexPath.row].user?.id
    }) else { return }
    
    self.tableView.beginUpdates()
    let elementToPin = self.filtededConversations[indexPath.row]
    
    let filteredIndexToInsert = self.filteredPinnedConversations.insertionIndex(of: elementToPin, using: { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    })
    
    let unfilteredIndexToInsert = self.pinnedConversations.insertionIndex(of: elementToPin, using: { (conversation1, conversation2) -> Bool in
      return conversation1.message?.timestamp?.int32Value > conversation2.message?.timestamp?.int32Value
    })
    
    self.filteredPinnedConversations.insert(elementToPin, at: filteredIndexToInsert)
    self.pinnedConversations.insert(elementToPin, at: unfilteredIndexToInsert)
    self.filtededConversations.remove(at: indexPath.row)
    self.conversations.remove(at: index)
    let destinationIndexPath = IndexPath(row: filteredIndexToInsert, section: 0)
    
    self.tableView.deleteRows(at: [indexPath], with: .top)
    self.tableView.insertRows(at: [destinationIndexPath], with: .top)
    self.tableView.endUpdates()
    
    let metadataRef = Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).child(messageMetaDataFirebaseFolder)
    metadataRef.updateChildValues(["pinned": true], withCompletionBlock: { (error, reference) in
      if error != nil {
        basicErrorAlertWith(title: "Error pinning/unpinning", message: "Changes won't be saved across app restarts. Check your internet connection, re-launch the app, and try again.", controller: self)
        print(error?.localizedDescription ?? "")
        return
      }
    })
  }
  
  func deletePinnedConversation(at indexPath: IndexPath) {
    
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let conversation = self.filteredPinnedConversations[indexPath.row]
    guard let chatPartnerId = conversation.message?.chatPartnerId() else { return }
    guard let index = self.pinnedConversations.index(where: { (conversation) -> Bool in
      return conversation.user?.id == self.filteredPinnedConversations[indexPath.row].user?.id
    }) else { return }
    
    self.tableView.beginUpdates()
    self.filteredPinnedConversations.remove(at: indexPath.row)
    self.pinnedConversations.remove(at: index)
    self.tableView.deleteRows(at: [indexPath], with: .left)
    self.tableView.endUpdates()
    
    Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue()
    self.configureTabBarBadge()
  }
  
  func deleteUnPinnedConversation(at indexPath: IndexPath) {
    guard let uid = Auth.auth().currentUser?.uid else { return }
    let conversation = self.filtededConversations[indexPath.row]
    guard let chatPartnerId = conversation.message?.chatPartnerId() else { return }
    guard let index = self.conversations.index(where: { (conversation) -> Bool in
      return conversation.user?.id == self.filtededConversations[indexPath.row].user?.id
    }) else { return }
    
    self.tableView.beginUpdates()
    self.filtededConversations.remove(at: indexPath.row)
    self.conversations.remove(at: index)
    self.tableView.deleteRows(at: [indexPath], with: .left)
    self.tableView.endUpdates()
    
    Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue()
    self.configureTabBarBadge()
  }
  
 fileprivate func updateMutedDatabaseValue(to state: Bool, uid: String, chatPartnerID: String) {
    
    let metadataRef = Database.database().reference().child("user-messages").child(uid).child(chatPartnerID).child(messageMetaDataFirebaseFolder)
    metadataRef.updateChildValues(["muted": state], withCompletionBlock: { (error, reference) in
      if error != nil {
        basicErrorAlertWith(title: "Error muting/unmuting", message: "Check your internet connection and try again.", controller: self)
      }
    })
  }
  
  func handleMuteConversation(at indexPath: IndexPath, for message: Message) {
    
    guard let uid = Auth.auth().currentUser?.uid, let chatPartnerID = message.chatPartnerId() else { return }
    
    if indexPath.section == 0 {
      guard filteredPinnedConversations[indexPath.row].chatMetaData?.muted != nil else {
        updateMutedDatabaseValue(to: true, uid: uid, chatPartnerID: chatPartnerID)
        return
      }
      guard filteredPinnedConversations[indexPath.row].chatMetaData!.muted! else {
        updateMutedDatabaseValue(to: true, uid: uid, chatPartnerID: chatPartnerID)
        return
      }
      updateMutedDatabaseValue(to: false, uid: uid, chatPartnerID: chatPartnerID)
      
    } else if indexPath.section == 1 {
      guard filtededConversations[indexPath.row].chatMetaData?.muted != nil else {
        updateMutedDatabaseValue(to: true, uid: uid, chatPartnerID: chatPartnerID)
        return
      }
      guard filtededConversations[indexPath.row].chatMetaData!.muted! else {
        updateMutedDatabaseValue(to: true, uid: uid, chatPartnerID: chatPartnerID)
        return
      }
      updateMutedDatabaseValue(to: false, uid: uid, chatPartnerID: chatPartnerID)
    }
  }
}
