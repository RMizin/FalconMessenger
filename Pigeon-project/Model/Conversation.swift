//
//  Conversation.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class Conversation: NSObject {

  var chatID: String?
  var chatName: String?
  var chatPhotoURL: String?
  var chatThumbnailPhotoURL: String?
  var lastMessageID: String?
  var lastMessage: Message?
  var isGroupChat: Bool?
  var chatParticipantsIDs:[String]?
  var admin: String?
  var badge: Int?
  var pinned: Bool?
  var muted: Bool?
  
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
}
