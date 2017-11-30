//
//  AppDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import AudioToolbox


public let deviceScreen = UIScreen.main.bounds

func setUserNotificationToken(token: String) {
  
  guard let uid = Auth.auth().currentUser?.uid else {
    return
  }
  let userReference = Database.database().reference().child("users").child(uid).child("notificationTokens")
  userReference.updateChildValues([token : true])
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  
    if #available(iOS 10.0, *) {
      // For iOS 10 display notification (sent via APNS)
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
     FirebaseApp.configure()
     Database.database().isPersistenceEnabled = true
    
     window = UIWindow(frame: UIScreen.main.bounds)
  
     let mainController = GeneralTabBarController()
    
     setTabs(mainController: mainController)
      
     self.window?.rootViewController = mainController
     self.window?.makeKeyAndVisible()
     self.window?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    
    
    let userDefaults = UserDefaults.standard
    
    if userDefaults.bool(forKey: "hasRunBefore") == false {
  
      do {
        try Auth.auth().signOut()
      } catch {}
      
      userDefaults.set(true, forKey: "hasRunBefore")
      userDefaults.synchronize()
      
      presentController(with: mainController)
    } else {
     presentController(with: mainController)
    }
    
    setDeaultsForSettings()
    
    return true
  }
  
  func presentController(with mainController: UITabBarController) {
    if Auth.auth().currentUser == nil {
      
      let destination = OnboardingController()
      let newNavigationController = UINavigationController(rootViewController: destination)
      let theme = Theme.Default
      ThemeManager.applyTheme(theme: theme)
      newNavigationController.navigationBar.shadowImage = UIImage()
      newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
      newNavigationController.modalTransitionStyle = .crossDissolve
      mainController.present(newNavigationController, animated: false, completion: {
      })
    } else {
      let theme = ThemeManager.currentTheme()
      ThemeManager.applyTheme(theme: theme)

    }
  }
  
 let chatsController = ChatsController()
  func setTabs(mainController : UITabBarController) {
    
    let contactsController = ContactsController()
    _ = contactsController.view
    contactsController.title = "Contacts"
    let contactsNavigationController = UINavigationController(rootViewController: contactsController)
    
  //  contactsNavigationController.navigationBar.isTranslucent = false
    if #available(iOS 11.0, *) {
      contactsNavigationController.navigationBar.prefersLargeTitles = true
    }
    
    chatsController.delegate = mainController as? ManageAppearance
    _ = chatsController.view
    chatsController.title = "Chats"
    let chatsNavigationController = UINavigationController(rootViewController: chatsController)

    if #available(iOS 11.0, *) {
      chatsNavigationController.navigationBar.prefersLargeTitles = true
    }
    
    let settingsController = AccountSettingsController()
    _ = settingsController.view
    settingsController.title = "Settings"
    let settingsNavigationController = UINavigationController(rootViewController: settingsController)

   // settingsNavigationController.navigationBar.isTranslucent = false
    if #available(iOS 11.0, *) {
      settingsNavigationController.navigationBar.prefersLargeTitles = true
    }
    
    let contactsTabItem = UITabBarItem(title: contactsController.title, image: UIImage(named:"user"), selectedImage: UIImage(named:""))
    let chatsTabItem = UITabBarItem(title: chatsController.title, image: UIImage(named:"chat"), selectedImage: UIImage(named:""))
    let settingsTabItem = UITabBarItem(title: settingsController.title, image: UIImage(named:"settings"), selectedImage: UIImage(named:""))
    contactsController.tabBarItem = contactsTabItem
    chatsController.tabBarItem = chatsTabItem
    settingsController.tabBarItem = settingsTabItem
    
    let tabBarControllers = [contactsNavigationController, chatsNavigationController as UIViewController, settingsNavigationController]
    mainController.setViewControllers((tabBarControllers), animated: false)
    mainController.selectedIndex = tabs.chats.rawValue
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
//    if notification.request.content.title == "New user" {
//    //  NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadPigeonContacts"), object: nil)
//    }
    
    if ( UIApplication.shared.applicationState == UIApplicationState.active) {
      if self.chatsController.navigationController?.visibleViewController is ChatLogController {
         print(notification.request.content)
        
      } else {
        if UserDefaults.standard.bool(forKey: "In-AppSounds")  {
          SystemSoundID.playFileNamed(fileName: "notification", withExtenstion: "caf")
        }
      }
    }
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
   
//    if response.notification.request.content.title == "New user" {
//      // NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadPigeonContacts"), object: nil)
//    }
    completionHandler()
  }
  
  
  func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
    print("Firebase registration token: \(fcmToken)")
    setUserNotificationToken(token: fcmToken)
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    
    Messaging.messaging()
      .setAPNSToken(deviceToken, type: MessagingAPNSTokenType.prod)
    
     Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.prod)
        Messaging.messaging().apnsToken = deviceToken// as Data
    
        let token = Messaging.messaging().fcmToken
        print("FCM token: \(token ?? "")")
  }
  
  func setDeaultsForSettings() {
    if UserDefaults.standard.object(forKey: "In-AppSounds") == nil {
      UserDefaults.standard.set(true, forKey: "In-AppSounds")
    }
  }
  
  var orientationLock = UIInterfaceOrientationMask.allButUpsideDown
  
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    
    if Auth.auth().currentUser == nil {
      return UIInterfaceOrientationMask.portrait
    } else {
      return self.orientationLock
    }
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    /* probably will be removed later */
   //  NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadPigeonContacts"), object: nil)
    
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
}
