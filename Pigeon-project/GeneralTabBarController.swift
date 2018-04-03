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
  
  var onceToken = 0
  
  let splash: UIImageView  = {
    let splash = UIImageView()
    splash.translatesAutoresizingMaskIntoConstraints = false
    
    return splash
  }()
  
  override func viewDidLoad() {
      super.viewDidLoad()
   
    setOnlineStatus()
    configureTabBar()   
  }
  
  fileprivate func configureTabBar() {
    UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor], for: .normal)
    tabBar.unselectedItemTintColor = ThemeManager.currentTheme().generalSubtitleColor
    tabBar.isTranslucent = false
    tabBar.layer.borderWidth = 0.50
    tabBar.layer.borderColor = UIColor.clear.cgColor
    tabBar.clipsToBounds = true
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    /* sometimes on iPhone X if after device rotation if tabbar wasn't visible, tabBar height is not updating, next line fixes this bug */
    tabBar.sizeToFit()
    
    if onceToken == 0 {
      splash.image = ThemeManager.currentTheme().splashImage
      splash.tag = 13
      view.addSubview(splash)
      splash.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      splash.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      splash.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      splash.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    onceToken = 1
  }
}

extension GeneralTabBarController: ManageAppearance {
  func manageAppearance(_ chatsController: ChatsTableViewController, didFinishLoadingWith state: Bool) {
    if state {
      splash.removeFromSuperview()
    }
  }
}
