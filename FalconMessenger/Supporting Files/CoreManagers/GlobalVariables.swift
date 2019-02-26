//
//  GlobalVariables.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/1/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

let globalVariables = GlobalVariables()

final class GlobalVariables: NSObject {
	let reportDatabaseURL = "https://pigeon-project-79c81-d6fdd.firebaseio.com/"
	let imageSourcePhotoLibrary = "imageSourcePhotoLibrary"
	let imageSourceCamera = "imageSourceCamera"
	var isInsertingCellsToTop: Bool = false
	var contentSizeWhenInsertingToTop: CGSize?
  var localPhones: [String] = [] {
    didSet {
      NotificationCenter.default.post(name: .localPhonesUpdated, object: nil)
    }
  }
}

extension NSNotification.Name {
	static let profilePictureDidSet = NSNotification.Name(Bundle.main.bundleIdentifier! + ".profilePictureDidSet")
	static let blacklistUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".blacklistUpdated")
  static let localPhonesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".localPhones")
  static let authenticationSucceeded = NSNotification.Name(Bundle.main.bundleIdentifier! + ".authenticationSucceeded")
  static let inputViewResigned = NSNotification.Name(Bundle.main.bundleIdentifier! + ".inputViewResigned")
  static let inputViewResponded = NSNotification.Name(Bundle.main.bundleIdentifier! + ".inputViewResponded")
	static let messageSent = NSNotification.Name(Bundle.main.bundleIdentifier! + ".messageSent")
}
