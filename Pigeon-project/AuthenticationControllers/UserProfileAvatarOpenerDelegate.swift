//
//  UserProfileAvatarOpenerDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

extension UserProfileController: AvatarOpenerDelegate {
  func avatarOpener(avatarPickerDidPick image: UIImage) {
    userProfileContainerView.profileImageView.showActivityIndicator()
    userProfileDataDatabaseUpdater.deleteCurrentPhoto { (isDeleted) in
      self.userProfileDataDatabaseUpdater.updateUserProfile(with: image, completion: { (isUpdated) in
        self.userProfileContainerView.profileImageView.hideActivityIndicator()
        guard isUpdated else {
          basicErrorAlertWith(title: basicErrorTitleForAlert, message: thumbnailUploadError, controller: self)
          return
        }
        self.userProfileContainerView.profileImageView.image = image
       
      })
    }
  }
  
  func avatarOpener(didPerformDeletionAction: Bool) {
    userProfileContainerView.profileImageView.showActivityIndicator()
    userProfileDataDatabaseUpdater.deleteCurrentPhoto { (isDeleted) in
      self.userProfileContainerView.profileImageView.hideActivityIndicator()
      guard isDeleted else {
           basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self)
        return
      }
      self.userProfileContainerView.profileImageView.image = nil
    }
  }
}
