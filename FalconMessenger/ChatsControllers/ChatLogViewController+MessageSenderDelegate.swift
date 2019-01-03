//
//  ChatLogViewController+MessageSenderDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

extension ChatLogViewController: MessageSenderDelegate {
  
  func update(mediaSending progress: Double, animated: Bool) {
    uploadProgressBar.setProgress(Float(progress), animated: animated)
  }
  
  func update(with arrayOfvalues: [[String: AnyObject]]) {


		autoreleasepool {
			let realm = try! Realm()

			realm.beginWrite()

			collectionView.performBatchUpdates({

				for values in arrayOfvalues {
					var values = values
					guard let messagesFetcher = messagesFetcher else { realm.cancelWrite(); return }
					if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
						values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
					} else {
						values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
					}
					let message = Message(dictionary: values)
					message.status = messageStatusSending
					message.conversation = conversation

					realm.create(Message.self, value: message, update: true)

					guard let newSectionTitle = message.shortConvertedTimestamp else { realm.cancelWrite(); return }

					let lastSection = groupedMessages.last?.title ?? ""
					let isNewSection = newSectionTitle != lastSection

					if isNewSection {
						guard let messages = conversation?.messages
							.sorted(byKeyPath: "timestamp", ascending: true)
							.filter("shortConvertedTimestamp == %@", newSectionTitle) else { realm.cancelWrite(); return }

						print(messages.count)

						let newSection = SectionedMessage(messages: messages, title: newSectionTitle)

						groupedMessages.append(newSection)

						let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
						self.collectionView.insertSections(IndexSet([sectionIndex]))
					} else {
						let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0

						let rowIndex = self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
							self.groupedMessages[sectionIndex].messages.count - 1 : 0

						self.collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
					}
				}
				
			}, completion: { (isCompleted) in
			//	guard isCompleted else { return }



			})

			self.collectionView.scrollToBottom(animated: true)

			let tokens = self.groupedMessages.map({ $0.notificationToken }).compactMap({ $0 })

			try! realm.commitWrite(withoutNotifying: tokens)




		//	self.groupedMessages

			for message in self.groupedMessages where message.notificationToken == nil {
		//		if message.notificationToken == nil {
					self.observeChanges(for: message)
				//}
			}
			NotificationCenter.default.post(name: .messageSent, object: nil)

//			if let lastSection = self.groupedMessages.last {
//
//				print(lastSection.title, lastSection.messages)
//				if lastSection.notificationToken == nil {
//					self.observeChanges(for: lastSection)
//				}
//			}

	//		for values in arrayOfvalues {

				//var values = values

//				guard let messagesFetcher = messagesFetcher else { realm.cancelWrite(); return }
//				if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
//					values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
//				} else {
//					values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
//				}
//
//				let message = Message(dictionary: values)
//				message.status = messageStatusSending
//				message.conversation = conversation
//
//
//				realm.create(Message.self, value: message, update: true)
//
//				guard let newSectionTitle = message.shortConvertedTimestamp else { realm.cancelWrite(); return }
//
//				let lastSection = groupedMessages.last?.title ?? ""
//				let isNewSection = newSectionTitle != lastSection

//				collectionView.performBatchUpdates({
//
//					if isNewSection {
//						guard let messages = conversation?.messages
//							.sorted(byKeyPath: "timestamp", ascending: true)
//							.filter("shortConvertedTimestamp == %@", newSectionTitle) else { realm.cancelWrite(); return }
//						print(messages.count)
//
//						let newSection = SectionedMessage(messages: messages, title: newSectionTitle)
//
//						groupedMessages.append(newSection)
//
//						let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
//
//
//
//						//		groupedMessages[sectionIndex].messages.ass
//
//						self.collectionView.insertSections(IndexSet([sectionIndex]))
//						//	self.collectionView.insertItems(at: [IndexPath(row: 0, section: sectionIndex)])
//					} else {
//						let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
//
//						let rowIndex = self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
//							self.groupedMessages[sectionIndex].messages.count - 1 : 0
//
//
//
//					//	UIView.performWithoutAnimation {
//							self.collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
//					//	}
//
//					}
//				}, completion: { (isCompleted) in
//				//	let tokens = self.groupedMessages.map({ $0.notificationToken }).compactMap({ $0 })
//
//
//
////					try! realm.commitWrite(withoutNotifying: tokens)
//
//					//			let tokens = self.groupedMessages.map({ $0.notificationToken }).compactMap({ $0 })
//					//
//					//
//					//
//					//			try! realm.commitWrite(withoutNotifying: tokens)
//
//					self.collectionView.scrollToBottom(animated: true)
//
//
//
//				})
		//	}

//			let tokens = self.groupedMessages.map({ $0.notificationToken }).compactMap({ $0 })
//			try! realm.commitWrite(withoutNotifying: tokens)
//
//			NotificationCenter.default.post(name: .messageSent, object: nil)
//			if let lastSection = self.groupedMessages.last {
//				if lastSection.notificationToken == nil {
//					self.observeChanges(for: lastSection)
//				}
//			}

		}//*/







		//realm.isInWriteTransaction
//		autoreleasepool {

	//	}

	//	realm.refresh()



//	}


		
		//messagesFetcher.configureTails(for: conversation!.messages, isGroupChat: nil)







		//let oldNumberOfSections = groupedMessages.count

		//withoutNotifying: groupedMessages.map({ $0.notificationToken ?? NotificationToken() })
		//NotificationCenter.default.post(name: .messageSent, object: nil)



		//updateDataSource(with: values, oldNumberOfSections: oldNumberOfSections)
		
//		collectionView.scrollToBottom(animated: true)


  }
  
//  //TO REFACTOR
//	fileprivate func updateDataSource(with values: [String: AnyObject], oldNumberOfSections: Int) {
//
//  //  let realm = try! Realm()
//
//    var values = values
//
//    guard let messagesFetcher = messagesFetcher else { return }
//    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
//      values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
//    } else {
//      values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
//    }
//
//    let message = Message(dictionary: values)
////		message.status = messageStatusSending
////		message.conversation = conversation
//	//	message.senderName = convers
//  //  messages.append(message)
//
////		realm.beginWrite()
////		realm.create(Message.self, value: message, update: true)
////    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
////      messages = messagesFetcher.configureTails(for: messages, isGroupChat: true)
////    } else {
////      messages = messagesFetcher.configureTails(for: messages, isGroupChat: false)
////    }
////		try! realm.commitWrite()
//
//		NotificationCenter.default.post(name: .messageSent, object: nil)
//
//
//   // let oldNumberOfSections = groupedMessages.count
//  //  groupedMessages = Message.groupedMessages(messages)
//    guard let indexPath = Message.get(indexPathOf: message, in: groupedMessages) else { return }
//
//    collectionView.performBatchUpdates({
//      if oldNumberOfSections-1 < groupedMessages.count {
//
//        collectionView.insertSections([indexPath.section])
//
//        guard indexPath.section-1 >= 0, groupedMessages[indexPath.section-1].messages.count-1 >= 0 else { return }
//        let previousItem = groupedMessages[indexPath.section-1].messages.count-1
//        collectionView.reloadItems(at: [IndexPath(row: previousItem, section: indexPath.section-1)])
//      } else {
//        collectionView.insertItems(at: [indexPath])
//        let previousRow = groupedMessages[indexPath.section].messages.count-2
//        self.collectionView.reloadItems(at: [IndexPath(row: previousRow, section: indexPath.section)])
//      }
//    }) { (_) in
//      self.collectionView.scrollToBottom(animated: true)
//    }
//  }
}
