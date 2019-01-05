//
//  ChatLogViewController+ChatHistoryFetcherDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/28/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

extension ChatLogViewController: ChatLogHistoryDelegate {
  
  func chatLogHistory(isEmpty: Bool) {
    refreshControl.endRefreshing()
  }




	func gg (messages: [Message]) {
		let realm = try! Realm()

		collectionView.performBatchUpdates({

			for message in messages {
					realm.create(Message.self, value: message, update: true)
					guard let newSectionTitle = message.shortConvertedTimestamp else { realm.cancelWrite(); return }

					let firstSection = groupedMessages.first?.title ?? ""
					let isNewSection = newSectionTitle != firstSection


				if isNewSection {
					guard let messages = conversation?.messages
						.sorted(byKeyPath: "timestamp", ascending: true)
						.filter("shortConvertedTimestamp == %@", newSectionTitle) else { realm.cancelWrite(); return }

					print(messages.count)

					let newSection = SectionedMessage(messages: messages, title: newSectionTitle)

					groupedMessages.insert(newSection, at: 0)

					let sectionIndex = 0//self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
					self.collectionView.insertSections(IndexSet([sectionIndex]))
				} else {
					let sectionIndex = 0//self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0

					let rowIndex = 0
//						self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
//						self.groupedMessages[sectionIndex].messages.count - 1 : 0

					self.collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
				}



			}

//			for values in arrayOfvalues {
////				var values = values
////				guard let messagesFetcher = messagesFetcher else { realm.cancelWrite(); return }
////				if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
////					values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
////				} else {
////					values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
////				}
////				let message = Message(dictionary: values)
////				message.status = messageStatusSending
////				message.conversation = conversation
//
//				realm.create(Message.self, value: message, update: true)
//
//				guard let newSectionTitle = message.shortConvertedTimestamp else { realm.cancelWrite(); return }
//
//				let lastSection = groupedMessages.last?.title ?? ""
//				let isNewSection = newSectionTitle != lastSection
//
//				if isNewSection {
//					guard let messages = conversation?.messages
//						.sorted(byKeyPath: "timestamp", ascending: true)
//						.filter("shortConvertedTimestamp == %@", newSectionTitle) else { realm.cancelWrite(); return }
//
//					print(messages.count)
//
//					let newSection = SectionedMessage(messages: messages, title: newSectionTitle)
//
//					groupedMessages.append(newSection)
//
//					let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
//					self.collectionView.insertSections(IndexSet([sectionIndex]))
//				} else {
//					let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
//
//					let rowIndex = self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
//						self.groupedMessages[sectionIndex].messages.count - 1 : 0
//
//					self.collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
//				}
//			}

		}, completion: { (isCompleted) in
			//	guard isCompleted else { return }



		})
	}
	func chatLogHistory(updated messages: [Message]) {
		globalDataStorage.contentSizeWhenInsertingToTop = collectionView.contentSize
		globalDataStorage.isInsertingCellsToTop = true
		refreshControl.endRefreshing()

	//	return


//		self.messages = messages
		let oldSections = self.groupedMessages.count
//		self.groupedMessages = Message.groupedMessages(messages)


		// 1. write to realm first in case of some changes, without notifications
		// 2. get range of next page
		// 3. loading previously updated messages in range from realm
		// 4. setup observers for new sections
		// 4. batch updating of collection view


		let realm = try! Realm()
		autoreleasepool {
			realm.beginWrite()
			for message in messages {
				if realm.object(ofType: Message.self, forPrimaryKey: message.messageUID) == nil {
					realm.create(Message.self, value: message, update: true)
				}
			}

	//		let tokens = self.groupedMessages.map({ $0.notificationToken }).compactMap({ $0 })
			try! realm.commitWrite()//withoutNotifying: tokens)
		}

//
//		let pageOffset = 50
//		let allMessages = conversation!.messages.sorted(byKeyPath: "timestamp", ascending: true)
//		let flatGroupedMessages = groupedMessages.compactMap({ $0.messages })
//		let nextPage: (fromIndex: Int, toIndex: Int) = (fromIndex: allMessages.count - flatGroupedMessages.count - pageOffset,
//																										toIndex: allMessages.count - flatGroupedMessages.count)
//
//
//		var messages: Results<Message>!
//		let messagesList = List<Message>()
//
//
//		for index in nextPage.fromIndex...nextPage.toIndex where index >= 0 {
//			print(index)
//			let pagedItem = allMessages[index]
//			messagesList.append(pagedItem)
//		}
//
//
//
//		messages = messagesList.sorted(byKeyPath: "timestamp", ascending: true)

		







		UIView.performWithoutAnimation {
			collectionView.performBatchUpdates({
				guard oldSections < self.groupedMessages.count else { collectionView.reloadSections([0]); return }
				let amount: Int = self.groupedMessages.count - oldSections
				var indexSet = IndexSet()
				Array(0..<amount).forEach({ (index) in
					indexSet.insert(index)
				})
				collectionView.reloadSections([0])
				collectionView.insertSections(indexSet)
			}, completion: { (_) in
				DispatchQueue.main.async {
					self.bottomScrollConainer.isHidden = false
				}
			})
		}
	}


//}

//  func chatLogHistory(updated messages: [Message]) {
//    globalDataStorage.contentSizeWhenInsertingToTop = collectionView.contentSize
//    globalDataStorage.isInsertingCellsToTop = true
//    refreshControl.endRefreshing()
//
//		let realm = try! Realm()
//
//		autoreleasepool {
//			realm.beginWrite()
//			for message in messages {
//				if realm.object(ofType: Message.self, forPrimaryKey: message.messageUID) == nil {
//					realm.create(Message.self, value: message, update: true)
//				}
//			}
//
//			let tokens = self.groupedMessages.map({ $0.notificationToken }).compactMap({ $0 })
//			try! realm.commitWrite(withoutNotifying: tokens)
//		}
//
////		realm.beginWrite()
////		messagesFetcher?.configureTails(for: conversation!.messages, isGroupChat: nil)
////		try! realm.commitWrite()
////let mmm = conversation!.messages.sorted(byKeyPath: "timestamp", ascending: true)
//		//conversation.MESS
////		let allMessages = groupedMessages.flatMap { (sectionedMessage) -> [Message] in
////			return Array(sectionedMessage.messages)
////		}
//
//	//	print(allMessages.count)
//
//	//	getMessages(fromIndex: mmm.count-allMessages.count-50, toIndex: mmm.count-allMessages.count)
//		DispatchQueue.main.async {
//			self.bottomScrollConainer.isHidden = false
//		}
//
////		try! realm.write {
////			au
////			realm.create(Message.self, value: , update: )
////			self.messages = messages
////		}
//
////    let oldSections = self.groupedMessages.count
////   // self.groupedMessages = Message.groupedMessages(messages)
////
////    UIView.performWithoutAnimation {
////      collectionView.performBatchUpdates({
////        guard oldSections < self.groupedMessages.count else { collectionView.reloadSections([0]); return }
////        let amount: Int = self.groupedMessages.count - oldSections
////        var indexSet = IndexSet()
////        Array(0..<amount).forEach({ (index) in
////          indexSet.insert(index)
////        })
////        collectionView.reloadSections([0])
////        collectionView.insertSections(indexSet)
////      }, completion: { (_) in
////        DispatchQueue.main.async {
////          self.bottomScrollConainer.isHidden = false
////        }
////      })
////    }
//  }
}
