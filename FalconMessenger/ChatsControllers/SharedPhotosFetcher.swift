//
//  SharedPhotosFetcher.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

class SharedPhotosFetcher: NSObject {

	weak var delegate: SharedMediaDelegate?

	// MARK: - Photos fetcher
	fileprivate var sharedPhotosURLs = [SharedPhoto]()
	fileprivate var photosGroup = DispatchGroup()

	func fetchPhotos(userID: String?, chatID: String?, page: Int = 1) {
		guard let userID = userID, let chatID = chatID else { return }
		let database = Database.database().reference()
		let itemsPerPage = 50 * page

		let reference = database.child("user-messages").child(userID).child(chatID).child("userMessages").queryLimited(toLast: UInt(itemsPerPage))
		reference.keepSynced(true)
		reference.observeSingleEvent(of: .value) { (snapshot) in
			guard let messageIDsDictionary = snapshot.value as? [String: AnyObject] else { return }

			let messageIDs = Array(messageIDsDictionary.keys)

			self.photosGroup = DispatchGroup()
			messageIDs.forEach({ _ in self.photosGroup.enter() })
			self.photosGroupNotification()
			messageIDs.forEach({ (messageID) in
				self.fetchPhotoMessages(messageID: messageID)
			})
		}
	}

	fileprivate func fetchPhotoMessages(messageID: String) {
		let database = Database.database().reference()
		let reference = database.child("messages").child(messageID).queryOrdered(byChild: "imageUrl")
		reference.observeSingleEvent(of: .value) { (snapshot) in
			guard let message = snapshot.value as? [String: AnyObject] else { self.photosGroup.leave(); return }
			guard let imageURL = message["imageUrl"] as? String, let timestamp = message["timestamp"] as? NSNumber else {
				self.photosGroup.leave()
				return
			}

			self.updateSharedPhotos(imageURL: imageURL, timestamp: timestamp)
		}
	}

	fileprivate func updateSharedPhotos(imageURL: String, timestamp: NSNumber) {
		let sharedPhoto = SharedPhoto(imageURL: imageURL, timestamp: timestamp, convertedTimestamp: "")
		guard !sharedPhotosURLs.contains(sharedPhoto) else { return }
		let date = Date(timeIntervalSince1970: TimeInterval(truncating: timestamp))
		sharedPhoto.shortConvertedTimestamp = date.getShortDateStringFromUTC() as String
		sharedPhotosURLs.append(sharedPhoto)
		photosGroup.leave()
	}

	// MARK: - Photo Dispatch notification
	fileprivate func photosGroupNotification() {
		photosGroup.notify(queue: .main) {
			print("Photos fetching finished")
			let groupedSharedPhotos = SharedPhoto.groupedSharedPhotos(self.sharedPhotosURLs)
			self.delegate?.sharedPhotos(with: groupedSharedPhotos)
		}
	}
}

