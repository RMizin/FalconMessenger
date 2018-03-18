//
//  ChatsController+NotificationsHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/15/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//
/*
import UIKit
import AudioToolbox
import Firebase


extension ChatsController {
  
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
  
  func handleInAppSoundPlaying(_ message: Message, for unhandledNewMessages: Int) {
    if self.unhandledNewMessages < 0 {
      self.unhandledNewMessages = 0
      return
    }
    guard let uid = Auth.auth().currentUser?.uid, let chatPartnerID = message.chatPartnerId(), self.unhandledNewMessages == 0 else { return }
    if self.visibleTab() is ChatLogController { return }
    
    let reference = Database.database().reference().child("users").child(chatPartnerID)
    reference.observeSingleEvent(of: .value, with: { (snapshot) in
      guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
      dictionary.updateValue(chatPartnerID as AnyObject, forKey: "id")
      let user = User(dictionary: dictionary)
      
      guard !self.isAppJustDidBecomeActive, self.isAppLoaded, message.fromId != uid else {
         self.isAppJustDidBecomeActive = false
        return
      }
   
      self.playNotificationSound()
      if UserDefaults.standard.bool(forKey: "In-AppNotifications") {
        self.showInAppNotification(title: user.name ?? "" , subtitle: self.subtitleForMessage(message: message), user: user)
      }
     
      self.isAppJustDidBecomeActive = false
    })
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
  
  fileprivate func showInAppNotification(title: String, subtitle: String, user: User) {
    
    let announcement = Announcement(title: title, subtitle: subtitle, image: nil, duration: 3, backgroundColor: ThemeManager.currentTheme().inputTextViewColor, textColor: ThemeManager.currentTheme().generalTitleColor, dragIndicatordColor: ThemeManager.currentTheme().generalTitleColor) {
      
      let user = user
      self.autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
      self.autoSizingCollectionViewFlowLayout?.minimumLineSpacing = 4
      self.chatLogController = ChatLogController(collectionViewLayout: self.autoSizingCollectionViewFlowLayout!)
      self.chatLogController?.delegate = self
      self.chatLogController?.allMessagesRemovedDelegate = self
      self.chatLogController?.user = user
      self.chatLogController?.hidesBottomBarWhenPushed = true
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

*/















