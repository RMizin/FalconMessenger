//
//  Message.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import Firebase
import RealmSwift

struct MessageSubtitle {
  static let video = "Attachment: Video"
  static let image = "Attachment: Image"
  static let audio = "Audio message"
  static let empty = "No messages here yet."
}

enum MessageType {
  case textMessage
  case photoMessage
  case videoMessage
  case voiceMessage
  case sendingMessage
}

let defaultMessage = Message(dictionary: ["timestamp": 0 as AnyObject])

final class Message: Object {

    @objc dynamic var messageUID: String?

    let isInformationMessage = RealmOptional<Bool>()

    @objc dynamic var fromId: String?
    @objc dynamic var text: String?
    @objc dynamic var toId: String?
    let timestamp = RealmOptional<Int64>()
    @objc dynamic var convertedTimestamp: String? // local only
    @objc dynamic var shortConvertedTimestamp: String? //local only
  
    @objc dynamic var status: String?
    let seen = RealmOptional<Bool>()

    @objc dynamic var imageUrl: String?
	 	@objc dynamic var thumbnailImageUrl: String?
	 	@objc dynamic var thumbnailImage: RealmImage?
    let imageHeight = RealmOptional<Double>()
    let imageWidth = RealmOptional<Double>()

		@objc dynamic var localImage: RealmImage?
    @objc dynamic var localVideoUrl: String?
		@objc dynamic var localVideoIdentifier: String?
    @objc dynamic var voiceData: Data?
    @objc dynamic var voiceDuration: String?

    let voiceStartTime = RealmOptional<Int>()

    @objc dynamic var voiceEncodedString: String?
    @objc dynamic var videoUrl: String?
    @objc dynamic var estimatedFrameForText: RealmCGRect?
		@objc dynamic var landscapeEstimatedFrameForText: RealmCGRect?
  
		let imageCellHeight = RealmOptional<Double>()
    let isCrooked = RealmOptional<Bool>() // local only

    @objc dynamic var senderName: String? //local only, group messages only
		@objc dynamic var conversation: Conversation?// = nil


    func chatPartnerId() -> String? {
			return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }

		override static func primaryKey() -> String? {
			return "messageUID"
		}
  
    convenience init(dictionary: [String: AnyObject]) {
        self.init()

        messageUID = dictionary["messageUID"] as? String
        isInformationMessage.value = dictionary["isInformationMessage"] as? Bool
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        toId = dictionary["toId"] as? String
        timestamp.value = dictionary["timestamp"] as? Int64

        convertedTimestamp = dictionary["convertedTimestamp"] as? String
        shortConvertedTimestamp = dictionary["shortConvertedTimestamp"] as? String

        status = dictionary["status"] as? String
        seen.value = dictionary["seen"] as? Bool

        imageUrl = dictionary["imageUrl"] as? String
				thumbnailImageUrl = dictionary["thumbnailImageUrl"] as? String
        imageHeight.value = dictionary["imageHeight"] as? Double
        imageWidth.value = dictionary["imageWidth"] as? Double

        videoUrl = dictionary["videoUrl"] as? String

				if let image = dictionary["localImage"] as? UIImage {
					localImage = RealmImage(image, quality: 0.5, id: dictionary["messageUID"] as? String ?? "")
				}

				if let thumbnail = realm?.object(ofType: RealmImage.self, forPrimaryKey: (dictionary["messageUID"] as? String ?? "") + "thumbnail") {
					thumbnailImage = thumbnail
				}

        localVideoUrl = dictionary["localVideoUrl"] as? String
			  localVideoIdentifier = dictionary["localVideoIdentifier"] as? String

        voiceEncodedString = dictionary["voiceEncodedString"] as? String
        voiceData = dictionary["voiceData"] as? Data //unused
        voiceDuration = dictionary["voiceDuration"] as? String
        voiceStartTime.value = dictionary["voiceStartTime"] as? Int

				estimatedFrameForText = dictionary["estimatedFrameForText"] as? RealmCGRect
				landscapeEstimatedFrameForText = dictionary["landscapeEstimatedFrameForText"] as? RealmCGRect
        imageCellHeight.value = dictionary["imageCellHeight"] as? Double
    }

	static func get(indexPathOf message: Message, in groupedArray: [MessageSection]) -> IndexPath? {
		guard let section = groupedArray.firstIndex(where: { (messages) -> Bool in
			for message1 in messages.messages where message1.messageUID == message.messageUID {
				return true
			}; return false
		}) else { return nil }

		guard let row = groupedArray[section].messages.firstIndex(where: { (message1) -> Bool in
			return message1.messageUID == message.messageUID
		}) else { return nil }

		return IndexPath(row: row, section: section)
	}

  static func get(indexPathOf messageUID: String? = nil , localPhoto: UIImage? = nil, in groupedArray: [MessageSection]?) -> IndexPath? {
		guard let groupedArray = groupedArray else { return nil }
    if messageUID != nil {
			guard let section = groupedArray.firstIndex(where: { (messages) -> Bool in
        for message1 in messages.messages where message1.messageUID == messageUID {
          return true
        }; return false
      }) else { return nil }

			guard let row = groupedArray[section].messages.firstIndex(where: { (message1) -> Bool in
        return message1.messageUID == messageUID
      }) else { return nil }

       return IndexPath(row: row, section: section)

    } else if localPhoto != nil {

			guard let section = groupedArray.firstIndex(where: { (messages) -> Bool in
        for message1 in messages.messages where message1.localImage == localPhoto {
          return true
        }; return false
      }) else { return nil }

			guard let row = groupedArray[section].messages.firstIndex(where: { (message1) -> Bool in
        return message1.localImage == localPhoto
      }) else { return nil }

			return IndexPath(row: row, section: section)
    }
     return nil
  }
}
