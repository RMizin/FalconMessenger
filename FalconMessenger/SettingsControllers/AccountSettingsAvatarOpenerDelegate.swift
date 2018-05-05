//
//  AccountSettingsAvatarOpenerDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 4/4/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension AccountSettingsController: AvatarOpenerDelegate {
  func avatarOpener(avatarPickerDidPick image: UIImage) {
    userProfileContainerView.profileImageView.showActivityIndicator()
    userProfileDataDatabaseUpdater.deleteCurrentPhoto { [weak self] (isDeleted) in
      self?.userProfileDataDatabaseUpdater.updateUserProfile(with: image, completion: { [weak self] (isUpdated) in
        self?.userProfileContainerView.profileImageView.hideActivityIndicator()
        guard isUpdated else {
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
      guard isDeleted else {
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self!)
        return
      }
      self?.userProfileContainerView.profileImageView.image = nil
    }
  }
}
