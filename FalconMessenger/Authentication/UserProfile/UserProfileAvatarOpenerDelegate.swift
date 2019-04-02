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
    userProfileDataDatabaseUpdater.deleteCurrentPhoto { [weak self] (_) in
      self?.userProfileDataDatabaseUpdater.updateUserProfile(with: image, completion: { [weak self] (isUpdated) in
        self?.userProfileContainerView.profileImageView.hideActivityIndicator()
        guard isUpdated, self != nil else {
          basicErrorAlertWith(title: basicErrorTitleForAlert, message: thumbnailUploadError, controller: self!)
          return
        }
        self?.userProfileContainerView.profileImageView.image = image
       
      })
    }
  }
  
	func avatarOpener(didPerformDeletionAction: Bool) {
    userProfileContainerView.profileImageView.showActivityIndicator()
    userProfileDataDatabaseUpdater.deleteCurrentPhoto { [weak self] (isDeleted) in
      self?.userProfileContainerView.profileImageView.hideActivityIndicator()
      guard isDeleted, self != nil else {
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self!)
        return
      }
      self?.userProfileContainerView.profileImageView.image = nil
    }
  }
}
