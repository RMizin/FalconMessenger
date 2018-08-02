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
    super.init()
    self.id = dictionary["id"] as? String
    self.name = dictionary["name"] as? String
    self.bio = dictionary["bio"] as? String
    self.photoURL = dictionary["photoURL"] as? String
    self.thumbnailPhotoURL = dictionary["thumbnailPhotoURL"] as? String
    self.phoneNumber = dictionary["phoneNumber"] as? String
    self.onlineStatus = dictionary["OnlineStatus"]// as? AnyObject
  }
}
  
extension User { // local only
  var titleFirstLetter: String {
    guard let name = name else {return "" }
    return String(name[name.startIndex]).uppercased()
  }
}
