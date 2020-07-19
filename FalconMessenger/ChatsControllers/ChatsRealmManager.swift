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

	func update(conversation: Conversation) {
		autoreleasepool {
			try! RealmKeychain.defaultRealm.safeWrite {
				RealmKeychain.defaultRealm.create(Conversation.self, value: conversation, update: .modified)
			}
		}
	}

	func update(conversations: [Conversation], tokens: [NotificationToken]) {
			autoreleasepool {
				guard !RealmKeychain.defaultRealm.isInWriteTransaction else {
					print("Update Array operation, realm is in write transaction in \(String(describing: ChatsRealmManager.self))")
					return
				}

				RealmKeychain.defaultRealm.beginWrite()
				for conversation in conversations {
					conversation.isTyping.value = RealmKeychain.defaultRealm.object(ofType: Conversation.self, forPrimaryKey: conversation.chatID ?? "")?.isTyping.value
					RealmKeychain.defaultRealm.create(Conversation.self, value: conversation, update: .modified)
					if let message = conversation.lastMessageRuntime {
						message.senderName = RealmKeychain.defaultRealm.object(ofType: Message.self, forPrimaryKey: message.messageUID ?? "")?.senderName
						message.isCrooked.value = RealmKeychain.defaultRealm.object(ofType: Message.self, forPrimaryKey: message.messageUID ?? "")?.isCrooked.value
						if message.thumbnailImage == nil {
							message.thumbnailImage = RealmKeychain.defaultRealm.object(ofType: RealmImage.self, forPrimaryKey: (message.messageUID ?? "") + "thumbnail")
						}
						if message.localImage == nil {
							message.localImage = RealmKeychain.defaultRealm.object(ofType: RealmImage.self, forPrimaryKey: message.messageUID ?? "")
						}
						RealmKeychain.defaultRealm.create(Message.self, value: message, update: .modified)
					}
				}
				do {
					try RealmKeychain.defaultRealm.commitWrite(withoutNotifying: tokens)
				} catch {}
			}
	}

	func delete(conversation: Conversation) {
		autoreleasepool {
			try! RealmKeychain.defaultRealm.safeWrite {
				let result = RealmKeychain.defaultRealm.objects(Conversation.self).filter("chatID = '\(conversation.chatID!)'")
				let messagesResult = RealmKeychain.defaultRealm.objects(Message.self).filter("conversation.chatID = '\(conversation.chatID ?? "")'")
				RealmKeychain.defaultRealm.delete(messagesResult)
				RealmKeychain.defaultRealm.delete(result)
			}
		}
	}

	func deleteAll() {
		autoreleasepool {
			do {
				try RealmKeychain.defaultRealm.safeWrite {
					RealmKeychain.defaultRealm.deleteAll()
				}
			} catch {}
		}
	}
}
