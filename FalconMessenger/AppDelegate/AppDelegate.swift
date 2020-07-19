//
//  AppDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Firebase
import FirebaseMessaging
import FirebaseCore
import UserNotifications
import FirebaseAnalytics

func setUserNotificationToken(token: String) {
  guard let uid = Auth.auth().currentUser?.uid else { return }
  let userReference = Database.database().reference().child("users").child(uid).child("notificationTokens")
  userReference.updateChildValues([token : true])
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

  var window: UIWindow?
  var tabBarController: GeneralTabBarController?
	fileprivate let snapshotLockerView = SnapshotLockerView()
      let splitViewController = SplitViewController()
  
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
   
    ThemeManager.applyTheme(theme: ThemeManager.currentTheme())

		FirebaseConfiguration.shared.setLoggerLevel(.min)
    FirebaseApp.configure()
		Database.database().isPersistenceEnabled = true
  
    userDefaults.configureInitialLaunch()
		
		_ = blacklistManager.initialize
    
    tabBarController = GeneralTabBarController()
    let detailViewController = SplitPlaceholderViewController()

    splitViewController.viewControllers = [tabBarController, detailViewController] as! [UIViewController]
    window = UIWindow(frame: UIScreen.main.bounds)
    if DeviceType.isIPad {
      window?.rootViewController = splitViewController
    } else { //nesessary to disable split screen on iPhones+
      let navigationController = UINavigationController(rootViewController: tabBarController ?? UIViewController())
      navigationController.navigationBar.isHidden = true
      window?.rootViewController = navigationController
    }
  
    window?.makeKeyAndVisible()
    window?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tabBarController?.presentOnboardingController()

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
    } else {
      let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    return true
  }
  
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    setUserNotificationToken(token: fcmToken)
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().setAPNSToken(deviceToken, type: MessagingAPNSTokenType.unknown)
    Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)
    Messaging.messaging().apnsToken = deviceToken
  }
  
  var orientationLock = UIInterfaceOrientationMask.allButUpsideDown
  
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    guard Auth.auth().currentUser != nil else { return .portrait }
    return self.orientationLock
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
		snapshotLockerView.add(to: window)
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
		snapshotLockerView.remove(from: window)
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
  }

  func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		Database.database().purgeOutstandingWrites()
		autoreleasepool {
			try! RealmKeychain.defaultRealm.safeWrite {
				for object in RealmKeychain.defaultRealm.objects(Message.self).filter("status == %@", messageStatusSending) {
					object.status = messageStatusNotSent
				}
			}
		}
  }
}
