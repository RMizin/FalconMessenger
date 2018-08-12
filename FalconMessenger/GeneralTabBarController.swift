//
//  GeneralTabBarController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import LocalAuthentication

enum tabs: Int {
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
    configureTabBar()
    setOnlineStatus()
  }
  
  fileprivate func configureTabBar() {
    UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor], for: .normal)
    tabBar.unselectedItemTintColor = ThemeManager.currentTheme().generalSubtitleColor
    tabBar.isTranslucent = false
    tabBar.clipsToBounds = true
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
}

extension GeneralTabBarController: ManageAppearance {
  func manageAppearance(_ chatsController: ChatsTableViewController, didFinishLoadingWith state: Bool) {
    let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
    guard state, isBiometricalAuthEnabled else { splashContainer.showSecuredData(); return }
    splashContainer.authenticationWithTouchID()
  }
}
