//
//  RealmCGRect.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/5/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import RealmSwift

final class RealmCGRect: Object {
	@objc dynamic var id: String?
	let x =  RealmOptional<Double>()
	let y = RealmOptional<Double>()
	let width = RealmOptional<Double>()
	let height = RealmOptional<Double>()

	override static func primaryKey() -> String? {
		return "id"
	}

	convenience init(_ cgRect: CGRect, id: String) {
		self.init()
		self.id = id
		x.value = Double(cgRect.origin.x)
		y.value = Double(cgRect.origin.y)
		width.value = Double(cgRect.size.width)
		height.value = Double(cgRect.size.height)
	}
}
