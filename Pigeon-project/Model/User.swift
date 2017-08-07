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
  var name: String?
  var photoURL: String?
  var phoneNumber: String?
  var onlineStatus: String?
  
  
  init(dictionary: [String: AnyObject]) {
    self.id = dictionary["id"] as? String
    self.name = dictionary["name"] as? String
    self.photoURL = dictionary["photoURL"] as? String
    self.phoneNumber = dictionary["phoneNumber"] as? String
    self.onlineStatus = dictionary["OnlineStatus"] as? String
  
  }
  
  
}
