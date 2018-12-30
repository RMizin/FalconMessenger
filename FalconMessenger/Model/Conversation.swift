//
//  Conversation.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

//class RelationalConversation: Object {
//	  @objc dynamic var chatID: String?
//		let messages = LinkingObjects(fromType: Message.self, property: "conversation")
//	//	var lastMessage = messages
//	var lastMessage: Message? {
//
//	//	messages.sor
//
//		//var mostRecent = messages.reduce(messages[0], { $0.timestamp > $1.timestamp ? $0 : $1 } )
//
//		return messages.last
//
//	}
//}

class Conversation: Object {
  
  @objc dynamic var chatID: String?
  @objc dynamic var chatName: String?
  @objc dynamic var chatPhotoURL: String?
  @objc dynamic var chatThumbnailPhotoURL: String?
  @objc dynamic var lastMessageID: String?
//	@objc dynamic var lastMessage: Message?

	@objc dynamic var lastMessage: Message? {
		let realm = try! Realm()
		let results = realm.objects(Message.self).filter("conversation.chatID = '\(chatID ?? "")'")
		let currentConvers = results.first

		let lastMessage = currentConvers?.conversation?.messages.last
	///	let timestamp = lastMessage?.timestamp?.doubleValue ?? 0.0
		//timestamp?.doubleValue ?? 0.0
//		realm.beginWrite()
//		lastMessageTimestamp = timestamp// Date(timeIntervalSince1970: TimeInterval(exactly: timestamp ?? 0) ?? 0)
//		try! realm.commitWrite()
	//	lastMessage?.timestamp

//		realm.beginWrite()
//		lastMessageTimestamp.value = lastMessage?.timestamp.value
//		try! realm.commitWrite()

		return lastMessage
	}

	let lastMessageTimestamp = RealmOptional<Int64>()
//	{
////		let realm = try! Realm()
////		let results = realm.objects(Message.self).filter("conversation.chatID = '\(chatID ?? "")'")
////		let currentConvers = results.first
//	//	Date.t
//	//	lastMessage.t
//		return lastMessage?.timestamp.value
//	}

	@objc dynamic var admin: String?

  let chatParticipantsIDs = List<String>()

	let badge = RealmOptional<Int>()

	let isGroupChat = RealmOptional<Bool>()
  let pinned = RealmOptional<Bool>()
  let muted = RealmOptional<Bool>()
	let isTyping = RealmOptional<Bool>()
  let permitted = RealmOptional<Bool>()

//	let messages = List<Message>()
	let messages = LinkingObjects(fromType: Message.self, property: "conversation")

	override class func ignoredProperties() -> [String] {
		return ["lastMessage"]
	}

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

	override static func primaryKey() -> String? {
		return "chatID"
	}
  
  convenience init(dictionary: [String: AnyObject]?) {
    self.init()

    chatID = dictionary?["chatID"] as? String
    chatName = dictionary?["chatName"] as? String
    chatPhotoURL = dictionary?["chatOriginalPhotoURL"] as? String
    chatThumbnailPhotoURL = dictionary?["chatThumbnailPhotoURL"] as? String
    lastMessageID = dictionary?["lastMessageID"] as? String
  // lastMessage = dictionary?["lastMessage"] as? Message
    isGroupChat.value = dictionary?["isGroupChat"] as? Bool

    chatParticipantsIDs.assign(dictionary?["chatParticipantsIDs"] as? [String])
		
    admin = dictionary?["admin"] as? String
    badge.value = dictionary?["badge"] as? Int
    pinned.value = dictionary?["pinned"] as? Bool
    muted.value = dictionary?["muted"] as? Bool
    permitted.value = dictionary?["permitted"] as? Bool
  }

	static func convertIntoDict(conversation: Conversation) -> [String:AnyObject] {
		var dictionary =  [String:AnyObject]()


		dictionary["chatID"] = conversation.chatID as AnyObject
		dictionary["chatName"] = conversation.chatName as AnyObject
		dictionary["chatOriginalPhotoURL"] = conversation.chatPhotoURL as AnyObject
		dictionary["chatThumbnailPhotoURL"] = conversation.chatThumbnailPhotoURL as AnyObject
		dictionary["lastMessageID"] = conversation.lastMessageID as AnyObject
		dictionary["isGroupChat"] = conversation.isGroupChat as AnyObject
	//		dictionary?["chatID"]

		dictionary["chatParticipantsIDs"] = conversation.chatParticipantsIDs as AnyObject
		dictionary["admin"] = conversation.admin as AnyObject
		dictionary["badge"] = conversation.badge as AnyObject
		dictionary["pinned"] = conversation.pinned as AnyObject
		dictionary["muted"] = conversation.muted as AnyObject
		dictionary["permitted"] = conversation.permitted as AnyObject

		return dictionary
	}
}
