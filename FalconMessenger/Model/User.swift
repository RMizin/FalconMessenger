//
//  User.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/6/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import RealmSwift

final class User: Object {

	 @objc dynamic var id: String?
	 @objc dynamic var name: String?
	 @objc dynamic var bio: String?
	 @objc dynamic var photoURL: String?
	 @objc dynamic var thumbnailPhotoURL: String?
	 @objc dynamic var phoneNumber: String?
	 @objc dynamic var onlineStatusString: String?

	 var onlineStatus: AnyObject?
	 var isSelected: Bool! = false // local only
	 let onlineStatusSortDescriptor = RealmOptional<Double>()

	override static func primaryKey() -> String? {
		return "id"
	}

  convenience init(dictionary: [String: AnyObject]) {
    self.init()
    self.id = dictionary["id"] as? String
    self.name = dictionary["name"] as? String
    self.bio = dictionary["bio"] as? String
    self.photoURL = dictionary["photoURL"] as? String
    self.thumbnailPhotoURL = dictionary["thumbnailPhotoURL"] as? String
    self.phoneNumber = dictionary["phoneNumber"] as? String
    self.onlineStatus = dictionary["OnlineStatus"]
		
		self.onlineStatusString = stringStatus(onlineStatus: dictionary["OnlineStatus"])
		self.onlineStatusSortDescriptor.value = sorts(onlineStatus: dictionary["OnlineStatus"])
  }

	func sorts(onlineStatus: AnyObject?) -> Double {
		guard let onlineStatus = onlineStatus else { return 0 }
		if let statusString = onlineStatus as? String {
			if statusString == statusOnline {
				return Double.greatestFiniteMagnitude - Double.random0to1() - (id?.doubleValue ?? 0).truncatingRemainder(dividingBy: 1)
			}
		}

		if let lastSeen = onlineStatus as? TimeInterval {
			return lastSeen
		}
		return 0
	}

	func stringStatus(onlineStatus: AnyObject?) -> String? {
		guard let onlineStatus = onlineStatus else { return "" }
		if let statusString = onlineStatus as? String {
			if statusString == statusOnline {
				return statusString
			}
		}

		if let lastSeen = onlineStatus as? TimeInterval {
			let date = Date(timeIntervalSince1970: lastSeen/1000)
			let lastSeenTime = "Last seen " + timeAgoSinceDate(date)
			return lastSeenTime
		}
		return ""
	}
}

extension User { // local only
  var titleFirstLetter: String {
    guard let name = name else {return "" }
    return String(name[name.startIndex]).uppercased()
  }
}
