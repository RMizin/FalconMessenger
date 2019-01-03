//
//  ChatsRealmManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 12/29/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

class ChatsRealmManager {

	let realm = try! Realm()

	func update(conversation: Conversation) {
		realm.beginWrite()
		realm.create(Conversation.self, value: conversation, update: true)
		try! realm.commitWrite()
	}

	func update(conversations: [Conversation], tokens: [NotificationToken]) {
			autoreleasepool {
				let realm = try! Realm()
			///	guard !realm.isInWriteTransaction else {  try! realm.commitWrite(); return }
				realm.beginWrite()
				for conversation in conversations {
					conversation.isTyping.value = realm.objects(Conversation.self).filter("chatID = %@", conversation.chatID ?? "").first?.isTyping.value
					realm.create(Conversation.self, value: conversation, update: true)
					if let message = conversation.lastMessageRuntime {
						realm.create(Message.self, value: message, update: true)
					}

				}
				try! realm.commitWrite(withoutNotifying: tokens)
			}
	}

	func delete(conversation: Conversation) {
		realm.beginWrite()
		let result = realm.objects(Conversation.self).filter("chatID = '\(conversation.chatID!)'")
		let messagesResult = realm.objects(Message.self).filter("conversation.chatID = '\(conversation.chatID ?? "")'")

		realm.delete(messagesResult)
		realm.delete(result)

		try! realm.commitWrite()
	}

	func deleteAll() {
		realm.beginWrite()
		realm.deleteAll()
		try! realm.commitWrite()
	}
}
