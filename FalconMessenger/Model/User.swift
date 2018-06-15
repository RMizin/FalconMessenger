//
//  User.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/6/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class User: NSObject, NSCoding {
  
  var id: String?
  var name: String?
  var bio: String?
  var photoURL: String?
  var thumbnailPhotoURL: String?
  var phoneNumber: String?
  var onlineStatus: AnyObject?
  var isSelected: Bool! = false // local only
  
  init(dictionary: [String: AnyObject]) {
    self.id = dictionary["id"] as? String
    self.name = dictionary["name"] as? String
    self.bio = dictionary["bio"] as? String
    self.photoURL = dictionary["photoURL"] as? String
    self.thumbnailPhotoURL = dictionary["thumbnailPhotoURL"] as? String
    self.phoneNumber = dictionary["phoneNumber"] as? String
    self.onlineStatus = dictionary["OnlineStatus"]// as? AnyObject
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(id, forKey: "id")
    aCoder.encode(name, forKey: "name")
    aCoder.encode(bio, forKey: "bio")
    aCoder.encode(photoURL, forKey: "photoURL")
    aCoder.encode(thumbnailPhotoURL, forKey: "thumbnailPhotoURL")
    aCoder.encode(phoneNumber, forKey: "phoneNumber")
    aCoder.encode(onlineStatus, forKey: "OnlineStatus")
  }
  
  required init?(coder aDecoder: NSCoder) {
    id = aDecoder.decodeObject(forKey: "id") as? String
    name = aDecoder.decodeObject(forKey: "name") as? String
    bio = aDecoder.decodeObject(forKey: "bio") as? String
    photoURL =  aDecoder.decodeObject(forKey: "photoURL") as? String
    thumbnailPhotoURL = aDecoder.decodeObject(forKey: "thumbnailPhotoURL") as? String
    phoneNumber = aDecoder.decodeObject(forKey: "phoneNumber") as? String
    onlineStatus = aDecoder.decodeObject(forKey: "OnlineStatus") as AnyObject
  }
}

extension User { // local only
  var titleFirstLetter: String {
    guard let name = name else {return "" }
    return String(name[name.startIndex]).uppercased()
  }
}
