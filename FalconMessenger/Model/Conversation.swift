//
//  Conversation.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import RealmSwift

final class Conversation: Object {
  
  @objc dynamic var chatID: String?
  @objc dynamic var chatName: String?
  @objc dynamic var chatPhotoURL: String?
  @objc dynamic var chatThumbnailPhotoURL: String?
  @objc dynamic var lastMessageID: String?
	@objc dynamic var admin: String?

	@objc dynamic var lastMessage: Message? {
		return RealmKeychain.defaultRealm.object(ofType: Message.self, forPrimaryKey: lastMessageID ?? "")
	}

	let lastMessageTimestamp = RealmOptional<Int64>()
  let chatParticipantsIDs = List<String>()
	let badge = RealmOptional<Int>()
	let isGroupChat = RealmOptional<Bool>()
  let pinned = RealmOptional<Bool>()
  let muted = RealmOptional<Bool>()
	let isTyping = RealmOptional<Bool>()
	let permitted = RealmOptional<Bool>()
	let shouldUpdateRealmRemotelyBeforeDisplaying = RealmOptional<Bool>()

	var lastMessageRuntime: Message?
	let messages = LinkingObjects(fromType: Message.self, property: "conversation")

	func getTyping() -> Bool {
		return RealmKeychain.defaultRealm.object(ofType: Conversation.self, forPrimaryKey: chatID ?? "")?.isTyping.value ?? false
	}

	override class func ignoredProperties() -> [String] {
		return ["lastMessage"]
	}

	override static func primaryKey() -> String? {
		return "chatID"
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

  convenience init(dictionary: [String: AnyObject]?) {
    self.init()

    chatID = dictionary?["chatID"] as? String
    chatName = dictionary?["chatName"] as? String
    chatPhotoURL = dictionary?["chatOriginalPhotoURL"] as? String
    chatThumbnailPhotoURL = dictionary?["chatThumbnailPhotoURL"] as? String
    lastMessageID = dictionary?["lastMessageID"] as? String
    isGroupChat.value = dictionary?["isGroupChat"] as? Bool
    chatParticipantsIDs.assign(dictionary?["chatParticipantsIDs"] as? [String])
    admin = dictionary?["admin"] as? String
    badge.value = dictionary?["badge"] as? Int
    pinned.value = dictionary?["pinned"] as? Bool
    muted.value = dictionary?["muted"] as? Bool
    permitted.value = dictionary?["permitted"] as? Bool
		shouldUpdateRealmRemotelyBeforeDisplaying.value = RealmKeychain.defaultRealm.object(ofType: Conversation.self,
																																												forPrimaryKey: dictionary?["chatID"] as? String ?? "")?.shouldUpdateRealmRemotelyBeforeDisplaying.value
  }
}
