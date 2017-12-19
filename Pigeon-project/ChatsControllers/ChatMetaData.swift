//
//  ChatMetaData.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/30/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class ChatMetaData:  NSObject  {
  
  var badge: Int?
  var pinned: Bool?
  
  init(dictionary: [String: AnyObject]?) {
    super.init()
    
    badge = dictionary?["badge"] as? Int
    pinned = dictionary?["pinned"] as? Bool
    
  }
}
