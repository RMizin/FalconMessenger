//
//  RealmCGRect.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/5/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

class RealmCGRect: Object {
	@objc dynamic var messageUID: String?
	let x =  RealmOptional<Double>()
	let y = RealmOptional<Double>()
	let width = RealmOptional<Double>()
	let height = RealmOptional<Double>()

	override static func primaryKey() -> String? {
		return "messageUID"
	}

	convenience init(cgrect: CGRect, messageUID: String) {
		self.init()
		self.messageUID = messageUID
		x.value = Double(cgrect.origin.x)
		y.value = Double(cgrect.origin.y)
		width.value = Double(cgrect.size.width)
		height.value = Double(cgrect.size.height)
	}
}
