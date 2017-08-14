//
//  GeneralTabBarController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase


enum tabs: Int {
  case contacts = 0
  case chats = 1
  case settings = 2
}

class GeneralTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
      
      self.view.alpha = 0
      setOnlineStatus()
    }
}

extension GeneralTabBarController: ManageAppearance {
  func manageAppearance(_ chatsController: ChatsController, didFinishLoadingWith state: Bool) {
    if state {
      self.view.alpha = 1
    }
  }
}
