//
//  GeneralTabBarController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseAuth


enum tabs: Int {
  case contacts = 0
  case chats = 1
  case settings = 2
  
}

class GeneralTabBarController: UITabBarController {

  
    override func viewDidLoad() {
        super.viewDidLoad()
    
      delegate = self
      setTabs()
    }
  
  
  fileprivate func setTabs () {
    
    let contactsController = ContactsController()
    let chatsController = ChatsController()
    let settingsController = SettingsViewControllersContainer()
    
    let contactsTabItem = UITabBarItem(title: contactsController.title, image: UIImage(named:"TabIconContacts"), selectedImage: UIImage(named:"TabIconContacts_Highlighted"))
    let chatsTabItem = UITabBarItem(title: chatsController.title, image: UIImage(named:"TabIconMessages"), selectedImage: UIImage(named:"TabIconMessages_Highlighted"))
    let settingsTabItem = UITabBarItem(title: settingsController.title, image: UIImage(named:"TabIconSettings"), selectedImage: UIImage(named:"TabIconSettings_Highlighted"))
    contactsController.tabBarItem = contactsTabItem
    chatsController.tabBarItem = chatsTabItem
    settingsController.tabBarItem = settingsTabItem
    
    let tabBarControllers = [contactsController, chatsController, settingsController]
    setViewControllers(tabBarControllers, animated: false)
  }
}


extension GeneralTabBarController: UITabBarControllerDelegate {

  override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    self.title = item.title
  }
}
