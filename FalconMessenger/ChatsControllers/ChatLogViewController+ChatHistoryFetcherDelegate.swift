//
//  ChatLogViewController+ChatHistoryFetcherDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/28/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension ChatLogViewController: ChatLogHistoryDelegate {
  
  func chatLogHistory(isEmpty: Bool) {
    refreshControl.endRefreshing()
  }

	func chatLogHistory(updated newMessages: [Message]) {
		let numberOfMessagesInFirstSectionBeforeUpdate = groupedMessages[0].messages.count
		let numberOfMessagesInDataSourceBeforeUpdate = groupedMessages.compactMap { (sectionedMessage) -> Int in
			return sectionedMessage.messages.count
			}.reduce(0, +)

		updateRealmMessagesData(newMessages: newMessages) //saved: {
			let firstSectionTitle = groupedMessages.first?.title ?? ""
			let dates = newMessages.map({ $0.shortConvertedTimestamp ?? "" })
			var datesSet = Set(dates)

			let rowsRange = updateFirstSection(firstSectionTitle, numberOfMessagesInDataSourceBeforeUpdate, numberOfMessagesInFirstSectionBeforeUpdate)
			datesSet.remove(firstSectionTitle)
			let sectionsRange = insertNewSections(datesSet)
			batchInsertMS(rowsRange: rowsRange, sectionsRange: sectionsRange)
	}

	fileprivate func updateRealmMessagesData(newMessages: [Message]) {
		autoreleasepool {
			try! realm.safeWrite {
				for message in newMessages {
					realm.create(Message.self, value: message, update: .modified)
				}
			}
		}
	}

	fileprivate func batchInsertMS(rowsRange: Int, sectionsRange: Int) {
		UIView.performWithoutAnimation {
			collectionView.performBatchUpdates({
				var indexSet = IndexSet()
				Array(0..<sectionsRange).forEach({ (index) in
					indexSet.insert(index)
				})

				var indexPaths = [IndexPath]()
				Array(0..<rowsRange).forEach({ (index) in
					indexPaths.append(IndexPath(row: index, section: indexSet.count))
				})

				globalVariables.contentSizeWhenInsertingToTop = collectionView.contentSize
				globalVariables.isInsertingCellsToTop = true
				
				collectionView.insertSections(indexSet)
				collectionView.insertItems(at: indexPaths)
			}, completion: { (_) in
				DispatchQueue.main.async {
					self.bottomScrollConainer.isHidden = false
					self.refreshControl.endRefreshing()
				}
			})
		}
	}

	fileprivate func insertNewSections(_ datesSet: Set<String>) -> Int {
		var sectionsInserted = 0
		let datesArray = Array(datesSet).sorted { (time1, time2) -> Bool in
			return Date.dateFromCustomString(customString: time1) <  Date.dateFromCustomString(customString: time2)
		}
		let numberOfMessagesInDataSourceBeforeInsertNewSections = groupedMessages.compactMap { (sectionedMessage) -> Int in
			return sectionedMessage.messages.count
			}.reduce(0, +)

		for date in datesArray.reversed() {
			guard var messagesInSection = conversation?.messages
				.filter("shortConvertedTimestamp == %@", date)
				.sorted(byKeyPath: "timestamp", ascending: true) else {
					continue
			}

			let messagesInSectionCount = messagesInSection.count
			let maxNumberOfMessagesInChat = numberOfMessagesInDataSourceBeforeInsertNewSections + messagesToLoad
			let possibleNumberOfMessagesWithInsertedSection = numberOfMessagesInDataSourceBeforeInsertNewSections + messagesInSectionCount
			let needToLimitSection = possibleNumberOfMessagesWithInsertedSection > maxNumberOfMessagesInChat

			if needToLimitSection {
				let indexOfLastMessageToDisplay = possibleNumberOfMessagesWithInsertedSection - maxNumberOfMessagesInChat
				guard let timestampOfLastMessageToDisplay = messagesInSection[indexOfLastMessageToDisplay].timestamp.value else { continue }
				let limitedMessagesForSection = messagesInSection.filter("timestamp >= %@", timestampOfLastMessageToDisplay)
				messagesInSection = limitedMessagesForSection
				let newSection = MessageSection(messages: messagesInSection, title: date)
				configureBubblesTails(for: newSection.messages)
				groupedMessages.insert(newSection, at: 0)
				sectionsInserted += 1
				break
			} else {
				let newSection = MessageSection(messages: messagesInSection, title: date)
				configureBubblesTails(for: newSection.messages)
				groupedMessages.insert(newSection, at: 0)
				sectionsInserted += 1
			}
		}
		return sectionsInserted
	}

	fileprivate func updateFirstSection(
		_ firstSectionTitle: String,
		_ numberOfMessagesInDataSourceBeforeUpdate: Int,
		_ numberOfMessagesInFirstSectionBeforeUpdate: Int) -> Int {

		guard var messagesInFirstSectionAfterUpdate = conversation?.messages
			.filter("shortConvertedTimestamp == %@", firstSectionTitle)
			.sorted(byKeyPath: "timestamp", ascending: true) else { return 0 }

		let numberOfMessagesInFirstSectionAfterUpdate = messagesInFirstSectionAfterUpdate.count
		let possibleNumberOfMessagesWithUpdatedSection = (numberOfMessagesInDataSourceBeforeUpdate - numberOfMessagesInFirstSectionBeforeUpdate) + numberOfMessagesInFirstSectionAfterUpdate
		let maxNumberOfMessagesInChat = numberOfMessagesInDataSourceBeforeUpdate + messagesToLoad
		let needToLimitFirstSection = possibleNumberOfMessagesWithUpdatedSection > maxNumberOfMessagesInChat

		if needToLimitFirstSection {
			let indexOfLastMessageToDisplay = possibleNumberOfMessagesWithUpdatedSection - maxNumberOfMessagesInChat
			guard let timestampOfLastMessageToDisplay = messagesInFirstSectionAfterUpdate[indexOfLastMessageToDisplay].timestamp.value else { return 0 }
			let limitedMessagesForFirstSection = messagesInFirstSectionAfterUpdate.filter("timestamp >= %@", timestampOfLastMessageToDisplay)
			messagesInFirstSectionAfterUpdate = limitedMessagesForFirstSection
			let updatedFirstSection = MessageSection(messages: messagesInFirstSectionAfterUpdate, title: firstSectionTitle)
			configureBubblesTails(for: updatedFirstSection.messages)
			groupedMessages[0] = updatedFirstSection
			let numberOfMessagesInFirstSectionAfterLimiting = groupedMessages[0].messages.count

			return numberOfMessagesInFirstSectionAfterLimiting - numberOfMessagesInFirstSectionBeforeUpdate
		} else {
			let updatedFirstSection = MessageSection(messages: messagesInFirstSectionAfterUpdate, title: firstSectionTitle)
			configureBubblesTails(for: updatedFirstSection.messages)
			groupedMessages[0] = updatedFirstSection
			return numberOfMessagesInFirstSectionAfterUpdate - numberOfMessagesInFirstSectionBeforeUpdate
		}
	}
}
