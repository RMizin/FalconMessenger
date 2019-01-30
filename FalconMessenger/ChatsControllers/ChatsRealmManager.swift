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
		try! realm.safeWrite {
			realm.create(Conversation.self, value: conversation, update: true)
		}
	}

	func update(conversations: [Conversation], tokens: [NotificationToken]) {
			autoreleasepool {
				let realm = try! Realm()
				guard !realm.isInWriteTransaction else {
					print("Update Array operation, realm is in write transaction in \(String(describing: ChatsRealmManager.self))")
					return
				}

				realm.beginWrite()
				for conversation in conversations {
					conversation.isTyping.value = realm.objects(Conversation.self).filter("chatID = %@", conversation.chatID ?? "").first?.isTyping.value
					realm.create(Conversation.self, value: conversation, update: true)
					if let message = conversation.lastMessageRuntime {
						message.senderName = realm.object(ofType: Message.self, forPrimaryKey: message.messageUID ?? "")?.senderName
						message.isCrooked.value = realm.object(ofType: Message.self, forPrimaryKey: message.messageUID ?? "")?.isCrooked.value
						if message.thumbnailImage == nil {
							message.thumbnailImage = realm.object(ofType: RealmUIImage.self, forPrimaryKey: (message.messageUID ?? "") + "thumbnail")
						}
						if message.localImage == nil {
							message.localImage = realm.object(ofType: RealmUIImage.self, forPrimaryKey: message.messageUID ?? "")
						}
						realm.create(Message.self, value: message, update: true)
					}
				}
				do {
					try realm.commitWrite(withoutNotifying: tokens)
				} catch {}
			}
	}

	func delete(conversation: Conversation) {
		try! realm.safeWrite {
			let result = realm.objects(Conversation.self).filter("chatID = '\(conversation.chatID!)'")
			let messagesResult = realm.objects(Message.self).filter("conversation.chatID = '\(conversation.chatID ?? "")'")
			realm.delete(messagesResult)
			realm.delete(result)
		}
	}

	func deleteAll() {
		do {
			try realm.safeWrite {
				realm.deleteAll()
			}
		} catch {}
	}
}
