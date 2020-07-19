//
//  ChatLogViewController+MessageSenderDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

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
			guard !realm.isInWriteTransaction else { return }

			collectionView.performBatchUpdates({ 
				for values in arrayOfvalues {
					realm.beginWrite()
					let message = Message(dictionary: preloadedCellData(values: values))
					message.status = messageStatusSending
					message.conversation = conversation
					message.isCrooked.value = false
					realm.create(Message.self, value: message, update: .modified)

					guard let newSectionTitle = message.shortConvertedTimestamp else { realm.cancelWrite(); return }

					let lastSection = groupedMessages.last?.title ?? ""
					let isNewSection = newSectionTitle != lastSection

					if isNewSection {
						guard let messages = conversation?.messages
							.filter("shortConvertedTimestamp == %@", newSectionTitle)
							.sorted(byKeyPath: "timestamp", ascending: true) else { realm.cancelWrite(); return }

						let newSection = MessageSection(messages: messages, title: newSectionTitle)
						groupedMessages.append(newSection)

						let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
						self.collectionView.insertSections(IndexSet([sectionIndex]))
					} else {

						let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0
						let rowIndex = self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
						self.groupedMessages[sectionIndex].messages.count - 1 : 0

						if self.groupedMessages[sectionIndex].messages.indices.contains(rowIndex - 1),
							self.groupedMessages[sectionIndex].messages[rowIndex - 1].fromId == message.fromId {
							self.groupedMessages[sectionIndex].messages[rowIndex - 1].isCrooked.value = false
						}
						self.collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
					}
					self.groupedMessages.last?.messages.last?.isCrooked.value = true
					try! realm.commitWrite()
				}
			}, completion: { (isCompleted) in

				let sectionIndex = self.groupedMessages.count - 1 >= 0 ? self.groupedMessages.count - 1 : 0

				let rowIndex = self.groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
					self.groupedMessages[sectionIndex].messages.count - 1 : 0

					self.collectionView.performBatchUpdates({
						UIView.performWithoutAnimation {
							self.collectionView.reloadItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
							if rowIndex-arrayOfvalues.count >= 0 {
								self.collectionView.reloadItems(at: [IndexPath(row: rowIndex-arrayOfvalues.count, section: sectionIndex)])
							}
						}
					}, completion: nil)
				self.collectionView.scrollToBottom(animated: true)
				NotificationCenter.default.post(name: .messageSent, object: nil)
			})
		}
  }
}
