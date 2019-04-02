//
//  MessageSection.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/5/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import RealmSwift

final class MessageSection: Object {

	@objc var title: String?
	var messages: Results<Message>!
	var notificationToken: NotificationToken?

	convenience init(messages: Results<Message>, title: String) {
		self.init()

		self.title = title
		self.messages = messages
	}
}
