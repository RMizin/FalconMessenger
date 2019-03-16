//
//  AppearanceExampleMessagesFactory.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 3/16/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

final class AppearanceExampleMessagesFactory {

	static func messages() -> [Message] {
		guard let currentUID = Auth.auth().currentUser?.uid else { return [Message]() }

		let messagesFetcher = MessagesFetcher()
		let messageUID = "1"
		let timestamp: Int64 = 1238924237489
		let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
		let convertedTimestamp = timestampOfChatLogMessage(date) as AnyObject
		let shortConvertedTimestamp = date.getShortDateStringFromUTC() as AnyObject
		let outgoingMessageText = "You can store text, photos, videos and voice messages in the cloud, by sending them to your personal storage."
		let outgoingRect = RealmCGRect(messagesFetcher.estimateFrameForText(outgoingMessageText, orientation: .portrait), id: messageUID)
		let outgoingLRect = RealmCGRect(messagesFetcher.estimateFrameForText(outgoingMessageText, orientation: .landscapeLeft),
																		id: messageUID + "landscape")

		let outgoingMessageDictionary: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
																													"fromId": currentUID as AnyObject,
																													"toId": "2" as AnyObject,
																													"text": outgoingMessageText as AnyObject,
																													"timestamp": timestamp as AnyObject,
																													"convertedTimestamp": convertedTimestamp,
																													"shortConvertedTimestamp": shortConvertedTimestamp,
																													"estimatedFrameForText": outgoingRect,
																													"landscapeEstimatedFrameForText": outgoingLRect]

		let incomingMessageText = "Falcon Messenger is a fast and beautiful cloud-based messaging app. App based on this repository is available on the App Store."
		let incomingRect = RealmCGRect(messagesFetcher.estimateFrameForText(outgoingMessageText, orientation: .portrait), id: messageUID + "1")
		let incomingLRect = RealmCGRect(messagesFetcher.estimateFrameForText(outgoingMessageText, orientation: .landscapeLeft),
																		id: messageUID + "1" + "landscape")

		let incomingMessageDictionary: [String: AnyObject] = ["messageUID": messageUID + "1" as AnyObject,
																													"fromId": currentUID + "1" as AnyObject,
																													"toId": currentUID as AnyObject,
																													"text": incomingMessageText as AnyObject,
																													"timestamp": timestamp as AnyObject,
																													"convertedTimestamp": convertedTimestamp,
																													"shortConvertedTimestamp": shortConvertedTimestamp,
																													"estimatedFrameForText": incomingRect,
																													"landscapeEstimatedFrameForText": incomingLRect]

		let incomingMessage = Message(dictionary: incomingMessageDictionary)
		let outgoingMessage = Message(dictionary: outgoingMessageDictionary)

		return [incomingMessage, outgoingMessage]
	}
}
