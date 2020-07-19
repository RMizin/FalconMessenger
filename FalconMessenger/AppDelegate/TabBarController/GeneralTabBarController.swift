//
//  GeneralTabBarController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import LocalAuthentication

enum Tabs: Int {
  case contacts = 0
  case chats = 1
  case settings = 2
}

class CurrentTab {
    static let shared = CurrentTab()
    var index = 0

}
class GeneralTabBarController: UITabBarController {
  
  var onceToken = 0
  
  let splashContainer: SplashScreenContainer = {
    let splashContainer = SplashScreenContainer()
    splashContainer.translatesAutoresizingMaskIntoConstraints = false
    return splashContainer
  }()


    override var selectedIndex: Int {
        didSet {
            CurrentTab.shared.index = selectedIndex
        }
    }
    
  override func viewDidLoad() {
      super.viewDidLoad()
    
    chatsController.delegate = self
    configureTabBar()
		setOnlineStatus()
		NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
  }

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc fileprivate func changeTheme() {
		tabBar.unselectedItemTintColor = ThemeManager.currentTheme().unselectedButtonTintColor
		UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().barTextColor],
																										 for: .normal)
	}

  
  fileprivate func configureTabBar() {
		UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().barTextColor],
																										 for: .normal)
    tabBar.unselectedItemTintColor = ThemeManager.currentTheme().unselectedButtonTintColor
    tabBar.isTranslucent = false
    tabBar.clipsToBounds = true
    setTabs()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
    guard onceToken == 0, isBiometricalAuthEnabled else { onceToken = 1; return }
    view.addSubview(splashContainer)
    splashContainer.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    splashContainer.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    splashContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    splashContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    onceToken = 1
  }
  
  func presentOnboardingController() {
    guard Auth.auth().currentUser == nil else { return }
    let destination = OnboardingController()
    let newNavigationController = UINavigationController(rootViewController: destination)
		newNavigationController.navigationBar.setValue(true, forKey: "hidesShadow")
    newNavigationController.modalTransitionStyle = .crossDissolve
    newNavigationController.modalPresentationStyle = .overFullScreen
    if #available(iOS 13.0, *) {
        newNavigationController.isModalInPresentation = true
    }
  
    if DeviceType.isIPad {
      splitViewController?.show(newNavigationController, sender: self)
    } else {
      present(newNavigationController, animated: false, completion: nil)
    }
  }
  
  let chatsController = ChatsTableViewController()
  let contactsController = ContactsController()
  let settingsController = AccountSettingsController()
  
  fileprivate func setTabs() {
    
    contactsController.navigationItem.title = "Contacts"
    chatsController.navigationItem.title = "Chats"
    settingsController.navigationItem.title = "Settings"
    
    let contactsNavigationController = UINavigationController(rootViewController: contactsController)
    let chatsNavigationController = UINavigationController(rootViewController: chatsController)
    let settingsNavigationController = UINavigationController(rootViewController: settingsController)
		settingsNavigationController.navigationBar.setValue(true, forKey: "hidesShadow")

    if #available(iOS 11.0, *) {
      settingsNavigationController.navigationBar.prefersLargeTitles = true
      chatsNavigationController.navigationBar.prefersLargeTitles = true
      contactsNavigationController.navigationBar.prefersLargeTitles = true
    }
    
    let contactsImage =  UIImage(named: "user")
    let chatsImage = UIImage(named: "chat")
    let settingsImage = UIImage(named: "settings")
    
    let contactsTabItem = UITabBarItem(title: contactsController.navigationItem.title, image: contactsImage, selectedImage: nil)
    let chatsTabItem = UITabBarItem(title: chatsController.navigationItem.title, image: chatsImage, selectedImage: nil)
    let settingsTabItem = UITabBarItem(title: settingsController.navigationItem.title, image: settingsImage, selectedImage: nil)
    
    contactsController.tabBarItem = contactsTabItem
    chatsController.tabBarItem = chatsTabItem
    settingsController.tabBarItem = settingsTabItem
    
    let tabBarControllers = [contactsNavigationController, chatsNavigationController as UIViewController, settingsNavigationController]
    viewControllers = tabBarControllers
    selectedIndex = Tabs.chats.rawValue
  }
}

extension GeneralTabBarController: ManageAppearance {
  func manageAppearance(_ chatsController: ChatsTableViewController, didFinishLoadingWith state: Bool) {
    let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
    guard state, isBiometricalAuthEnabled else { splashContainer.showSecuredData(); return }
    splashContainer.authenticationWithTouchID()
  }
}
