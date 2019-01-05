//
//  PopOverMenuConfiguration.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 7/8/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import FTPopOverMenu_Swift

extension ChatLogViewController {
  func configureCellContextMenuView() {
    let config = FTConfiguration.shared
    config.backgoundTintColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
    config.borderColor = UIColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 0.0)
    config.menuWidth = 100
    config.menuSeparatorColor = .clear
    config.menuRowHeight = 40
    config.cornerRadius = 25
  }
}
