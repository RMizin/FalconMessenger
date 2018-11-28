//
//  SharedMediaFetcher.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

class SharedMediaFetcher: NSObject {

	weak var delegate: SharedMediaDelegate?

	// MARK: - Photos fetcher
	fileprivate var sharedMediaURLs = [SharedMedia]()
	fileprivate var mediaGroup = DispatchGroup()
	fileprivate var pagesToLoad = 1
	

	func fetchMedia(userID: String?, chatID: String?) {

		guard let userID = userID, let chatID = chatID else { delegate?.sharedMedia(error: true); return }
		let database = Database.database().reference()
		let itemsPerPage = 500 * pagesToLoad
		pagesToLoad += 1

		let reference = database.child("user-messages").child(userID).child(chatID).child("userMessages").queryLimited(toLast: UInt(itemsPerPage))
		reference.keepSynced(true)
		reference.observeSingleEvent(of: .value) { (snapshot) in
			guard let messageIDsDictionary = snapshot.value as? [String: AnyObject] else {
				self.delegate?.sharedMedia(error: true);
				return
			}

			let messageIDs = Array(messageIDsDictionary.keys)
			self.mediaGroup = DispatchGroup()
			messageIDs.forEach({ _ in self.mediaGroup.enter() })
			self.mediaGroupNotification(previousCount: self.sharedMediaURLs.count, countToLoad: itemsPerPage, userID: userID, chatID: chatID)
			messageIDs.forEach({ (messageID) in
				self.fetchMediaMessages(messageID: messageID)
			})
		}
	}

	fileprivate func fetchMediaMessages(messageID: String) {
		let database = Database.database().reference()
		let reference = database.child("messages").child(messageID).queryOrdered(byChild: "imageUrl")
		reference.observeSingleEvent(of: .value) { (snapshot) in
			guard var messageDictionary = snapshot.value as? [String: AnyObject] else { self.mediaGroup.leave(); return }
			messageDictionary.updateValue(snapshot.key as AnyObject, forKey: "messageUID")
			let message = Message(dictionary: messageDictionary)

			guard let imageURL = message.imageUrl, let timestamp = message.timestamp, let messageID = message.messageUID else {
				self.mediaGroup.leave()
				return
			}

			if let videoURL = message.videoUrl {
				self.updateSharedMedia(messageID, imageURL, timestamp, videoURL, message.thumbnailImageUrl)
			} else {
				self.updateSharedMedia(messageID, imageURL, timestamp, nil, message.thumbnailImageUrl)
			}
		}
	}

	fileprivate func updateSharedMedia(_ id: String, _ imageURL: String, _ timestamp: NSNumber, _ videoURL: String?, _ thumbnailImageUrl: String?) {
		let sharedElement = SharedMedia(id: id,
																		imageURL: imageURL,
																		timestamp: timestamp,
																		convertedTimestamp: "",
																		videoURL: videoURL,
																		thumbnailImageUrl: thumbnailImageUrl)

		guard !sharedMediaURLs.contains(where: { (element) -> Bool in
			return element.id == id
		}) else {
			mediaGroup.leave()
			return
		}

		let date = Date(timeIntervalSince1970: TimeInterval(truncating: timestamp))
		sharedElement.shortConvertedTimestamp = date.getShortDateStringFromUTC() as String
		sharedMediaURLs.append(sharedElement)
		mediaGroup.leave()
	}

	// MARK: - Media Dispatch notification
	fileprivate func mediaGroupNotification(previousCount: Int, countToLoad: Int, userID: String, chatID: String) {




//		 if self.sharedMediaURLs.count == countToLoad {
//		//	 finish loading
//	}
//		 if self.sharedMediaURLs.count < countToLoad && self.sharedMediaURLs.count > previousCount {
//		// load one more time
//	}
//
//		 if self.sharedMediaURLs.count < countToLoad && self.sharedMediaURLs.count == previousCount {
//		// finish loading
//		}


		// если количество обновленного равно количеству нужного, то все норм
		// если количество обновленного меньше нужного, и при этом еще можно что то загрузить, то загружаем
		// если количество обновленного меньше нужного, и при этом нельзя больше загрузить, то все загружено, все норм

		mediaGroup.notify(queue: .main) {
			let groupedSharedMedia = SharedMedia.groupedSharedMedia(self.sharedMediaURLs)
			self.delegate?.sharedMedia(with: groupedSharedMedia)
		}

		/*
		mediaGroup.notify(queue: .main) {

			let isPageLoadFinished = self.sharedMediaURLs.count == countToLoad
			let shouldLoadMore = self.sharedMediaURLs.count < countToLoad
			let isAllMediaLoaded = self.sharedMediaURLs.count == previousCount


			if isPageLoadFinished {
				let groupedSharedMedia = SharedMedia.groupedSharedMedia(self.sharedMediaURLs)
				self.delegate?.sharedMedia(with: groupedSharedMedia)
				print("isPageLoadFinished")
			} else if shouldLoadMore && !isAllMediaLoaded {
//				let groupedSharedMedia = SharedMedia.groupedSharedMedia(self.sharedMediaURLs)
//				self.delegate?.sharedMedia(with: groupedSharedMedia)
				DispatchQueue.global(qos: .utility).async {
					self.fetchMedia(userID: userID, chatID: chatID)
				}

				print("should load more")
			} else {
				print("else isPageLoadFinished")
				let groupedSharedMedia = SharedMedia.groupedSharedMedia(self.sharedMediaURLs)
				self.delegate?.sharedMedia(with: groupedSharedMedia)
			}
		}*/
	}
}
