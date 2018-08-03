//
//  GlobalDataStorage.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/1/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


let globalDataStorage = GlobalDataStorage()

class GlobalDataStorage: NSObject {
  
  var shouldReloadContactsControllerAfterChangingTheme = false
  
  var shouldReloadChatsControllerAfterChangingTheme = false
  
  var localPhones: [String] = [] {
    didSet {
      NotificationCenter.default.post(name: .localPhonesUpdated, object: nil)
    }
  }
  
 // var preparedNumbers = [String]()
  
  var falconUsers: [User] = [] {
    didSet {
      NotificationCenter.default.post(name: .falconUsersUpdated, object: nil)
    }
  }
  
  let imageSourcePhotoLibrary = "imageSourcePhotoLibrary"
  
  let imageSourceCamera = "imageSourceCamera"
  
  var isInsertingCellsToTop: Bool = false
  
  var contentSizeWhenInsertingToTop: CGSize?
}

extension NSNotification.Name {
  static let falconUsersUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".falconUsers")
  static let localPhonesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".localPhones")
}
