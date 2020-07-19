//
//  InAppNotificationManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/21/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import AudioToolbox
import SafariServices
import CropViewController

class InAppNotificationManager: NSObject {

  fileprivate var notificationReference: DatabaseReference!
  fileprivate var notificationHandle = [(handle: DatabaseHandle, chatID: String)]()
  fileprivate var conversations = [Conversation]()
  
  func updateConversations(to conversations: [Conversation]) {
    self.conversations = conversations
  }
  
  func removeAllObservers() {
    guard let currentUserID = Auth.auth().currentUser?.uid, notificationReference != nil else { return }
    let reference = Database.database().reference()
    for handle in notificationHandle {
      notificationReference = reference.child("user-messages").child(currentUserID).child(handle.chatID).child(messageMetaDataFirebaseFolder)
      notificationReference.removeObserver(withHandle: handle.handle)
    }
    notificationHandle.removeAll()
  }
  
  func observersForNotifications(conversations: [Conversation]) {
    removeAllObservers()
    updateConversations(to: conversations)
    for conversation in self.conversations {
      guard let currentUserID = Auth.auth().currentUser?.uid, let chatID = conversation.chatID else { continue }
      let handle = DatabaseHandle()
      let element = (handle: handle, chatID: chatID)
      notificationHandle.insert(element, at: 0)
      
      notificationReference = Database.database().reference().child("user-messages").child(currentUserID).child(chatID).child(messageMetaDataFirebaseFolder)
      notificationHandle[0].handle = notificationReference.observe(.childChanged, with: { (snapshot) in
        guard snapshot.key == "lastMessageID" else { return }
        guard let messageID = snapshot.value as? String else { return }
        guard let oldMessageID = conversation.lastMessageID, messageID > oldMessageID else { return }
        
        let lastMessageReference = Database.database().reference().child("messages").child(messageID)
        lastMessageReference.observeSingleEvent(of: .value, with: { (snapshot) in
          
          guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
          dictionary.updateValue(messageID as AnyObject, forKey: "messageUID")
          
          let message = Message(dictionary: dictionary)
          guard let uid = Auth.auth().currentUser?.uid, message.fromId != uid else { return }
          self.handleInAppSoundPlaying(message: message, conversation: conversation, conversations: self.conversations)
        })
      })
    }
  }
  
  func handleInAppSoundPlaying(message: Message, conversation: Conversation, conversations: [Conversation]) {
    if UIApplication.topViewController() is SFSafariViewController ||
      UIApplication.topViewController() is CropViewController ||
      UIApplication.topViewController() is INSPhotosViewController { return }
    
    if DeviceType.isIPad {
      if let chatLogController = UIApplication.topViewController() as? ChatLogViewController,
        let currentOpenedChat = chatLogController.conversation?.chatID,
        let conversationID = conversation.chatID {
        if currentOpenedChat == conversationID { return }
      }
    } else {
      if UIApplication.topViewController() is ChatLogViewController { return }
    }
   
		if let index = conversations.firstIndex(where: { (conv) -> Bool in
      return conv.chatID == conversation.chatID
    }) {
      let isGroupChat = conversations[index].isGroupChat.value ?? false
      if let muted = conversations[index].muted.value, !muted, let chatName = conversations[index].chatName {
        self.playNotificationSound()
        
        if userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications) {
          self.showInAppNotification(conversation: conversations[index], title: chatName, subtitle: self.subtitleForMessage(message: message), resource: conversationAvatar(resource: conversations[index].chatThumbnailPhotoURL, isGroupChat: isGroupChat), placeholder: conversationPlaceholder(isGroupChat: isGroupChat) )
        }
      } else if let chatName = conversations[index].chatName, conversations[index].muted.value == nil {
        self.playNotificationSound()
        if userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications) {
          self.showInAppNotification(conversation: conversations[index], title: chatName, subtitle: self.subtitleForMessage(message: message), resource: conversationAvatar(resource: conversations[index].chatThumbnailPhotoURL, isGroupChat: isGroupChat), placeholder: conversationPlaceholder(isGroupChat: isGroupChat))
        }
      }
    }
  }
  
  fileprivate func subtitleForMessage(message: Message) -> String {
    if (message.imageUrl != nil || message.localImage != nil) && message.videoUrl == nil {
      return MessageSubtitle.image
    } else if (message.imageUrl != nil || message.localImage != nil) && message.videoUrl != nil {
      return MessageSubtitle.video
    } else if message.voiceEncodedString != nil {
      return MessageSubtitle.audio
    } else {
      return message.text ?? ""
    }
  }
  
  fileprivate func conversationAvatar(resource: String?, isGroupChat: Bool) -> Any {
    let placeHolderImage = isGroupChat ? UIImage(named: "GroupIcon") : UIImage(named: "UserpicIcon")
    guard let imageURL = resource, imageURL != "" else { return placeHolderImage! }
    return URL(string: imageURL)!
  }
  
  fileprivate func conversationPlaceholder(isGroupChat: Bool) -> Data? {
    let placeHolderImage = isGroupChat ? UIImage(named: "GroupIcon") : UIImage(named: "UserpicIcon")
    guard let data = placeHolderImage?.asJPEGData else {
      return nil
    }
    return data
  }
  
    fileprivate func showInAppNotification(conversation: Conversation, title: String, subtitle: String, resource: Any?, placeholder: Data?) {
        let notification: InAppNotification = InAppNotification(resource: resource, title: title, subtitle: subtitle, data: placeholder)
        InAppNotificationDispatcher.shared.show(notification: notification) { (_) in
            guard let controller = UIApplication.shared.keyWindow?.rootViewController else { return }
            guard let id = conversation.chatID, let realmConversation = RealmKeychain.defaultRealm.objects(Conversation.self).filter("chatID == %@", id).first else {
                chatLogPresenter.open(conversation, controller: controller)
                return
            }
            chatLogPresenter.open(realmConversation, controller: controller)
        }
    }

  fileprivate func playNotificationSound() {
    if userDefaults.currentBoolObjectState(for: userDefaults.inAppSounds) {
      SystemSoundID.playFileNamed(fileName: "notification", withExtenstion: "caf")
    }
    if userDefaults.currentBoolObjectState(for: userDefaults.inAppVibration) {
      AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
  }
}
