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

	fileprivate func tails(messages: Results<Message>) {
		for index in (0..<messages.count).reversed() {
			try! realm.safeWrite {
				let isLastMessage = index == messages.count - 1
				if isLastMessage { messages[index].isCrooked.value = true }
				guard messages.indices.contains(index - 1) else { return }
				let isPreviousMessageSenderDifferent = messages[index - 1].fromId != messages[index].fromId
				messages[index - 1].isCrooked.value = isPreviousMessageSenderDifferent ? true : messages[index].isInformationMessage.value ?? false
			}
		}
	}

	func chatLogHistory(updated newMessages: [Message]) {
		print(newMessages.count)

		globalDataStorage.contentSizeWhenInsertingToTop = collectionView.contentSize
		globalDataStorage.isInsertingCellsToTop = true
		refreshControl.endRefreshing()

		let realm = try! Realm()
		autoreleasepool {
			guard !realm.isInWriteTransaction else { return }
			realm.beginWrite()
			for message in newMessages {
				realm.create(Message.self, value: message, update: true)
			}
			try! realm.commitWrite()


			var sectionsInserted = 0
			let firstSection = groupedMessages.first?.title ?? ""
			let dates = newMessages.map({ $0.shortConvertedTimestamp ?? "" })
			var datesSet = Set(dates)

			let allMessages = groupedMessages.flatMap { (sectionedMessage) -> Results<Message> in
				return sectionedMessage.messages
			}


			if datesSet.contains(firstSection) {
				var messages = conversation!.messages.filter("shortConvertedTimestamp == %@", firstSection)

				if messages.count > allMessages.count + messagesToLoad {
					messages = messages.sorted(byKeyPath: "timestamp", ascending: true)

					guard let timestamp = messages[messages.count - (allMessages.count + messagesToLoad)].timestamp.value else { return }
					messages = messages.filter("timestamp >= %@", timestamp)
					tails(messages: messages)

					let section = MessageSection(messages: messages, title: firstSection)
					let oldItemsCount = groupedMessages[0].messages.count
					groupedMessages[0] = section
					let newItemsCount = section.messages.count
					let amount = newItemsCount - oldItemsCount

					var indexPaths = [IndexPath]()

					Array(0..<amount).forEach({ (index) in
						indexPaths.append(IndexPath(row: index, section: 0))
					})

					UIView.performWithoutAnimation {
						collectionView.performBatchUpdates({
							collectionView.insertItems(at: indexPaths)
						}, completion: nil)
					}
					return
				} else {
					messages = messages.sorted(byKeyPath: "timestamp", ascending: true)
					tails(messages: messages)

					let section = MessageSection(messages: messages, title: firstSection)
					groupedMessages[0] = section

					UIView.performWithoutAnimation {
						collectionView.reloadSections([0])
					}

					datesSet.remove(firstSection)
				}
			}

			let uniqueDates = Array(datesSet)

			let keys = uniqueDates.sorted { (time1, time2) -> Bool in
				return Date.dateFromCustomString(customString: time1) <  Date.dateFromCustomString(customString: time2)
			}

			for date in keys.reversed() {
				let messages = conversation!.messages.filter("shortConvertedTimestamp == %@", date).sorted(byKeyPath: "timestamp", ascending: true)
				tails(messages: messages)
				let section = MessageSection(messages: messages, title: date)
				sectionsInserted += 1
				groupedMessages.insert(section, at: 0)
			}

			UIView.performWithoutAnimation {
				collectionView.performBatchUpdates({
					guard sectionsInserted > 0 else { return }

					var indexSet = IndexSet()
					Array(0..<sectionsInserted).forEach({ (index) in
						indexSet.insert(index)
					})

					collectionView.insertSections(indexSet)
				}, completion: { (_) in
					DispatchQueue.main.async {
						self.bottomScrollConainer.isHidden = false
					}
				})
			}
		}
	}
}
