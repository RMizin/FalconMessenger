//
//  ChatsTableViewController+NotificationsHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/14/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import AudioToolbox
import Firebase
import CropViewController
import SafariServices

extension ChatsTableViewController {
  
  func currentTab() -> UINavigationController? {
    guard let appDelegate = tabBarController as? GeneralTabBarController else { return nil }
    switch self.tabBarController!.selectedIndex {
    case 0:
      let controller = appDelegate.contactsController.navigationController
      return controller
    case 1:
      let controller = navigationController
      return controller
    case 2:
      let controller = appDelegate.settingsController.navigationController
      return controller
    default: break
    }
    return nil
  }
  
  func handleInAppSoundPlaying(message: Message, conversation: Conversation) {

    if UIApplication.topViewController() is SFSafariViewController ||
      UIApplication.topViewController() is CropViewController ||
      UIApplication.topViewController() is ChatLogController ||
      UIApplication.topViewController() is INSPhotosViewController { return }

    var allConversations = conversations
    allConversations.insert(contentsOf: pinnedConversations, at: 0)
    
    if let index = allConversations.index(where: { (conv) -> Bool in
      return conv.chatID == conversation.chatID
    }) {
      let isGroupChat = allConversations[index].isGroupChat ?? false
      if let muted = allConversations[index].muted, !muted, let chatName = allConversations[index].chatName {
        self.playNotificationSound()
      
        if userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications) {
          self.showInAppNotification(conversation: allConversations[index], title: chatName, subtitle: self.subtitleForMessage(message: message), resource: conversationAvatar(resource: allConversations[index].chatThumbnailPhotoURL, isGroupChat: isGroupChat), placeholder: conversationPlaceholder(isGroupChat: isGroupChat) )
        }
      } else if let chatName = allConversations[index].chatName , allConversations[index].muted == nil   {
        self.playNotificationSound()
        if userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications) {
          self.showInAppNotification(conversation: allConversations[index], title: chatName, subtitle: self.subtitleForMessage(message: message), resource: conversationAvatar(resource: allConversations[index].chatThumbnailPhotoURL, isGroupChat: isGroupChat), placeholder: conversationPlaceholder(isGroupChat: isGroupChat))
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
      self.destinationLayout = AutoSizingCollectionViewFlowLayout()
      self.destinationLayout?.minimumLineSpacing = AutoSizingCollectionViewFlowLayout.lineSpacing
      self.chatLogController = ChatLogController(collectionViewLayout: self.destinationLayout!)
      self.messagesFetcher = MessagesFetcher()
      self.messagesFetcher?.delegate = self
      self.messagesFetcher?.loadMessagesData(for: conversation)
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
