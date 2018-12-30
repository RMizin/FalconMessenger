//
//  SharedPhoto.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SharedMedia: NSObject {

	var id: String?
	var imageURL: String?
	var thumbnailImageUrl: String?
	var videoURL: String?
	var timestamp: Int64?
	var shortConvertedTimestamp: String? //local only
	var image: UIImage? //local only
	var thumbnailImage: UIImage? //local only

	init(id: String, imageURL: String, timestamp: Int64, convertedTimestamp: String, videoURL: String?, thumbnailImageUrl: String?) {
		super.init()
		self.id = id
		self.imageURL = imageURL
		self.timestamp = timestamp
		self.shortConvertedTimestamp = convertedTimestamp
		self.videoURL = videoURL
		self.thumbnailImageUrl = thumbnailImageUrl
	}

	static func groupedSharedMedia(_ sharedMedia: [SharedMedia]) -> [[SharedMedia]] {

		let sorted = sharedMedia.sorted { (media1, media2) -> Bool in
			return (media1.id ?? "") > (media2.id ?? "")
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
		guard let section = groupedArray.index(where: { (messages) -> Bool in
			for message1 in messages where message1.id == message.messageUID {
				return true
			}; return false
		}) else { return nil }

		guard let row = groupedArray[section].index(where: { (message1) -> Bool in
			return message1.id == message.messageUID
		}) else { return IndexPath(row: -1, section: section) }

		return IndexPath(row: row, section: section)
	}
}
