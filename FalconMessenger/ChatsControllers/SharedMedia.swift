//
//  SharedPhoto.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

class SharedMedia: Object {

	@objc dynamic var id: String?
	@objc dynamic var imageURL: String?
	@objc dynamic var thumbnailImageUrl: String?
	@objc dynamic var videoURL: String?
	@objc dynamic var shortConvertedTimestamp: String? //local only
	@objc dynamic var conversation: Conversation?// = nil
	let timestamp = RealmOptional<Int64>()
	var image: UIImage?
	var thumbnailImage: UIImage?

	override static func primaryKey() -> String? {
		return "id"
	}

	convenience init(id: String, imageURL: String, timestamp: Int64, convertedTimestamp: String, videoURL: String?, thumbnailImageUrl: String?) {
		self.init()
		self.id = id
		self.imageURL = imageURL
		self.timestamp.value = timestamp
		self.shortConvertedTimestamp = convertedTimestamp
		self.videoURL = videoURL
		self.thumbnailImageUrl = thumbnailImageUrl
	}

	static func groupedSharedMedia(_ sharedMedia: [SharedMedia]) -> [[SharedMedia]] {
		let sorted = sharedMedia.sorted { (media1, media2) -> Bool in
			return media1.id ?? "" > media2.id ?? ""
		}

		let grouped = Dictionary.init(grouping: sorted) { (sharedElement) -> String in
			return sharedElement.shortConvertedTimestamp ?? ""
		}

		let keys = grouped.keys.sorted { (time1, time2) -> Bool in
			return Date.dateFromCustomString(customString: time1) > Date.dateFromCustomString(customString: time2)
		}

		var groupedSharedMedia = [[SharedMedia]]()
		keys.forEach({
			groupedSharedMedia.append(grouped[$0]!)
		})

		return groupedSharedMedia
	}

	static func get(indexPathOf message: INSPhotoViewable, in groupedArray: [[SharedMedia]]) -> IndexPath? {
		guard let section = groupedArray.firstIndex(where: { (messages) -> Bool in
			for message1 in messages where message1.id == message.messageUID {
				return true
			}; return false
		}) else { return nil }

		guard let row = groupedArray[section].firstIndex(where: { (message1) -> Bool in
			return message1.id == message.messageUID
		}) else { return IndexPath(row: -1, section: section) }

		return IndexPath(row: row, section: section)
	}

//	static func get(indexPathOf message: INSPhotoViewable, in groupedArray: [SharedMediaSection]) -> IndexPath? {
//		guard let section = groupedArray.index(where: { (messages) -> Bool in
//			for message1 in messages.sharedMedia where message1.id == message.messageUID {
//				return true
//			}; return false
//		}) else { return nil }
//
//		guard let row = groupedArray[section].sharedMedia.index(where: { (message1) -> Bool in
//			return message1.id == message.messageUID
//		}) else { return IndexPath(row: -1, section: section) }
//
//		return IndexPath(row: row, section: section)
//	}
}
