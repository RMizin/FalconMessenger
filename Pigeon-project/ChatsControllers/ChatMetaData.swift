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
  
  init(dictionary: [String: Int]?) {
    super.init()
    
    badge = dictionary?["badge"] //as? Int
    
  }
}
