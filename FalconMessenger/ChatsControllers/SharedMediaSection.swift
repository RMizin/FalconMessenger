//
//  SharedMediaSection.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 2/22/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

class SharedMediaSection: Object {

	@objc var title: String?
	var sharedMedia = [SharedMedia]()
	var notificationToken: NotificationToken?

	convenience init(sharedMedia: [SharedMedia], title: String) {
		self.init()

		self.title = title
		self.sharedMedia = sharedMedia
	}
}

