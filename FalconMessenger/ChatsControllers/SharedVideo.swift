//
//  SharedVideo.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SharedVideo: NSObject {

	var videoURL: String?
	var thumbnailURL: String?

	var timestamp: NSNumber? {
		didSet {
			setupConvertedTimestamp()
		}
	}
	
	var shortConvertedTimestamp: String? //local only

	init(thumbnailURL: String, videoURL: String, timestamp: NSNumber) {
		super.init()
		self.videoURL = videoURL
		self.thumbnailURL = thumbnailURL

		self.timestamp = timestamp
	}

	fileprivate func setupConvertedTimestamp() {
		guard let timestamp = timestamp else { return }
		let date = Date(timeIntervalSince1970: TimeInterval(truncating: timestamp))
		shortConvertedTimestamp = date.getShortDateStringFromUTC() as String
	}

	static func groupedSharedVideos(_ sharedVideos: [SharedVideo]) -> [[SharedVideo]] {
		let grouped = Dictionary.init(grouping: sharedVideos) { (sharedVideo) -> String in
			return sharedVideo.shortConvertedTimestamp ?? ""
		}

		let keys = grouped.keys.sorted { (time1, time2) -> Bool in
			return Date.dateFromCustomString(customString: time1) <  Date.dateFromCustomString(customString: time2)
		}

		var groupedSharedVideos = [[SharedVideo]]()
		keys.forEach({
			groupedSharedVideos.append(grouped[$0]!)
		})

		return groupedSharedVideos
	}
}
