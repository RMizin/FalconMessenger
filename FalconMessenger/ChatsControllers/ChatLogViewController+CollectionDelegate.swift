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
  
  func collectionView(shouldRemoveMessage id: String) { }

  func collectionView(shouldUpdateOutgoingMessageStatusFrom reference: DatabaseReference, message: Message) {
    guard let messageID = message.messageUID else { return }
    let handle = DatabaseHandle()
    
    messageChangesHandles.insert((uid: messageID, handle: handle), at: 0)
    messageChangesHandles[0].handle = reference.observe(.childChanged, with: { (snapshot) in
      guard snapshot.exists(), snapshot.key == "status", let newMessageStatus = snapshot.value else { return }
			message.status = newMessageStatus as? String
      self.updateMessageStatusUI(sentMessage: message)
    })
		DispatchQueue.global(qos: .background).async {
    	self.updateMessageStatus(messageRef: reference)
		}
    updateMessageStatusUI(sentMessage: message)
  }

  func collectionView(shouldBeUpdatedWith message: Message, reference: DatabaseReference) {
		self.update(message: message, reference: reference)
  }

	func update(message: Message, reference: DatabaseReference) {
		guard isInsertingToTheBottom(message: message) else { return }
		batch(message: message, reference: reference)
	}

	fileprivate func batch(message: Message, reference: DatabaseReference) {
		guard !realm.isInWriteTransaction else { return }

		realm.beginWrite()
		groupedMessages.last?.messages.last?.isCrooked.value = false
		message.conversation = conversation
		message.isCrooked.value = false
		realm.create(Message.self, value: message, update: .modified)

		guard let newSectionTitle = message.shortConvertedTimestamp else { try! self.realm.commitWrite(); return }
		let lastSectionTitle = groupedMessages.last?.title ?? ""
		let mustCreateNewSection = newSectionTitle != lastSectionTitle

		if mustCreateNewSection {
			guard let messages = conversation?.messages.filter("shortConvertedTimestamp == %@", newSectionTitle)
				.sorted(byKeyPath: "timestamp", ascending: true) else { try! self.realm.commitWrite(); return }

			let newSection = MessageSection(messages: messages, title: newSectionTitle)

			let insertionIndex = groupedMessages.insertionIndexOf(elem: newSection) { (section1, section2) -> Bool in
				return Date.dateFromCustomString(customString: section1.title ?? "") < Date.dateFromCustomString(customString: section2.title ?? "")
			}
			groupedMessages.insert(newSection, at: insertionIndex)
			groupedMessages.last?.messages.last?.isCrooked.value = true
			collectionView.performBatchUpdates({
					collectionView.insertSections([insertionIndex])
			}) { (isCompleted) in
				self.performAdditionalUpdates(reference: reference)
			}
		} else {
			guard let indexPath = Message.get(indexPathOf: message, in: groupedMessages) else { try! self.realm.commitWrite(); return }
			groupedMessages.last?.messages.last?.isCrooked.value = true

			// temporary due to inefficiency
			UIView.performWithoutAnimation {
				collectionView.performBatchUpdates({
						collectionView.reloadSections([indexPath.section])
				}) { (isCompleted) in
					self.performAdditionalUpdates(reference: reference)
				}
			}
		}
		try! self.realm.commitWrite()
	}

	fileprivate func isInsertingToTheBottom(message: Message) -> Bool {
		let firstObject = groupedMessages.last?.messages.first?.timestamp.value ?? 0
		guard message.timestamp.value ?? 0 >= firstObject else { return false }
		return true
	}

	fileprivate func performAdditionalUpdates(reference: DatabaseReference) {
		DispatchQueue.global(qos: .background).async {
			self.updateMessageStatus(messageRef: reference)
		}
		if self.isScrollViewAtTheBottom() {
			self.collectionView.scrollToBottom(animated: true)
		}
		NotificationCenter.default.post(name: .messageSent, object: nil)
	}
}
