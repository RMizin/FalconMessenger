//
//  ChatLogController+CollectionDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

extension ChatLogViewController: CollectionDelegate {
  
  func collectionView(shouldRemoveMessage id: String) {

//		let realm = try! Realm()
//		guard let messageToDelete = conversation?.messages.filter("messageUID == %@", id).first, !messageToDelete.isInvalidated else {
//			print("removing is invalidated"); return }
//		print("in oberve removing")
//	//	guard !realm.isInWriteTransaction else { print("realm is in write transaction in \(String(describing: ChatLogViewController.self))"); return }
//
//		try! realm.safeWrite {
//			realm.delete(messageToDelete)
//		}

	//	realm.beginWrite()



	//	try! realm.commitWrite()
		
//		try! realm.write {
//			realm.delete(messageToDelete)
//		//	messagesFetcher?.configureTails(for: conversation!.messages, isGroupChat: nil)
//		}


//    guard let index = self.messages.index(where: { (message) -> Bool in
//      return message.messageUID == id
//    }) else { return }
  //  performBatchUpdates(for: index, id: id)
  }
  
//  func performBatchUpdates(for index: Int, id: String) {
//    guard let messagesFetcher = messagesFetcher else { return }
//    let removedMessage = messages[index]
//		let isRemovedMessageLast = index == messages.count - 1
//
//		//MARK: REALM
//		let realm = try! Realm()
//		let message = conversation?.messages.filter("messageUID == %@", id).first ?? removedMessage
//
//		try! realm.write {
//			realm.delete(message)
//			messages.remove(at: index)
//		//	realm.delete(removedMessage)
//			messages = messagesFetcher.configureTails(for: messages, isGroupChat: nil)
//		}
//
//		if isRemovedMessageLast {
//			NotificationCenter.default.post(name: .messageSent, object: nil)
//		}
//
//
//    guard let indexPath = Message.get(indexPathOf: removedMessage, in: groupedMessages) else { return }
//
//    let currentSectionsCount = groupedMessages.count
//    groupedMessages = Message.groupedMessages(messages)
//
//    collectionView.performBatchUpdates({
//      if currentSectionsCount > self.groupedMessages.count {
//         collectionView.deleteSections([indexPath.section])
//      } else {
//        collectionView.deleteItems(at: [indexPath])
//      }
//    }) { (_) in
//      UIView.performWithoutAnimation {
//        self.collectionView.performBatchUpdates({
//          if currentSectionsCount > self.groupedMessages.count {
//            guard indexPath.section-1 >= 0 else { return }
//            self.collectionView.reloadSections([indexPath.section-1])
//          } else {
//            self.collectionView.reloadSections([indexPath.section])
//          }
//        }) { (_) in
//          guard self.messages.count == 0 else { return }
//          self.navigationController?.popViewController(animated: true)
//        }
//      }
//    }
//  }

  func collectionView(shouldUpdateOutgoingMessageStatusFrom reference: DatabaseReference, message: Message) {
    guard let messageID = message.messageUID else { return }
    let handle = DatabaseHandle()
    
    messageChangesHandles.insert((uid: messageID, handle: handle), at: 0)
    messageChangesHandles[0].handle = reference.observe(.childChanged, with: { (snapshot) in
      guard snapshot.exists(), snapshot.key == "status", let newMessageStatus = snapshot.value else { return }
			message.status = newMessageStatus as? String
      self.updateMessageStatusUI(sentMessage: message)
    })
    
    updateMessageStatus(messageRef: reference)
    updateMessageStatusUI(sentMessage: message)
  }



  func collectionView(shouldBeUpdatedWith message: Message, reference: DatabaseReference) {

	//	let realm = try! Realm()
		print(message.senderName)

		update1(message: message, reference: reference)
		print("HERE ")

//		print(message.senderName)
//
//		realm.beginWrite()
//		message.conversation = conversation
//		realm.create(Message.self, value: message, update: true)
//		try! realm.commitWrite()
//		try! realm.write {
//			message.conversation = conversation
//			realm.create(Message.self, value: message, update: true)
//		//	messagesFetcher?.configureTails(for: conversation!.messages, isGroupChat: nil)
//		}

		//self.updateMessageStatus(messageRef: reference)

		// check if typingIndicator is active
//		guard self.isScrollViewAtTheBottom() else { return }
//		self.collectionView.scrollToBottom(animated: true)
//    let insertionIndex = self.messages.insertionIndexOf(elem: message, isOrderedBefore: { (message1, message2) -> Bool in
//      return message1.messageUID! < message2.messageUID!
//    })
//
//    guard let _ = self.messages.index(where: { (existentMessage) -> Bool in
//      return existentMessage.messageUID == message.messageUID
//    }) else {
//      peformBatchUpdate(for: message, at: insertionIndex, reference: reference)
//      return
//    }
  }

