//
//  Message.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

struct MessageSubtitle {
  static let video = "Attachment: Video"
  static let image = "Attachment: Image"
  static let audio = "Audio message"
  static let empty = "No messages here yet."
}

enum MessageType {
  case textMessage
  case photoMessage
  case videoMessage
  case voiceMessage
  case sendingMessage
}

class Message: NSObject {
  
    var messageUID: String?
    var isInformationMessage: Bool?

    var fromId: String?
    var text: String?
    var toId: String?
    var timestamp: NSNumber?
    var convertedTimestamp: String? // local only
    var shortConvertedTimestamp: String? //local only
  
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
  
    var estimatedFrameForText: CGRect?
  
    var landscapeEstimatedFrameForText: CGRect?
  
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
        shortConvertedTimestamp = dictionary["shortConvertedTimestamp"] as? String
      
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
        landscapeEstimatedFrameForText = dictionary["landscapeEstimatedFrameForText"] as? CGRect
        imageCellHeight = dictionary["imageCellHeight"] as? NSNumber
      
        senderName = dictionary["senderName"] as? String
      
        isCrooked = dictionary["isCrooked"] as? Bool
    }
  
  
  static func groupedMessages(_ messages: [Message]) -> [[Message]] {
    let grouped = Dictionary.init(grouping: messages) { (message) -> String in
      return message.shortConvertedTimestamp ?? ""
    }
    
    let keys = grouped.keys.sorted { (time1, time2) -> Bool in
      return Date.dateFromCustomString(customString: time1) <  Date.dateFromCustomString(customString: time2)
    }
    
    var groupedMessages = [[Message]]()
    keys.forEach({
      groupedMessages.append(grouped[$0]!)
    })
    
    return groupedMessages
  }
  
  static func get(indexPathOf message: Message, in groupedArray: [[Message]]) -> IndexPath? {
    guard let section = groupedArray.index(where: { (messages) -> Bool in
      for message1 in messages where message1 == message {
        return true
      }; return false
    }) else { return nil }
    
    guard let row = groupedArray[section].index(where: { (message1) -> Bool in
      return message1.messageUID == message.messageUID
    }) else { return IndexPath(row: -1, section: section) }
    
    return IndexPath(row: row, section: section)
  }
  
  static func get(indexPathOf messageUID: String? = nil , localPhoto: UIImage? = nil, in groupedArray: [[Message]]) -> IndexPath? {
    
    if messageUID != nil {
      
      guard let section = groupedArray.index(where: { (messages) -> Bool in
        for message1 in messages where message1.messageUID == messageUID {
          return true
        }; return false
      }) else { return nil }
      
      guard let row = groupedArray[section].index(where: { (message1) -> Bool in
        return message1.messageUID == messageUID
      }) else { return IndexPath(row: -1, section: section) }
      
       return IndexPath(row: row, section: section)
      
    } else if localPhoto != nil {
      
      guard let section = groupedArray.index(where: { (messages) -> Bool in
        for message1 in messages where message1.localImage == localPhoto {
          return true
        }; return false
      }) else { return nil }
      
      guard let row = groupedArray[section].index(where: { (message1) -> Bool in
        return message1.localImage == localPhoto
      }) else { return IndexPath(row: -1, section: section) }
      
       return IndexPath(row: row, section: section)
    }
     return nil
  }
}

extension Date {
  static func dateFromCustomString(customString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM/yyyy"
    return dateFormatter.date(from: customString) ?? Date()
  }
}
