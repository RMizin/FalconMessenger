//
//  AppDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  
     FirebaseApp.configure()
     Database.database().isPersistenceEnabled = true
    
    window = UIWindow(frame: UIScreen.main.bounds)
    var mainController = UIViewController()
    
   
     mainController = GeneralTabBarController()
      
      let navigationController = UINavigationController(rootViewController: mainController)
      navigationController.navigationBar.isTranslucent = false
      
      self.window?.rootViewController = navigationController
      self.window?.makeKeyAndVisible()
      navigationController.view.alpha = 0
    
    DispatchQueue.main.async {
      if Auth.auth().currentUser == nil {
        let destination = OnboardingController()
        
        
        let newNavigationController = UINavigationController(rootViewController: destination)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        mainController.modalPresentationStyle = .overCurrentContext
        
        mainController.present(newNavigationController, animated: false, completion: { 
             navigationController.view.alpha = 1
        })
      } else {
            navigationController.view.alpha = 1
      }
    }

    return true
  }
  
 
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Pass device token to auth
    Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.prod)
    
    // Further handling of the device token if needed by the app
    // ...
  }
  
  func application(_ application: UIApplication,
                   didReceiveRemoteNotification notification: [AnyHashable : Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if Auth.auth().canHandleNotification(notification) {
      completionHandler(UIBackgroundFetchResult.noData)
      return
    }
    
    // This notification is not auth related, developer should handle it.
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
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

