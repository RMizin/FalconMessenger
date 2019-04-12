//
//  ConversationsFetcher.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/21/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

protocol ConversationUpdatesDelegate: class {
  func conversations(didStartFetching: Bool)
  func conversations(didStartUpdatingData: Bool)
  func conversations(didFinishFetching: Bool, conversations: [Conversation])
  func conversations(update conversation: Conversation, reloadNeeded: Bool)
  func conversations(didRemove: Bool, chatID: String)
  func conversations(addedNewConversation: Bool, chatID: String)
}

class ConversationsFetcher: NSObject {
	
  weak var delegate: ConversationUpdatesDelegate?
  
  fileprivate var group: DispatchGroup!
  fileprivate var isGroupAlreadyFinished = false
  fileprivate var conversations = [Conversation]()
  
  fileprivate var userReference: DatabaseReference!
  fileprivate var groupChatReference: DatabaseReference!
  fileprivate var currentUserConversationsReference: DatabaseReference!
  fileprivate var lastMessageForConverstaionRef: DatabaseReference!
  fileprivate var conversationReference: DatabaseReference!
  fileprivate var connectedReference: DatabaseReference!

  fileprivate var inAppNotificationsObserverHandler: DatabaseHandle!
  fileprivate var currentUserConversationsRemovingHandle = DatabaseHandle()
  fileprivate var currentUserConversationsAddingHandle = DatabaseHandle()

	func cleanFetcherConversations() {
		conversations.removeAll()
	}
  @objc public func removeAllObservers() {
    conversations.removeAll()
    isGroupAlreadyFinished = false
		group = nil
    
    if groupChatReference != nil {
      for handle in groupConversationsChangesHandle {
        groupChatReference = Database.database().reference().child("groupChats").child(handle.chatID).child(messageMetaDataFirebaseFolder)
        groupChatReference.removeObserver(withHandle: handle.handle)
      }
      groupConversationsChangesHandle.removeAll()
    }
    
    if userReference != nil {
      for handle in conversationsChangesHandle {
        userReference = Database.database().reference().child("users").child(handle.chatID)
        userReference.removeObserver(withHandle: handle.handle)
      }
      conversationsChangesHandle.removeAll()
    }
    
    if conversationReference != nil {
      for handle in conversationReferenceHandle {
        conversationReference = Database.database().reference().child("user-messages").child(handle.currentUserID).child(handle.chatID).child(messageMetaDataFirebaseFolder)
        conversationReference.removeObserver(withHandle: handle.handle)
      }
      conversationReferenceHandle.removeAll()
    }
    
    if currentUserConversationsReference != nil {
      currentUserConversationsReference.removeObserver(withHandle: currentUserConversationsAddingHandle)
      currentUserConversationsReference.removeObserver(withHandle: currentUserConversationsRemovingHandle)
    }
  }

  func fetchConversations() {
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    delegate?.conversations(didStartFetching: true)

		currentUserConversationsReference = Database.database().reference().child("user-messages").child(currentUserID)
		observeConversationAdded()
		observeConversationRemoved()
		DispatchQueue.global(qos: .default).async {
			self.currentUserConversationsReference.observeSingleEvent(of: .value) { (snapshot) in
				self.group = DispatchGroup()
				for _ in 0 ..< snapshot.childrenCount { self.group.enter() }

				self.group.notify(queue: .main, execute: {
					self.isGroupAlreadyFinished = true
					self.delegate?.conversations(didFinishFetching: true, conversations: self.conversations)
				})

				if !snapshot.exists() {
					self.delegate?.conversations(didFinishFetching: true, conversations: self.conversations)
					return
				}
			}
		}
  }
  
  func observeConversationRemoved() {
    currentUserConversationsRemovingHandle = currentUserConversationsReference.observe(.childRemoved) { (snapshot) in
      let chatID = snapshot.key
      if self.userReference != nil {
				guard let index = self.conversationsChangesHandle.firstIndex(where: { (element) -> Bool in
          return element.chatID == chatID
        }) else { return }
        self.userReference = Database.database().reference().child("users").child(self.conversationsChangesHandle[index].chatID)
        self.userReference.removeObserver(withHandle: self.conversationsChangesHandle[index].handle)
        self.conversationsChangesHandle.remove(at: index)
      }
      
      if self.groupChatReference != nil {
				guard let index = self.groupConversationsChangesHandle.firstIndex(where: { (element) -> Bool in
          return element.chatID == chatID
        }) else { return }
        self.groupChatReference = Database.database().reference().child("groupChats").child(self.groupConversationsChangesHandle[index].chatID).child(messageMetaDataFirebaseFolder)
        self.groupChatReference.removeObserver(withHandle: self.groupConversationsChangesHandle[index].handle)
        self.groupConversationsChangesHandle.remove(at: index)
      }
      self.delegate?.conversations(didRemove: true, chatID: chatID)
    }
  }
  
