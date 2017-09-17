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
     self.window?.backgroundColor = .white
    
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
    
    return true
  }
  
  
  func presentController(with mainController: UITabBarController) {
    if Auth.auth().currentUser == nil {
      
      let destination = OnboardingController()
      let newNavigationController = UINavigationController(rootViewController: destination)
  
      newNavigationController.navigationBar.backgroundColor = .white
      newNavigationController.navigationBar.shadowImage = UIImage()
      newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
      newNavigationController.modalTransitionStyle = .crossDissolve
      newNavigationController.navigationBar.isTranslucent = false
      
      mainController.present(newNavigationController, animated: false, completion: {
      })
    }
  }
  
 let chatsController = ChatsController()
  func setTabs(mainController : UITabBarController) {
    
    let contactsController = ContactsController()
    _ = contactsController.view
    contactsController.title = "Contacts"
    let contactsNavigationController = UINavigationController(rootViewController: contactsController)
    
    contactsNavigationController.view.backgroundColor = UIColor.white
    contactsNavigationController.navigationBar.backgroundColor = UIColor.white
    contactsNavigationController.navigationBar.isTranslucent = false
    
  //  UINavigationBar.appearance().shadowImage = UIImage()
   // UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
  
    
    
    chatsController.delegate = mainController as? ManageAppearance
    _ = chatsController.view
    chatsController.title = "Chats"
    let chatsNavigationController = UINavigationController(rootViewController: chatsController)
    chatsNavigationController.view.backgroundColor = UIColor.white
    chatsNavigationController.navigationBar.backgroundColor = UIColor.white
    chatsNavigationController.navigationBar.isTranslucent = false
    
    let settingsController = SettingsViewControllersContainer()
    _ = settingsController.view
    settingsController.title = "Settings"
    let settingsNavigationController = UINavigationController(rootViewController: settingsController)
    settingsNavigationController.view.backgroundColor = UIColor.white
    settingsNavigationController.navigationBar.backgroundColor = UIColor.white
    settingsNavigationController.navigationBar.isTranslucent = false
    
    
    let contactsTabItem = UITabBarItem(title: contactsController.title, image: UIImage(named:"TabIconContacts"), selectedImage: UIImage(named:"TabIconContacts_Highlighted"))
    let chatsTabItem = UITabBarItem(title: chatsController.title, image: UIImage(named:"TabIconMessages"), selectedImage: UIImage(named:"TabIconMessages_Highlighted"))
    let settingsTabItem = UITabBarItem(title: settingsController.title, image: UIImage(named:"TabIconSettings"), selectedImage: UIImage(named:"TabIconSettings_Highlighted"))
    contactsController.tabBarItem = contactsTabItem
    chatsController.tabBarItem = chatsTabItem
    settingsController.tabBarItem = settingsTabItem
    
    let tabBarControllers = [contactsNavigationController, chatsNavigationController as UIViewController, settingsNavigationController]
    mainController.setViewControllers((tabBarControllers), animated: false)
    mainController.selectedIndex = tabs.chats.rawValue
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
    if ( UIApplication.shared.applicationState == UIApplicationState.active) {
      if self.chatsController.navigationController?.visibleViewController is ChatLogController {
        print("yep")
         print(notification.request.content )
        
      } else {
        print("NOPE")
    
         SystemSoundID.playFileNamed(fileName: "notification", withExtenstion: "caf")
      }
    }
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
  
  
//  var orientationLock = UIInterfaceOrientationMask.all
//  
//  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//    return self.orientationLock
//  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
   // UIApplication.shared.applicationIconBadgeNumber = 0
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

