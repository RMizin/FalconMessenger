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

    override func viewDidLoad() {
        super.viewDidLoad()
      tabBar.unselectedItemTintColor = UIColor(red:0.64, green:0.64, blue:0.64, alpha:1.0)
      setOnlineStatus()
      tabBar.isTranslucent = false
    }
   let splash = UIImageView(frame: UIScreen.main.bounds)
  
   var onceToken = 0
  
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
      //self.view.alpha = 1
      print("\n did finished loading protocol \n")
      splash.removeFromSuperview()
    }
  }
}
