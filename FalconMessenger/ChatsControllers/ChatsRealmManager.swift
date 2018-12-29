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

	func updateLastMessage(with message: Message) {
	//	let realm = try! Realm()

		realm.beginWrite()
		realm.create(Message.self, value: message, update: true)
		try! realm.commitWrite()
	}


	func update(conversation: Conversation) {
		realm.beginWrite()
		realm.create(Conversation.self, value: conversation, update: true)
		try! realm.commitWrite()
	}

	func update(conversations: [Conversation]) {
		DispatchQueue.global().async {
			autoreleasepool {
				let realm = try! Realm()

				realm.beginWrite()
				for conversation in conversations {
					realm.create(Conversation.self, value: conversation, update: true)
				}
				try! realm.commitWrite()
			}
		}
	}

	func delete(conversation: Conversation) {
		realm.beginWrite()
		let result = realm.objects(Conversation.self).filter("chatID = '\(conversation.chatID!)'")
		let messagesResult = realm.objects(Message.self).filter("conversation.chatID = '\(conversation.chatID ?? "")'")

		print("xxx", messagesResult.count)

		realm.delete(messagesResult)
		realm.delete(result)

		try! realm.commitWrite()

		print("xxx", messagesResult.count)
	}
}
