//
//  User.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/6/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class User: NSObject {

  var id: String?
  @objc var name: String?
  var bio: String?
  var photoURL: String?
  var thumbnailPhotoURL: String?
  var phoneNumber: String?
  var onlineStatus: AnyObject?
  var isSelected: Bool! = false // local only
  
  init(dictionary: [String: AnyObject]) {
    id = dictionary["id"] as? String
    name = dictionary["name"] as? String
    bio = dictionary["bio"] as? String
    photoURL = dictionary["photoURL"] as? String
    thumbnailPhotoURL = dictionary["thumbnailPhotoURL"] as? String
    phoneNumber = dictionary["phoneNumber"] as? String
    onlineStatus = dictionary["OnlineStatus"]// as? AnyObject
  }
}

extension User { // local only
  var titleFirstLetter: String {
    guard let name = name else {return "" }
    return String(name[name.startIndex]).uppercased()
  }
}
