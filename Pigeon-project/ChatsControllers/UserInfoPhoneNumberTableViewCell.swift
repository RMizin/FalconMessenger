//
//  UserInfoPhoneNumberTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 2/2/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import FTPopOverMenu_Swift

class UserInfoPhoneNumberTableViewCell: UITableViewCell {
  
  weak var userInfoTableViewController: UserInfoTableViewController?
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
     addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc func handleLongTap(_ longPressGesture: UILongPressGestureRecognizer) {
    var contextMenuItems = [ContextMenuItems.copyItem]
    guard let indexPath = self.userInfoTableViewController?.tableView.indexPath(for: self) else { return }

    FTPopOverMenu.showForSender(sender: self, with: contextMenuItems, done: { (selectedIndex) in
      if contextMenuItems[selectedIndex] == ContextMenuItems.copyItem {
        UIPasteboard.general.string = self.textLabel?.text
      }
    }) {
       self.userInfoTableViewController?.tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
}

