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

	func preloadedCellData(values: [String: AnyObject]) -> [String: AnyObject] {
		var values = values

		if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
			values = messagesFetcher?.preloadCellData(to: values, isGroupChat: true) ?? values
		} else {
			values = messagesFetcher?.preloadCellData(to: values, isGroupChat: true) ?? values
		}
		return values
	}

  func update(with arrayOfvalues: [[String: AnyObject]]) {

		autoreleasepool {
			let realm = try! Realm()
			guard !realm.isInWriteTransaction else { return }

			realm.beginWrite()

			collectionView.performBatchUpdates({
				for values in arrayOfvalues {
					let message = Message(dictionary: preloadedCellData(values: values))
					message.status = messageStatusSending
					message.conversation = conversation
					message.isCrooked.value = false

					realm.create(Message.self, value: message, update: true)

					guard let newSectionTitle = message.shortConvertedTimestamp else { realm.cancelWrite(); return }
					let lastSection = groupedMessages.last?.title ?? ""
					let isNewSection = newSectionTitle != lastSection
					let sectionIndex = groupedMessages.count - 1 >= 0 ? groupedMessages.count - 1 : 0
					let rowIndex = groupedMessages[sectionIndex].messages.count - 1 >= 0 ? groupedMessages[sectionIndex].messages.count - 1 : 0

					if isNewSection {
						guard let messages = conversation?.messages
						.sorted(byKeyPath: "timestamp", ascending: true)
						.filter("shortConvertedTimestamp == %@", newSectionTitle) else { realm.cancelWrite(); return }
						let newSection = MessageSection(messages: messages, title: newSectionTitle)
						groupedMessages.append(newSection)
						collectionView.insertSections(IndexSet([sectionIndex]))
					} else {
						if groupedMessages[sectionIndex].messages.indices.contains(rowIndex - 1),
							groupedMessages[sectionIndex].messages[rowIndex - 1].fromId == message.fromId {
							groupedMessages[sectionIndex].messages[rowIndex - 1].isCrooked.value = false
						}
						collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
					}
				}
			}, completion: { (isCompleted) in
				self.groupedMessages.last?.messages.last?.isCrooked.value = true
				let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
				let rowIndex = self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
				self.groupedMessages[sectionIndex].messages.count - 1 : 0
				UIView.performWithoutAnimation {
					self.collectionView.reloadItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
					if rowIndex-arrayOfvalues.count >= 0 {
						self.collectionView.reloadItems(at: [IndexPath(row: rowIndex-arrayOfvalues.count, section: sectionIndex)])
					}
				}

				self.collectionView.scrollToBottom(animated: true)

				try! realm.commitWrite()
				NotificationCenter.default.post(name: .messageSent, object: nil)
			})
		}
  }
}
