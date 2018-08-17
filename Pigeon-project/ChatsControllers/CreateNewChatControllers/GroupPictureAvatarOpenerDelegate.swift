//
//  GroupPictureAvatarOpenerDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension GroupProfileTableViewController: AvatarOpenerDelegate {
  func avatarOpener(avatarPickerDidPick image: UIImage) {
    groupProfileTableHeaderContainer.profileImageView.image = image
  }
  
  func avatarOpener(didPerformDeletionAction: Bool) {
    groupProfileTableHeaderContainer.profileImageView.image = nil
  }
}
