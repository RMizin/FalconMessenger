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
    }
}
