//
//  GlobalDataStorage.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/1/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


let globalDataStorage = GlobalDataStorage()

final class GlobalDataStorage: NSObject {
  
  var localPhones: [String] = [] {
    didSet {
      NotificationCenter.default.post(name: .localPhonesUpdated, object: nil)
    }
  }
  
  var falconUsers: [User] = [] {
    didSet {
      NotificationCenter.default.post(name: .falconUsersUpdated, object: nil)
    }
  }
  
  let imageSourcePhotoLibrary = "imageSourcePhotoLibrary"
  
  let imageSourceCamera = "imageSourceCamera"
  
  static let reportDatabaseURL = "https://pigeon-project-79c81-d6fdd.firebaseio.com/"
  
  var isInsertingCellsToTop: Bool = false
  
  var contentSizeWhenInsertingToTop: CGSize?
}

extension NSNotification.Name {
  static let falconUsersUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".falconUsers")
  static let localPhonesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".localPhones")
}
