//
//  SharedMediaHistoryFetcher.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/29/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

class SharedMediaHistoryFetcher: NSObject {
	weak var delegate: SharedMediaHistoryDelegate?

	fileprivate var loadingGroup = DispatchGroup()
	fileprivate let messagesToLoad = 50
	fileprivate var loadedMessages = 0
	fileprivate var currentPage = 1

	var fetchingData: (userID: String, chatID: String)?

	public func loadPreviousMedia(_ fetchingData: (userID: String, chatID: String)?) {
		self.fetchingData = fetchingData
		loadChatHistory()
	}

	private func loadChatHistory() {
		guard let currentUserID = fetchingData?.userID, let conversationID = fetchingData?.chatID else { print("returningg"); return }
		getFirstID(currentUserID, conversationID)
	}

	fileprivate func checkExistence(reference: DatabaseReference, completion: @escaping () -> Void) {
		reference.observeSingleEvent(of: .value) { (snapshot) in
			if !snapshot.exists() {
				self.delegate?.sharedMediaHistory(isEmpty: true)
			} else {
				self.delegate?.sharedMediaHistory(isEmpty: false)
				completion()
			}
		}
	}

	fileprivate func getFirstID(_ currentUserID: String, _ conversationID: String) {
		let firstIDReference = Database.database().reference().child("user-messages")
			.child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder)

		checkExistence(reference: firstIDReference) {
			findFirstID()
		}

		func findFirstID() {
			let numberOfMessagesToLoad = messagesToLoad * currentPage
			let firstIDQuery = firstIDReference.queryLimited(toLast: UInt(numberOfMessagesToLoad))
			firstIDQuery.observeSingleEvent(of: .childAdded, with: { (snapshot) in
				let firstID = snapshot.key
				self.getLastID(firstID, currentUserID, conversationID)
			})
		}
	}

	fileprivate func getLastID(_ firstID: String, _ currentUserID: String, _ conversationID: String) {
		let nextMessageIndex = loadedMessages + 1
		let lastIDReference = Database.database().reference().child("user-messages")
			.child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder)
		let lastIDQuery = lastIDReference.queryLimited(toLast: UInt(nextMessageIndex))

		lastIDQuery.observeSingleEvent(of: .childAdded, with: { (snapshot) in
			let lastID = snapshot.key

			if (firstID == lastID) {
				self.delegate?.sharedMediaHistory(allLoaded: true)
				return
			}

			self.getRange(firstID, lastID, currentUserID, conversationID)
		})
	}

	fileprivate func getRange(_ firstID: String, _ lastID: String, _ currentUserID: String, _ conversationID: String) {
		let rangeReference = Database.database().reference().child("user-messages")
			.child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder)
		let rangeQuery = rangeReference.queryOrderedByKey().queryStarting(atValue: firstID).queryEnding(atValue: lastID)

		rangeQuery.observeSingleEvent(of: .value, with: { (snapshot) in
			for _ in 0 ..< snapshot.childrenCount { self.loadingGroup.enter() }
			self.notifyWhenGroupFinished(query: rangeQuery)
			self.getMessages(from: rangeQuery)
		})
	}

	fileprivate var userMessageHande: DatabaseHandle!
	fileprivate var previousMedia = [SharedMedia]()

	fileprivate func getMessages(from query: DatabaseQuery) {
		self.previousMedia = [SharedMedia]()
		self.userMessageHande = query.observe(.childAdded, with: { (snapshot) in
			let messageUID = snapshot.key
			self.getMetadata(fromMessageWith: messageUID)
		})
	}

	fileprivate func getMetadata(fromMessageWith messageUID: String) {
		let reference = Database.database().reference().child("messages").child(messageUID)

		reference.observeSingleEvent(of: .value, with: { (snapshot) in
			guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
			dictionary.updateValue(messageUID as AnyObject, forKey: "messageUID")
			let message = Message(dictionary: dictionary)

			guard let messageID = message.messageUID, let timestamp = message.timestamp else {
				return
			}

			if let imageURL = message.imageUrl {
				let thumbnailImageUrl = message.thumbnailImageUrl ?? nil
				let videoURL = message.videoUrl ?? nil
				let date = Date(timeIntervalSince1970: TimeInterval(truncating: timestamp))
				let shortTimestamp = date.getShortDateStringFromUTC() as String

				let sharedElement = SharedMedia(id: messageID,
																				imageURL: imageURL,
																				timestamp: timestamp,
																				convertedTimestamp: shortTimestamp,
																				videoURL: videoURL,
																				thumbnailImageUrl: thumbnailImageUrl)
				self.previousMedia.append(sharedElement)
				self.loadingGroup.leave()
			} else {
				self.loadingGroup.leave()
			}
		})
	}

	fileprivate var sharedMediaToSend = [SharedMedia]()
	fileprivate var currentMediaPage = 1

	fileprivate func notifyWhenGroupFinished(query: DatabaseQuery) {
		loadingGroup.notify(queue: DispatchQueue.main, execute: {
			query.removeObserver(withHandle: self.userMessageHande)
			self.sharedMediaToSend.append(contentsOf: self.previousMedia)
			self.currentPage += 1
			self.loadedMessages += 50

			if self.sharedMediaToSend.count < self.messagesToLoad * self.currentMediaPage {
				self.loadChatHistory()
			} else {
				self.currentMediaPage += 1
			}
			self.delegate?.sharedMediaHistory(updated: self.previousMedia)
		})
	}
}
