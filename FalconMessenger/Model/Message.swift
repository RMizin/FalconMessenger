//
//  Message.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

struct MessageSubtitle {
  static let video = "Attachment: Video"
  static let image = "Attachment: Image"
  static let audio = "Audio message"
  static let empty = "No messages here yet."
}

class Message: NSObject, NSCoding {
  
    var messageUID: String?
    var isInformationMessage: Bool?

    var fromId: String?
    var text: String?
    var toId: String?
    var timestamp: NSNumber?
    var convertedTimestamp: String?
  
    var status: String?
    var seen: Bool?
  
    var imageUrl: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
  
    var localImage: UIImage?
  
    var localVideoUrl: String?
  
    var voiceData: Data?
    var voiceDuration: String?
    var voiceStartTime: Int?
    var voiceEncodedString: String?

    var videoUrl: String?
  
    var estimatedFrameForText:CGRect?
    var imageCellHeight: NSNumber?
  
    var isCrooked:Bool? // local only
  
    var senderName: String? //local only, group messages only
      
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
  
    init(dictionary: [String: AnyObject]) {
        super.init()
      
        messageUID = dictionary["messageUID"] as? String
        isInformationMessage = dictionary["isInformationMessage"] as? Bool
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        toId = dictionary["toId"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
      
        convertedTimestamp = dictionary["convertedTimestamp"] as? String
      
        status = dictionary["status"] as? String
        seen = dictionary["seen"] as? Bool
        
        imageUrl = dictionary["imageUrl"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
      
        localImage = dictionary["localImage"] as? UIImage
        localVideoUrl = dictionary["localVideoUrl"] as? String
      
        voiceEncodedString = dictionary["voiceEncodedString"] as? String
        voiceData = dictionary["voiceData"] as? Data //unused
        voiceDuration = dictionary["voiceDuration"] as? String
        voiceStartTime = dictionary["voiceStartTime"] as? Int
      
        estimatedFrameForText = dictionary["estimatedFrameForText"] as? CGRect
        imageCellHeight = dictionary["imageCellHeight"] as? NSNumber
      
        senderName = dictionary["senderName"] as? String
      
        isCrooked = dictionary["isCrooked"] as? Bool
    }
  
  
    func encode(with aCoder: NSCoder) {

      aCoder.encode(messageUID, forKey: "messageUID")
      aCoder.encode(isInformationMessage, forKey: "isInformationMessage")
      aCoder.encode(fromId, forKey: "fromId")
      aCoder.encode(text, forKey: "text")
      aCoder.encode(toId, forKey: "toId")
      aCoder.encode(timestamp, forKey: "timestamp")

      aCoder.encode(convertedTimestamp, forKey: "convertedTimestamp")

      aCoder.encode(status, forKey: "status")
      aCoder.encode(seen, forKey: "seen")

      aCoder.encode(imageUrl, forKey: "imageUrl")
      aCoder.encode(imageHeight, forKey: "imageHeight")
      aCoder.encode(imageWidth, forKey: "imageWidth")

      aCoder.encode(videoUrl, forKey: "videoUrl")

      aCoder.encode(localImage, forKey: "localImage")
      aCoder.encode(localVideoUrl, forKey: "localVideoUrl")

      aCoder.encode(voiceEncodedString, forKey: "voiceEncodedString")
      aCoder.encode(voiceData, forKey: "voiceData")
      aCoder.encode(voiceDuration, forKey: "voiceDuration")
      aCoder.encode(voiceStartTime, forKey: "voiceStartTime")

      aCoder.encode(estimatedFrameForText, forKey: "estimatedFrameForText")
      aCoder.encode(imageCellHeight, forKey: "imageCellHeight")

      aCoder.encode(senderName, forKey: "senderName")

      aCoder.encode(isCrooked, forKey: "isCrooked")
    }
  
    required init?(coder aDecoder: NSCoder) {

      messageUID = aDecoder.decodeObject(forKey: "messageUID") as? String
      isInformationMessage = aDecoder.decodeObject(forKey: "isInformationMessage") as? Bool
      fromId = aDecoder.decodeObject(forKey: "fromId") as? String
      text = aDecoder.decodeObject(forKey: "text") as? String
      toId = aDecoder.decodeObject(forKey: "toId") as? String
      timestamp = aDecoder.decodeObject(forKey: "timestamp") as? NSNumber

      convertedTimestamp = aDecoder.decodeObject(forKey: "convertedTimestamp") as? String

      status = aDecoder.decodeObject(forKey: "status") as? String
      seen = aDecoder.decodeObject(forKey: "seen") as? Bool

      imageUrl = aDecoder.decodeObject(forKey: "imageUrl") as? String
      imageHeight = aDecoder.decodeObject(forKey: "imageHeight") as? NSNumber
      imageWidth = aDecoder.decodeObject(forKey: "imageWidth") as? NSNumber

      videoUrl = aDecoder.decodeObject(forKey: "videoUrl") as? String

      localImage = aDecoder.decodeObject(forKey: "localImage") as? UIImage
      localVideoUrl = aDecoder.decodeObject(forKey: "localVideoUrl") as? String

      voiceEncodedString = aDecoder.decodeObject(forKey: "voiceEncodedString") as? String
      voiceData = aDecoder.decodeObject(forKey: "voiceData") as? Data
      voiceDuration = aDecoder.decodeObject(forKey: "voiceDuration") as? String
      voiceStartTime = aDecoder.decodeObject(forKey: "voiceStartTime") as? Int

      estimatedFrameForText = aDecoder.decodeObject(forKey: "estimatedFrameForText") as? CGRect
      imageCellHeight = aDecoder.decodeObject(forKey: "imageCellHeight") as? NSNumber

      senderName = aDecoder.decodeObject(forKey: "senderName") as? String

      isCrooked = aDecoder.decodeObject(forKey: "isCrooked") as? Bool
    }
}
