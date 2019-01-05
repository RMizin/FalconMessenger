//
//  Message.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

private func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

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

class RealmRect: Object {
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

//
//class TailedMessage: Object {
//
//	var messages: Results<Message>!
//
//	convenience init(messages: Results<Message>) {
//		self.init()
//
//		self.title = title
//		self.messages = messages
//	}
//}

class SectionedMessage: Object {

	@objc var title: String?

	var messages1: [TailedMessage]?
	var messages: Results<Message>!
	var notificationToken: NotificationToken?

	convenience init(messages: Results<Message> , title: String) {
		self.init()

		self.title = title
		self.messages = messages
	}

//	deinit {
//		print("deinits section message")
//		if notificationToken != nil {
//			notificationToken?.invalidate()
//		}
//	}
}


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

class Message: Object {

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
    let imageHeight = RealmOptional<Double>()
    let imageWidth = RealmOptional<Double>()

		@objc dynamic var localImage: RealmUIImage?
  
    @objc dynamic var localVideoUrl: String?

    @objc dynamic var voiceData: Data?
    @objc dynamic var voiceDuration: String?

    let voiceStartTime = RealmOptional<Int>()

    @objc dynamic var voiceEncodedString: String?

    @objc dynamic var videoUrl: String?
  
    @objc dynamic var estimatedFrameForText: RealmRect?

     @objc dynamic var landscapeEstimatedFrameForText: RealmRect?
  
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
					localImage = RealmUIImage(image: image, messageUID: dictionary["messageUID"] as? String ?? "")
				}

        //localImage = dictionary["localImage"] as? UIImage
        localVideoUrl = dictionary["localVideoUrl"] as? String

        voiceEncodedString = dictionary["voiceEncodedString"] as? String
        voiceData = dictionary["voiceData"] as? Data //unused
        voiceDuration = dictionary["voiceDuration"] as? String
        voiceStartTime.value = dictionary["voiceStartTime"] as? Int

				if let cgrect = dictionary["estimatedFrameForText"] as? CGRect {
					estimatedFrameForText = RealmRect(cgrect: cgrect, messageUID: dictionary["messageUID"] as? String ?? "")
				}

				if let cgrect = dictionary["landscapeEstimatedFrameForText"] as? CGRect {
					landscapeEstimatedFrameForText = RealmRect(cgrect: cgrect,
																										 messageUID: (dictionary["messageUID"] as? String ?? "") + "landscape")
				}

        imageCellHeight.value = dictionary["imageCellHeight"] as? Double
      
      //  senderName = dictionary["senderName"] as? String

        isCrooked.value = dictionary["isCrooked"] as? Bool
    }

//  static func groupedMessages(_ messages: [Message]) -> [[Message]] {
//    let grouped = Dictionary.init(grouping: messages) { (message) -> String in
//      return message.shortConvertedTimestamp ?? ""
//    }
//
//    let keys = grouped.keys.sorted { (time1, time2) -> Bool in
//      return Date.dateFromCustomString(customString: time1) <  Date.dateFromCustomString(customString: time2)
//    }
//
//    var groupedMessages = [[Message]]()
//    keys.forEach({
//      groupedMessages.append(grouped[$0]!)
//    })
//
//    return groupedMessages
//  }

  static func get(indexPathOf message: Message, in groupedArray: [SectionedMessage]) -> IndexPath? {
    guard let section = groupedArray.index(where: { (messages) -> Bool in
      for message1 in messages.messages where message1 == message {
        return true
      }; return false
    }) else { return nil }

    guard let row = groupedArray[section].messages.index(where: { (message1) -> Bool in
      return message1.messageUID == message.messageUID
    }) else { return IndexPath(row: -1, section: section) }

    return IndexPath(row: row, section: section)
  }

  static func get(indexPathOf messageUID: String? = nil , localPhoto: UIImage? = nil, in groupedArray: [SectionedMessage]) -> IndexPath? {


    if messageUID != nil {

      guard let section = groupedArray.index(where: { (messages) -> Bool in
        for message1 in messages.messages where message1.messageUID == messageUID {
          return true
        }; return false
      }) else { return nil }

      guard let row = groupedArray[section].messages.index(where: { (message1) -> Bool in
        return message1.messageUID == messageUID
      }) else { return IndexPath(row: -1, section: section) }

       return IndexPath(row: row, section: section)

    } else if localPhoto != nil {

      guard let section = groupedArray.index(where: { (messages) -> Bool in
        for message1 in messages.messages where message1.localImage == localPhoto {
          return true
        }; return false
      }) else { return nil }

      guard let row = groupedArray[section].messages.index(where: { (message1) -> Bool in
        return message1.localImage == localPhoto
      }) else { return IndexPath(row: -1, section: section) }

			return IndexPath(row: row, section: section)
    }
     return nil
  }
}

extension Date {
  static func dateFromCustomString(customString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM/yyyy"
    return dateFormatter.date(from: customString) ?? Date()
  }
}
