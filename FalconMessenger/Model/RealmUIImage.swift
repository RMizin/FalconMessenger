//
//  RealmUIImage.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/5/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

class RealmUIImage: Object {

	@objc dynamic var messageUID: String?
	@objc dynamic var image: Data?

	convenience init(image: UIImage, messageUID: String) {
		self.init()
		self.messageUID = messageUID
		self.image = image.jpegData(compressionQuality: 0.5)
	}

	override static func primaryKey() -> String? {
		return "messageUID"
	}
}
