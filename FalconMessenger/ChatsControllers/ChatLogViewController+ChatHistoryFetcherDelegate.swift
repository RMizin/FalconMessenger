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
			let isLastMessage = index == messages.count - 1
			if isLastMessage { messages[index].isCrooked.value = true }
			guard messages.indices.contains(index - 1) else { return }
			let isPreviousMessageSenderDifferent = messages[index - 1].fromId != messages[index].fromId
			messages[index - 1].isCrooked.value = isPreviousMessageSenderDifferent ? true : messages[index].isInformationMessage.value ?? false
		}
	}

	func chatLogHistory(updated messages: [Message]) {
		globalDataStorage.contentSizeWhenInsertingToTop = collectionView.contentSize
		globalDataStorage.isInsertingCellsToTop = true
		refreshControl.endRefreshing()

		let realm = try! Realm()
		autoreleasepool {
			guard !realm.isInWriteTransaction else { return }
			realm.beginWrite()
			for message in messages {
				realm.create(Message.self, value: message, update: true)
			}

			var sectionsInserted = 0
			let firstSection = groupedMessages.first?.title ?? ""
			let dates = messages.map({ $0.shortConvertedTimestamp ?? "" })

			var datesSet = Set(dates)
			if datesSet.contains(firstSection) {
				let messages = conversation!.messages.sorted(byKeyPath: "timestamp", ascending: true).filter("shortConvertedTimestamp == %@", firstSection)
				tails(messages: messages)
				datesSet.remove(firstSection)
			}

			let uniqueDates = Array(datesSet)

			let keys = uniqueDates.sorted { (time1, time2) -> Bool in
				return Date.dateFromCustomString(customString: time1) <  Date.dateFromCustomString(customString: time2)
			}

			for date in keys.reversed() {
				let messages = conversation!.messages.sorted(byKeyPath: "timestamp", ascending: true).filter("shortConvertedTimestamp == %@", date)
				tails(messages: messages)
				let section = MessageSection(messages: messages, title: date)
				sectionsInserted += 1
				groupedMessages.insert(section, at: 0)
			}

			UIView.performWithoutAnimation {
				collectionView.performBatchUpdates({

					guard sectionsInserted > 0 else {
						UIView.performWithoutAnimation {
							collectionView.reloadSections([0])
						}

						try! realm.commitWrite()
						print("returning from sections inserted 0")
						return
					}

					print("inserting coll sections")
					var indexSet = IndexSet()
					Array(0..<sectionsInserted).forEach({ (index) in
						print("inserting...")
						indexSet.insert(index)
					})
					UIView.performWithoutAnimation {
						collectionView.reloadSections([0])
						collectionView.insertSections(indexSet)
					}
				}, completion: { (_) in
					DispatchQueue.main.async {
						self.bottomScrollConainer.isHidden = false
					}
				})
			}
			if realm.isInWriteTransaction {
				try! realm.commitWrite()
			}
		}
	}
}
