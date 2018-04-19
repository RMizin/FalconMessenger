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

extension ChatsTableViewController {
  
  fileprivate func visibleTab() -> UIViewController? {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
    
    switch self.tabBarController!.selectedIndex {
    case 0:
      let controller = appDelegate.contactsController.navigationController?.visibleViewController
   
      return controller
    case 1:
      let controller = self.navigationController?.visibleViewController
  
      return controller
    case 2:
      let controller = appDelegate.settingsController.navigationController?.visibleViewController
  
      return controller
    default: break
    }
    return nil
  }
  
  func visibleNavigationController() -> UINavigationController? {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
    
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

    if self.visibleTab() is ChatLogController { return }

    var allConversations = conversations
    allConversations.insert(contentsOf: pinnedConversations, at: 0)
    
    if let index = allConversations.index(where: { (conv) -> Bool in
      return conv.chatID == conversation.chatID
    }) {
      if let muted = allConversations[index].muted, !muted, let chatName = allConversations[index].chatName {
        self.playNotificationSound()
        if UserDefaults.standard.bool(forKey: "In-AppNotifications") {
          self.showInAppNotification(title: chatName, subtitle: self.subtitleForMessage(message: message))
        }
      } else if let chatName = allConversations[index].chatName , allConversations[index].muted == nil   {
        self.playNotificationSound()
        if UserDefaults.standard.bool(forKey: "In-AppNotifications") {
          self.showInAppNotification(title: chatName, subtitle: self.subtitleForMessage(message: message))
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
   
   fileprivate func showInAppNotification(title: String, subtitle: String/*, user: User*/) {
   
       let announcement = Announcement(title: title, subtitle: subtitle, image: nil, duration: 3,
                                       backgroundColor: ThemeManager.currentTheme().inputTextViewColor,
                                       textColor: ThemeManager.currentTheme().generalTitleColor,
                                       dragIndicatordColor: ThemeManager.currentTheme().generalTitleColor) {
       
       //  let user = user
       //  self.autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
        // self.autoSizingCollectionViewFlowLayout?.minimumLineSpacing = 4
        // self.chatLogController = ChatLogController(collectionViewLayout: self.autoSizingCollectionViewFlowLayout!)
        // self.chatLogController?.delegate = self
        // self.chatLogController?.allMessagesRemovedDelegate = self
       //  self.chatLogController?.user = user
       //  self.chatLogController?.hidesBottomBarWhenPushed = true
       }
       guard let controller = self.tabBarController else { return }
       FalconMessenger.show(shout: announcement, to: controller)
   }
   
   fileprivate func playNotificationSound() {
     if UserDefaults.standard.bool(forKey: "In-AppSounds")  {
       SystemSoundID.playFileNamed(fileName: "notification", withExtenstion: "caf")
     }
     if UserDefaults.standard.bool(forKey: "In-AppVibration")  {
       AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
     }
   }
}