	func update1(message: Message, reference: DatabaseReference) {
		
//		guard !realm.isInWriteTransaction else { print("realm in write transaction , cancelling CollectionDelegate");
//			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//				self.update1(message: message, reference: reference)
//			}
//
//			//potentially dangerous
//			return
//
//		}

		let lastObject = conversation?.messages.sorted(byKeyPath: "timestamp", ascending: true).last

		guard message.timestamp.value ?? 0 >= lastObject?.timestamp.value ?? 0 else {
			print("shitty insert bcz of query")
			return
		}

		realm.beginWrite()

	//	collectionView.performBatchUpdates({
			message.conversation = conversation
			realm.create(Message.self, value: message, update: true)

			guard let newSectionTitle = message.shortConvertedTimestamp else { realm.cancelWrite(); return }
			let lastSection = groupedMessages.last?.title ?? ""
			let isNewSection = newSectionTitle != lastSection

			if isNewSection {
				guard let messages = conversation?.messages
					.sorted(byKeyPath: "timestamp", ascending: true)
					.filter("shortConvertedTimestamp == %@", newSectionTitle) else { realm.cancelWrite(); return }

				let newSection = SectionedMessage(messages: messages, title: newSectionTitle)

//				let insertionIndex = groupedMessages.insertionIndexOf(elem: newSection, isOrderedBefore: { (message1, message2) -> Bool in
//					return Date.dateFromCustomString(customString: message1.title ?? "") < Date.dateFromCustomString(customString: message2.title ?? "")
//				})

				groupedMessages.append(newSection)
				let insertionIndex = groupedMessages.count - 1 >= 0 ?  groupedMessages.count - 1 : 0
			//	if insertionIndex == groupedMessages.count {
					//groupedMessages.insert(newSection, at: insertionIndex)

					self.collectionView.insertSections(IndexSet([insertionIndex]))
			//	}
			} else {

			let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
			let rowIndex = self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
			self.groupedMessages[sectionIndex].messages.count - 1 : 0

				//message.shortConvertedTimestamp
//
//				guard let sectionIndex = groupedMessages.index(where: { (sectionedMessage) -> Bool in
//					return sectionedMessage.title == message.shortConvertedTimestamp
//				}) else { print("no section index!!"); return }
//
//				let messageIndexInSection = groupedMessages[sectionIndex].messages.insertionIndex(of: message, using: { (message1, message2) -> Bool in
//					return message1.timestamp.value ?? 0 <  message2.timestamp.value ?? 0
//				})

				

				self.collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])





			//	let rowIndex = self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
					//self.groupedMessages[sectionIndex].messages.count - 1 : 0

		//		if rowIndex == self.groupedMessages[sectionIndex].messages.count {
				//	self.collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
		//		}
			}
		//}, completion: { (isCompleted) in
			if self.isScrollViewAtTheBottom() {
				self.collectionView.scrollToBottom(animated: true)
			}

			self.updateMessageStatus(messageRef: reference)
		//	let tokens = self.groupedMessages.map({ $0.notificationToken }).compactMap({ $0 })
			try! self.realm.commitWrite()//withoutNotifying: tokens)
//			for message in self.groupedMessages where message.notificationToken == nil {
//				self.observeChanges(for: message)
//			}
			NotificationCenter.default.post(name: .messageSent, object: nil)
		//})
	}
  
//  fileprivate func peformBatchUpdate(for message: Message, at insertionIndex: Int, reference: DatabaseReference) {
//    messages.insert(message, at: insertionIndex)
//    guard let messagesFetcher = messagesFetcher else { return }
//    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
//      messages = messagesFetcher.configureTails(for: messages, isGroupChat: true)
//    } else {
//      messages = messagesFetcher.configureTails(for: messages, isGroupChat: false)
//    }
//    
//    let oldSections = groupedMessages.count
//    groupedMessages = Message.groupedMessages(messages)
//    guard let indexPath = Message.get(indexPathOf: message, in: groupedMessages) else { return }
//    
//    collectionView.performBatchUpdates({
//      if oldSections < groupedMessages.count {
//        collectionView.insertSections([indexPath.section])
//        // TODO: scroll to bottom
//      } else {
//        collectionView.insertItems(at: [indexPath])
//        // TODO: scroll to bottom
//      }
//      
//    }) { (_) in
//      self.updateMessageStatus(messageRef: reference)
//      guard oldSections <= self.groupedMessages.count else { return }
//      UIView.performWithoutAnimation {
//        self.collectionView.performBatchUpdates({
//           self.collectionView.reloadSections([indexPath.section])
//        }) { (_) in
//          guard self.isScrollViewAtTheBottom() else { return }
//          self.collectionView.scrollToBottom(animated: true)
//        }
//      }
//      
//    }
//  }
}
