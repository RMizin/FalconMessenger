//
//  ChatsRealmManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 12/29/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

enum TableUpdateType {
	case reloadData
	case reloadRow
	case updateDataSource
	case move
	case delete
	case clean
}
//
//class ChatsTableViewRealmObserver {
//
//	weak var managedController: ChatsTableViewController?
//	let realmManager = ChatsRealmManager()
//
//	func update(type: TableUpdateType, conversation: Conversation? = nil, conversations: [Conversation]? = nil) {
//
//		switch type {
//		case .reloadData:
//			guard let conversations = conversations else { return }
//			reloadData(conversations: conversations)
//			break
//		case .reloadRow:
//			guard let conversation = conversation else { return }
//			reloadRow(conversation: conversation, reloadNeeded: true)
//			break
//		case .updateDataSource:
//			guard let conversation = conversation else { return }
//			reloadRow(conversation: conversation, reloadNeeded: false)
//			break
//		case .move: break
//		case .delete: break
//		case .clean: clean(); break
//		}
//	}
//
//	fileprivate func clean() {
//		managedController?.realmUnpinnedConversations.removeAll()
//		managedController?.realmPinnedConversations.removeAll()
//		managedController?.realmAllConversations.removeAll()
//		realmManager.deleteAll()
//		managedController?.tableView.reloadData()
//	}
//	fileprivate func reloadData(conversations: [Conversation]) {
//		guard managedController != nil else { return }
//
//		let (pinned, unpinned) = conversations.stablePartition { (element) -> Bool in
//			let isPinned = element.pinned.value ?? false
//			return isPinned == true
//		}
//
//		managedController?.realmUnpinnedConversations.sort { (conversation1, conversation2) -> Bool in
//			guard let lastMessage1 = conversation1.lastMessage, let lastMessage2 = conversation2.lastMessage else { return true }
//			return lastMessage1.timestamp.value ?? 0 > lastMessage2.timestamp.value ?? 0
//		}
//
//		managedController?.realmPinnedConversations.sort { (conversation1, conversation2) -> Bool in
//			guard let lastMessage1 = conversation1.lastMessage, let lastMessage2 = conversation2.lastMessage else { return true }
//			return lastMessage1.timestamp.value ?? 0 > lastMessage2.timestamp.value ?? 0
//		}
//
//		managedController?.realmPinnedConversations = pinned
//		managedController?.realmUnpinnedConversations = unpinned
//
//
//
//		realmManager.update(conversations: conversations)
//
//		managedController?.tableView.reloadData()
//	}
//
//	fileprivate func reloadRow(conversation: Conversation, reloadNeeded: Bool) {
//		let chatID = conversation.chatID ?? ""
//
//		if let index = managedController?.realmUnpinnedConversations.index(where: {$0.chatID == chatID}) {
//			managedController?.realmUnpinnedConversations[index] = conversation
//			realmManager.update(conversation: conversation)
//			let indexPath = IndexPath(row: index, section: 0)
//			updateCell(at: indexPath)
//			if reloadNeeded { updateCell(at: indexPath) }
//		}
//		
//		if let index = managedController?.realmPinnedConversations.index(where: {$0.chatID == chatID}) {
//			managedController?.realmPinnedConversations[index] = conversation
//			realmManager.update(conversation: conversation)
//			let indexPath = IndexPath(row: index, section: 1)
//			updateCell(at: indexPath)
//			if reloadNeeded { updateCell(at: indexPath) }
//		}
//	}
//
//
//	func move(_ conversation: Conversation, at indexPath: IndexPath, from sourceArray: [Conversation], to destinationArray: [Conversation]) {
//	//	func unpinConversation(at indexPath: IndexPath) {
//		//	let conversation = filteredPinnedConversations[indexPath.row]
//		//	guard let conversationID = conversation.chatID else { return }
//
//			let pinnedElement = conversation//filteredPinnedConversations[indexPath.row]
//
//			let filteredIndexToInsert = destinationArray.insertionIndex(of: pinnedElement, using: { (conversation1, conversation2) -> Bool in
//				guard let lastMessage1 = conversation1.lastMessage, let lastMessage2 = conversation2.lastMessage else { return true }
//				return lastMessage1.timestamp.value ?? 0 > lastMessage2.timestamp.value ?? 0
//			})
//
//		if destinationArray == managedController?.realmPinnedConversations {
//			managedController?.realmPinnedConversations.insert(pinnedElement, at: filteredIndexToInsert) } else {
//			managedController?.realmUnpinnedConversations.insert(pinnedElement, at: filteredIndexToInsert) }
//
//		if sourceArray == managedController?.realmPinnedConversations {
//			managedController?.realmPinnedConversations.remove(at: indexPath.row) } else {
//			managedController?.realmUnpinnedConversations.remove(at: indexPath.row) }
//
//
//			let destinationIndexPath = IndexPath(row: filteredIndexToInsert, section: 1)
//
//			realmManager.update(conversation: conversation)
//			managedController?.tableView.beginUpdates()
//			if #available(iOS 11.0, *) {
//			} else {
//				managedController?.tableView.setEditing(false, animated: true)
//			}
//			managedController?.tableView.moveRow(at: indexPath, to: destinationIndexPath)
//
//			managedController?.tableView.endUpdates()
//
//
//		//}
//	}
//
//	func delete( at indexPath: IndexPath) {
//		guard let conversation = indexPath.section == 0 ?
//		managedController?.realmPinnedConversations[indexPath.row] :
//		managedController?.realmUnpinnedConversations[indexPath.row] else { return }
//		realmManager.delete(conversation: conversation)
//		if indexPath.section == 0  {
//			managedController?.realmPinnedConversations.remove(at: indexPath.row)
//		} else {
//			managedController?.realmUnpinnedConversations.remove(at: indexPath.row)
//		}
//
//		managedController?.tableView.beginUpdates()
//		managedController?.tableView.deleteRows(at: [indexPath], with: .left)
//		managedController?.tableView.endUpdates()
//	}
//
//
//
//	fileprivate func updateCell(at indexPath: IndexPath) {
//		managedController?.tableView.beginUpdates()
//		managedController?.tableView.reloadRows(at: [indexPath], with: .none)
//		managedController?.tableView.endUpdates()
//	}
//}
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
		DispatchQueue.global(qos: .userInitiated).async {
			autoreleasepool {
				let realm = try! Realm()

				realm.beginWrite()
				for conversation in conversations {
				//	var dictionary = Conversation.convertIntoDict(conversation: conversation)
					//dictionary.removeValue(forKey: "isTyping")
					//print(conversation.isTyping.value)
				//	let newConversation = Conversation(dictionary: dictionary)

				///	conversation
					//let dictionary = [conversation.]
					realm.create(Conversation.self, value: conversation, update: true)
				}
				try! realm.commitWrite()
			}
		}
	}

	func update(conversations: [Conversation], tokens: [NotificationToken]) {
			autoreleasepool {
				let realm = try! Realm()

				realm.beginWrite()
				for conversation in conversations {
					conversation.isTyping.value = realm.objects(Conversation.self).filter("chatID = %@", conversation.chatID ?? "").first?.isTyping.value
					realm.create(Conversation.self, value: conversation, update: true)
				}
				try! realm.commitWrite(withoutNotifying: tokens)
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

	func deleteAll() {
		realm.beginWrite()
		realm.deleteAll()
		try! realm.commitWrite()
	}
}
