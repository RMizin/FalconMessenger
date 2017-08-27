//
//  Message.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

class Message:  NSObject  {

    var fromId: String?
    var text: String?
    var timestamp: NSNumber?
    var toId: String?
  
    var status: String?
    var seen: Bool?
  
    var imageUrl: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
  
  var localImage: UIImage?
  
    var videoUrl: String?
      
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
  
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        toId = dictionary["toId"] as? String
      
        status = dictionary["status"] as? String
        seen = dictionary["seen"] as? Bool
        
        imageUrl = dictionary["imageUrl"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
      
        localImage = dictionary["localImage"] as? UIImage
    }
}
