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
    
    var appDelegate:AppDelegate! = UIApplication.shared.delegate as! AppDelegate
    
    switch self.tabBarController!.selectedIndex {
    case 0:
      let controller = appDelegate.contactsController.navigationController?.visibleViewController
      appDelegate = nil
      return controller
    case 1:
      let controller = self.navigationController?.visibleViewController
      appDelegate = nil
      return controller
    case 2:
      let controller = appDelegate.settingsController.navigationController?.visibleViewController
      appDelegate = nil
      return controller
    default: break
    }
    return nil
  }
  
  func visibleNavigationController() -> UINavigationController? {
    
    var appDelegate:AppDelegate! = UIApplication.shared.delegate as! AppDelegate
    
    switch self.tabBarController!.selectedIndex {
    case 0:
      let controller = appDelegate.contactsController.navigationController
      appDelegate = nil
      return controller
    case 1:
      let controller = navigationController
      appDelegate = nil
      return controller
    case 2:
      let controller = appDelegate.settingsController.navigationController
      appDelegate = nil
      return controller
    default: break
    }
    return nil
  }
  
  func handleInAppSoundPlaying(message: Message, conversation: Conversation) {

    if self.visibleTab() is ChatLogController { return }
     self.playNotificationSound()
    
    if UserDefaults.standard.bool(forKey: "In-AppNotifications") {
      self.showInAppNotification(title: conversation.chatName ?? "" , subtitle: self.subtitleForMessage(message: message))//, user: user)
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
   
       let announcement = Announcement(title: title, subtitle: subtitle, image: nil, duration: 3, backgroundColor: ThemeManager.currentTheme().inputTextViewColor, textColor: ThemeManager.currentTheme().generalTitleColor, dragIndicatordColor: ThemeManager.currentTheme().generalTitleColor) {
       
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
       Pigeon_project.show(shout: announcement, to: controller)
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


