//
//  RealmUIImage.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/5/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

class RealmImage: Object {

	@objc dynamic var messageUID: String?
	@objc dynamic var image: Data?

	func uiImage() -> UIImage? {
		guard let data = image else { return blurredPlaceholder }
		return UIImage(data: data)
	}

	convenience init(image: UIImage, quality: CGFloat, messageUID: String) {
		self.init()
		self.messageUID = messageUID

		if quality < 1.0 {
			self.image = image.jpegData(compressionQuality: quality)
		} else {
			self.image = image.pngData()
		}
	}

	override static func primaryKey() -> String? {
		return "messageUID"
	}
}
