//
//  Conversation.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

class Conversation: Object {
  
  @objc dynamic var chatID: String?
  @objc dynamic var chatName: String?
  @objc dynamic var chatPhotoURL: String?
  @objc dynamic var chatThumbnailPhotoURL: String?
  @objc dynamic var lastMessageID: String?
  @objc dynamic var lastMessage: Message?

	let isGroupChat = RealmOptional<Bool>()

  let chatParticipantsIDs = List<String>()//[String]?

  @objc dynamic var admin: String?

	let badge = RealmOptional<Int>()

  let pinned = RealmOptional<Bool>()
  let muted = RealmOptional<Bool>()
  let isTyping = RealmOptional<Bool>() // local only
  let permitted = RealmOptional<Bool>()
  
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
  
  convenience init(dictionary: [String: AnyObject]?) {
    self.init()

    chatID = dictionary?["chatID"] as? String
    chatName = dictionary?["chatName"] as? String
    chatPhotoURL = dictionary?["chatOriginalPhotoURL"] as? String
    chatThumbnailPhotoURL = dictionary?["chatThumbnailPhotoURL"] as? String
    lastMessageID = dictionary?["lastMessageID"] as? String
    lastMessage = dictionary?["lastMessage"] as? Message
    isGroupChat.value = dictionary?["isGroupChat"] as? Bool

    chatParticipantsIDs.assign(dictionary?["chatParticipantsIDs"] as? [String])
		
    admin = dictionary?["admin"] as? String
    badge.value = dictionary?["badge"] as? Int
    pinned.value = dictionary?["pinned"] as? Bool
    muted.value = dictionary?["muted"] as? Bool
    permitted.value = dictionary?["permitted"] as? Bool
  }
}
