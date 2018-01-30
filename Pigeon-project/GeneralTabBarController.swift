//
//  GeneralTabBarController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


enum tabs: Int {
  case contacts = 0
  case chats = 1
  case settings = 2
}


class GeneralTabBarController: UITabBarController {
  
  let splash = UIImageView(frame: UIScreen.main.bounds)
  var onceToken = 0
  
  override func viewDidLoad() {
      super.viewDidLoad()
    //UITabBar.appearance().tintColor = UIColor.white
    UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor], for: .normal)
    tabBar.unselectedItemTintColor = ThemeManager.currentTheme().generalSubtitleColor
    setOnlineStatus()
    tabBar.isTranslucent = false
    tabBar.layer.borderWidth = 0.50
    tabBar.layer.borderColor = UIColor.clear.cgColor
    tabBar.clipsToBounds = true
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if onceToken == 0 {
      splash.image = ThemeManager.currentTheme().splashImage
      splash.tag = 13
      view.addSubview(splash)
    }
    onceToken = 1
  }
}

extension GeneralTabBarController: ManageAppearance {
  func manageAppearance(_ chatsController: ChatsController, didFinishLoadingWith state: Bool) {
    if state {
      splash.removeFromSuperview()
    }
  }
}
