//
//  Conversation.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class Conversation: NSObject, NSCoding {

  var chatID: String?
  var chatName: String?
  var chatPhotoURL: String?
  var chatThumbnailPhotoURL: String?
  var lastMessageID: String?
  var lastMessage: Message?
  var isGroupChat: Bool?
  var chatParticipantsIDs: [String]?
  var admin: String?
  var badge: Int?
  var pinned: Bool?
  var muted: Bool?
  var isTyping: Bool? // local only
  
  func messageText() -> String {
    
    let isImageMessage = (lastMessage?.imageUrl != nil || lastMessage?.localImage != nil) && lastMessage?.videoUrl == nil
    let isVideoMessage = (lastMessage?.imageUrl != nil || lastMessage?.localImage != nil) && lastMessage?.videoUrl != nil
    let isVoiceMessage = lastMessage?.voiceEncodedString != nil
    let isTextMessage = lastMessage?.text != nil
    
    guard !isImageMessage else { return  MessageSubtitle.image }
    guard !isVideoMessage else { return MessageSubtitle.video }
    guard !isVoiceMessage else { return MessageSubtitle.audio }
    guard !isTextMessage else { return lastMessage?.text ?? "" }
    
    return MessageSubtitle.empty
  }
  
  init(dictionary: [String: AnyObject]?) {
    super.init()
    
    chatID = dictionary?["chatID"] as? String
    chatName = dictionary?["chatName"] as? String
    chatPhotoURL = dictionary?["chatOriginalPhotoURL"] as? String
    chatThumbnailPhotoURL = dictionary?["chatThumbnailPhotoURL"] as? String
    lastMessageID = dictionary?["lastMessageID"] as? String
    lastMessage = dictionary?["lastMessage"] as? Message
    isGroupChat = dictionary?["isGroupChat"] as? Bool
    chatParticipantsIDs = dictionary?["chatParticipantsIDs"] as? [String]
    admin = dictionary?["admin"] as? String
    badge = dictionary?["badge"] as? Int
    pinned = dictionary?["pinned"] as? Bool
    muted = dictionary?["muted"] as? Bool
  }
  
  func encode(with aCoder: NSCoder) {
    aCoder.encode(chatID, forKey: "chatID")
    aCoder.encode(chatName, forKey: "chatName")
    aCoder.encode(chatPhotoURL, forKey: "chatOriginalPhotoURL")
    aCoder.encode(chatThumbnailPhotoURL, forKey: "chatThumbnailPhotoURL")
    aCoder.encode(lastMessageID, forKey: "lastMessageID")
    aCoder.encode(lastMessage, forKey: "lastMessage")
    aCoder.encode(isGroupChat, forKey: "isGroupChat")
    aCoder.encode(chatParticipantsIDs, forKey: "chatParticipantsIDs")
    aCoder.encode(admin, forKey: "admin")
    aCoder.encode(badge, forKey: "badge")
    aCoder.encode(pinned, forKey: "pinned")
    aCoder.encode(muted, forKey: "muted")
  }

  required init?(coder aDecoder: NSCoder) {
    chatID = aDecoder.decodeObject(forKey: "chatID") as? String
    chatName = aDecoder.decodeObject(forKey: "chatName") as? String
    chatPhotoURL = aDecoder.decodeObject(forKey: "chatOriginalPhotoURL") as? String
    chatThumbnailPhotoURL = aDecoder.decodeObject(forKey: "chatThumbnailPhotoURL") as? String
    lastMessageID = aDecoder.decodeObject(forKey: "lastMessageID") as? String
    lastMessage = aDecoder.decodeObject(forKey: "lastMessage") as? Message
    isGroupChat = aDecoder.decodeObject(forKey: "isGroupChat") as? Bool
    chatParticipantsIDs = aDecoder.decodeObject(forKey: "chatParticipantsIDs") as? [String]
    admin = aDecoder.decodeObject(forKey: "admin") as? String
    badge = aDecoder.decodeObject(forKey: "badge") as? Int
    pinned = aDecoder.decodeObject(forKey: "pinned") as? Bool
    muted = aDecoder.decodeObject(forKey: "muted") as? Bool
  }
}
