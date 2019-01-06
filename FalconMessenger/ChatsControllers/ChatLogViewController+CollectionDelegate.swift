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
    
    updateMessageStatus(messageRef: reference)
    updateMessageStatusUI(sentMessage: message)
  }


  func collectionView(shouldBeUpdatedWith message: Message, reference: DatabaseReference) {
		update(message: message, reference: reference)
  }

	func update(message: Message, reference: DatabaseReference) {
		let lastObject = conversation?.messages.sorted(byKeyPath: "timestamp", ascending: true).last
		guard message.timestamp.value ?? 0 >= lastObject?.timestamp.value ?? 0 else { return }

		realm.beginWrite()

		message.conversation = conversation
		message.isCrooked.value = true

		realm.create(Message.self, value: message, update: true)

		guard let newSectionTitle = message.shortConvertedTimestamp else { try! realm.commitWrite(); return }
		let lastSection = groupedMessages.last?.title ?? ""
		let isNewSection = newSectionTitle != lastSection

		if isNewSection {
			guard let messages = conversation?.messages
				.sorted(byKeyPath: "timestamp", ascending: true)
				.filter("shortConvertedTimestamp == %@", newSectionTitle) else { try! realm.commitWrite(); return }

			let newSection = MessageSection(messages: messages, title: newSectionTitle)
			groupedMessages.append(newSection)
			let insertionIndex = groupedMessages.count - 1 >= 0 ?  groupedMessages.count - 1 : 0
			collectionView.insertSections(IndexSet([insertionIndex]))

		} else {

		let sectionIndex = groupedMessages.count - 1 >= 0 ? groupedMessages.count - 1 : 0
		let rowIndex = groupedMessages[sectionIndex].messages.count - 1 >= 0 ?
		groupedMessages[sectionIndex].messages.count - 1 : 0

			if groupedMessages[sectionIndex].messages.indices.contains(rowIndex - 1),
				groupedMessages[sectionIndex].messages[rowIndex - 1].fromId == message.fromId,
				message.isInformationMessage.value != true {
				groupedMessages[sectionIndex].messages[rowIndex - 1].isCrooked.value = false
			}

			collectionView.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
			collectionView.reloadItems(at: [IndexPath(row: rowIndex - 1, section: sectionIndex)])
		}

		updateMessageStatus(messageRef: reference)
		try! self.realm.commitWrite()
		NotificationCenter.default.post(name: .messageSent, object: nil)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			if self.isScrollViewAtTheBottom() {
				self.collectionView.scrollToBottom(animated: true)
			}
		}
	}
}