  func observeConversationAdded() {
    currentUserConversationsAddingHandle = currentUserConversationsReference.observe(.childAdded, with: { (snapshot) in
      let chatID = snapshot.key
      self.observeChangesForDefaultConversation(with: chatID)
      self.observeChangesForGroupConversation(with: chatID)
      self.delegate?.conversations(addedNewConversation: true, chatID: chatID)
      self.loadConversation(for: chatID)
    })
  }
  
  fileprivate var conversationReferenceHandle = [(handle: DatabaseHandle, currentUserID: String, chatID: String)]()


  fileprivate func loadConversation(for chatID: String) {
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }

    conversationReference = Database.database().reference().child("user-messages").child(currentUserID).child(chatID).child(messageMetaDataFirebaseFolder)
    let element = (handle: DatabaseHandle(), currentUserID: currentUserID, chatID: chatID)
    conversationReferenceHandle.insert(element, at: 0)
    conversationReference.keepSynced(true)
    conversationReferenceHandle[0].handle = conversationReference.observe( .value, with: { (snapshot) in
      
      guard var dictionary = snapshot.value as? [String: AnyObject], snapshot.exists() else { return }
      dictionary.updateValue(chatID as AnyObject, forKey: "chatID")

			if self.isGroupAlreadyFinished {
				self.delegate?.conversations(didStartUpdatingData: true)
			}

      let conversation = Conversation(dictionary: dictionary)
			conversation.isTyping.value = conversation.getTyping()

				guard let lastMessageID = conversation.lastMessageID else { //if no messages in chat yet
					self.loadAddictionalMetadata(for: conversation)
					return
				}
				self.loadLastMessage(for: lastMessageID, conversation: conversation)
    })
  }

	fileprivate let messagesFetcher = MessagesFetcher()
	
  fileprivate func loadLastMessage(for messageID: String, conversation: Conversation) {
    let lastMessageReference = Database.database().reference().child("messages").child(messageID)
    lastMessageReference.observeSingleEvent(of: .value, with: { (snapshot) in
      guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
      dictionary.updateValue(messageID as AnyObject, forKey: "messageUID")
			dictionary = self.messagesFetcher.preloadCellData(to: dictionary, isGroupChat: false)

      let message = Message(dictionary: dictionary)
			if let thumbnail = message.thumbnailImageUrl {
				prefetchThumbnail(from: thumbnail)
			}
			conversation.lastMessageTimestamp.value = message.timestamp.value
			message.conversation = conversation
			conversation.lastMessageRuntime = message
			self.loadAddictionalMetadata(for: conversation)
    })
  }

  fileprivate func loadAddictionalMetadata(for conversation: Conversation) {
    
    guard let chatID = conversation.chatID, let currentUserID = Auth.auth().currentUser?.uid else { return }
    
    let userDataReference = Database.database().reference().child("users").child(chatID)
    userDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
      guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
      dictionary.updateValue(chatID as AnyObject, forKey: "id")
      
      let user = User(dictionary: dictionary)

			if chatID == currentUserID {
				conversation.chatName = NameConstants.personalStorage
			} else {
				conversation.chatName = user.name
			}

      conversation.chatPhotoURL = user.photoURL
      conversation.chatThumbnailPhotoURL = user.thumbnailPhotoURL
      conversation.chatParticipantsIDs.assign([chatID, currentUserID])
			prefetchThumbnail(from: conversation.chatThumbnailPhotoURL == nil ? conversation.chatPhotoURL : conversation.chatThumbnailPhotoURL)
      self.updateConversationArrays(with: conversation)
    })
    
    let groupChatDataReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    groupChatDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
      guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
      dictionary.updateValue(chatID as AnyObject, forKey: "id")
      
      if let membersIDs = dictionary["chatParticipantsIDs"] as? [String:AnyObject] {
        dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "chatParticipantsIDs")
      }
      
      let metaInfo = Conversation(dictionary: dictionary)
      conversation.chatName = metaInfo.chatName
      conversation.chatPhotoURL = metaInfo.chatPhotoURL
      conversation.chatThumbnailPhotoURL = metaInfo.chatThumbnailPhotoURL
      conversation.chatParticipantsIDs.assign(metaInfo.chatParticipantsIDs) //= metaInfo.chatParticipantsIDs
      conversation.isGroupChat.value = metaInfo.isGroupChat.value
      conversation.admin = metaInfo.admin
      conversation.chatID = metaInfo.chatID
			prefetchThumbnail(from: conversation.chatThumbnailPhotoURL == nil ? conversation.chatPhotoURL : conversation.chatThumbnailPhotoURL)
      self.updateConversationArrays(with: conversation)
    })
  }

  fileprivate func updateConversationArrays(with conversation: Conversation) {
    guard let userID = conversation.chatID else { return }
    
		if let index = conversations.firstIndex(where: { (conversation) -> Bool in
      return conversation.chatID == userID
    }) {
      update(conversation: conversation, at: index)
    } else {
      conversations.append(conversation)
      handleGroupOrReloadTable()
    }
  }
  
  func update(conversation: Conversation, at index: Int) {
    if conversation.isTyping.value == nil {
      let isTyping = conversations[index].isTyping.value
      conversation.isTyping.value = isTyping
    }
 
    guard isGroupAlreadyFinished, (conversations[index].muted.value != conversation.muted.value) else {
      if isGroupAlreadyFinished && conversations[index].pinned.value != conversation.pinned.value {
        conversations[index] = conversation
        delegate?.conversations(update: conversations[index], reloadNeeded: false)
        return
      }
      
      conversations[index] = conversation
      handleGroupOrReloadTable()
      return
    }
    conversations[index] = conversation
    delegate?.conversations(update: conversations[index], reloadNeeded: true)
  }
  
  fileprivate func handleGroupOrReloadTable() {
    guard isGroupAlreadyFinished else {
      guard group != nil else {
        delegate?.conversations(didFinishFetching: true, conversations: conversations)
        return
      }
      group.leave()
      return
    }
    delegate?.conversations(didFinishFetching: true, conversations: conversations)
  }

  var conversationsChangesHandle = [(handle: DatabaseHandle, chatID: String)]()
  var groupConversationsChangesHandle = [(handle: DatabaseHandle, chatID: String)]()
  
  fileprivate func observeChangesForGroupConversation(with chatID: String) {
    groupChatReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    
    let handle = DatabaseHandle()
    let element = (handle: handle, chatID: chatID)
    groupConversationsChangesHandle.insert(element, at: 0)
    groupConversationsChangesHandle[0].handle = groupChatReference.observe(.childChanged, with: { (snapshot) in
      self.handleConversationChanges(from: snapshot, conversationNameKey: "chatName",
                                     conversationPhotoKey: "chatThumbnailPhotoURL",
                                     chatID: chatID, membersIDsKey: "chatParticipantsIDs", adminKey: "admin")
    })
  }
  
  fileprivate func observeChangesForDefaultConversation(with chatID: String) {
    userReference = Database.database().reference().child("users").child(chatID)
    
    let handle = DatabaseHandle()
    let element = (handle: handle, chatID: chatID)
    conversationsChangesHandle.insert(element, at: 0)
    conversationsChangesHandle[0].handle = userReference.observe(.childChanged, with: { (snapshot) in
      self.handleConversationChanges(from: snapshot, conversationNameKey: "name",
                                     conversationPhotoKey: "thumbnailPhotoURL",
                                     chatID: chatID, membersIDsKey: nil, adminKey: nil)
    })
  }
  
  fileprivate func handleConversationChanges(from snapshot: DataSnapshot,
                                                  conversationNameKey: String, conversationPhotoKey: String,
                                                  chatID: String, membersIDsKey: String?, adminKey: String?) {
    
		guard let index = conversations.firstIndex(where: { (conversation) -> Bool in
        return conversation.chatID == chatID
    }) else { return }
    
    if let adminKey = adminKey, snapshot.key == adminKey {
      conversations[index].admin = snapshot.value as? String
      delegate?.conversations(update: conversations[index], reloadNeeded: true)
    }
    
    if let membersIDsKey = membersIDsKey, snapshot.key == membersIDsKey {
      guard let dictionary = snapshot.value as? [String: AnyObject] else { return }
      conversations[index].chatParticipantsIDs.assign(Array(dictionary.keys)) //= Array(dictionary.keys)
      delegate?.conversations(update: conversations[index], reloadNeeded: true)
    }
    
    if snapshot.key == conversationNameKey {
			guard let currentUserID = Auth.auth().currentUser?.uid else { return }
			if conversations[index].chatID == currentUserID {
				conversations[index].chatName = NameConstants.personalStorage
			} else {
				conversations[index].chatName = snapshot.value as? String
			}

      delegate?.conversations(update: conversations[index], reloadNeeded: true)
    }
      
    if snapshot.key == conversationPhotoKey {
      conversations[index].chatThumbnailPhotoURL = snapshot.value as? String
      delegate?.conversations(update: conversations[index], reloadNeeded: true)
    }
  }
}
