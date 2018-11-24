//
//  SharedPhoto.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SharedPhoto: NSObject {

	var imageURL: String?
	var timestamp: NSNumber?
	var shortConvertedTimestamp: String? //local only

	init(imageURL: String, timestamp: NSNumber, convertedTimestamp: String) {
		super.init()
		self.imageURL = imageURL
		self.timestamp = timestamp
		self.shortConvertedTimestamp = convertedTimestamp
	}

	static func groupedSharedPhotos(_ sharedPhotos: [SharedPhoto]) -> [[SharedPhoto]] {
		let grouped = Dictionary.init(grouping: sharedPhotos) { (sharedPhoto) -> String in
			return sharedPhoto.shortConvertedTimestamp ?? ""
		}

		let keys = grouped.keys.sorted { (time1, time2) -> Bool in
			return Date.dateFromCustomString(customString: time1) > Date.dateFromCustomString(customString: time2)
		}

		var groupedSharedPhotos = [[SharedPhoto]]()
		keys.forEach({
			groupedSharedPhotos.append(grouped[$0]!)
		})

		return groupedSharedPhotos
	}
}
