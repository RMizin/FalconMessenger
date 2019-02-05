//
//  GeneralTabBarController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


enum Tabs: Int {
  case contacts = 0
  case chats = 1
  case settings = 2
}

class GeneralTabBarController: UITabBarController {
  
  var onceToken = 0
  
  let splashContainer: SplashScreenContainer = {
    let splashContainer = SplashScreenContainer()
    splashContainer.translatesAutoresizingMaskIntoConstraints = false
    
    return splashContainer
  }()
  
  override func viewDidLoad() {
      super.viewDidLoad()
    chatsController.delegate = self
    setOnlineStatus()
    configureTabBar()
  }
  
  fileprivate func configureTabBar() {
		UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor], for: .normal)
    tabBar.unselectedItemTintColor = ThemeManager.currentTheme().generalSubtitleColor
    tabBar.isTranslucent = false
    tabBar.layer.borderWidth = 0.50
    tabBar.layer.borderColor = UIColor.clear.cgColor
    tabBar.clipsToBounds = true
    setTabs()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
 
    if onceToken == 0 {
      view.addSubview(splashContainer)
      splashContainer.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      splashContainer.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      splashContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      splashContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    onceToken = 1
  }
  
  let chatsController = ChatsTableViewController()
  let contactsController = ContactsController()
  let settingsController = AccountSettingsController()
  
  fileprivate func setTabs() {
    
    contactsController.title = "Contacts"
    chatsController.title = "Chats"
    settingsController.title = "Settings"
    
    let contactsNavigationController = UINavigationController(rootViewController: contactsController)
    let chatsNavigationController = UINavigationController(rootViewController: chatsController)
    let settingsNavigationController = UINavigationController(rootViewController: settingsController)
    
    if #available(iOS 11.0, *) {
      settingsNavigationController.navigationBar.prefersLargeTitles = true
      chatsNavigationController.navigationBar.prefersLargeTitles = true
      contactsNavigationController.navigationBar.prefersLargeTitles = true
    }
    
    let contactsImage =  UIImage(named: "user")
    let chatsImage = UIImage(named: "chat")
    let settingsImage = UIImage(named: "settings")
    
    let contactsTabItem = UITabBarItem(title: contactsController.title, image: contactsImage, selectedImage: nil)
    let chatsTabItem = UITabBarItem(title: chatsController.title, image: chatsImage, selectedImage: nil)
    let settingsTabItem = UITabBarItem(title: settingsController.title, image: settingsImage, selectedImage: nil)
    
    contactsController.tabBarItem = contactsTabItem
    chatsController.tabBarItem = chatsTabItem
    settingsController.tabBarItem = settingsTabItem
    
    let tabBarControllers = [contactsNavigationController, chatsNavigationController as UIViewController, settingsNavigationController]
    viewControllers = tabBarControllers
    selectedIndex = Tabs.chats.rawValue
  }
  
  func presentOnboardingController() {
    guard Auth.auth().currentUser == nil else { return }
    let destination = OnboardingController()
    let newNavigationController = UINavigationController(rootViewController: destination)
    newNavigationController.navigationBar.shadowImage = UIImage()
    newNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
    newNavigationController.modalTransitionStyle = .crossDissolve
    present(newNavigationController, animated: false, completion: nil)
  }
}

extension GeneralTabBarController: ManageAppearance {
  func manageAppearance(_ chatsController: ChatsTableViewController, didFinishLoadingWith state: Bool) {
    let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
    _ = contactsController.view
    _ = settingsController.view
    guard state else { return }
    if isBiometricalAuthEnabled {
      splashContainer.authenticationWithTouchID()
    } else {
      self.splashContainer.showSecuredData()
    }
  }
}
