//
//  MessageSender.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos

protocol MessageSenderDelegate: class {
  func update(with arrayOfvalues: [[String: AnyObject]])
  func update(mediaSending progress: Double, animated: Bool)
}

class MessageSender: NSObject {

  fileprivate let storageUploader = StorageMediaUploader()
  fileprivate var conversation: Conversation?
  fileprivate var attachedMedia = [MediaObject]()
  fileprivate var text: String?


	fileprivate var dataToUpdate = [[String: AnyObject]]()

  weak var delegate: MessageSenderDelegate?
  
  init(_ conversation: Conversation?, text: String?, media: [MediaObject]) {
    self.conversation = conversation
    self.text = text
    self.attachedMedia = media    
  }
  
  public func sendMessage() {
    syncronizeMediaSending()
    sendTextMessage()
    attachedMedia.forEach { (mediaObject) in
      let isVoiceMessage = mediaObject.audioObject != nil
      let isPhotoMessage = (mediaObject.phAsset?.mediaType == PHAssetMediaType.image || mediaObject.phAsset == nil) && mediaObject.audioObject == nil && mediaObject.localVideoURL == nil
      let isVideoMessage = mediaObject.phAsset?.mediaType == PHAssetMediaType.video || mediaObject.localVideoURL != nil
      
      if isVoiceMessage {
        sendVoiceMessage(object: mediaObject)
      } else if isPhotoMessage {
        sendPhotoMessage(object: mediaObject)
      } else if isVideoMessage {
        sendVideoMessage(object: mediaObject)
      }
    }
  }
  
  fileprivate var mediaUploadGroup = DispatchGroup()
	fileprivate var localUpdateGroup = DispatchGroup()

  fileprivate var mediaCount = CGFloat()
  fileprivate var mediaToSend = [(values: [String: AnyObject], reference: DatabaseReference)]()
  fileprivate var progress = [UploadProgress]()
  
  fileprivate func syncronizeMediaSending() {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid else { return }
    mediaUploadGroup = DispatchGroup()
		localUpdateGroup = DispatchGroup()
    mediaCount = CGFloat()
    mediaToSend.removeAll()
    progress.removeAll()

    
    mediaUploadGroup.enter() // for text message
		localUpdateGroup.enter()

    mediaCount += 1 // for text message
    
    attachedMedia.forEach { (media) in
      mediaUploadGroup.enter()
			localUpdateGroup.enter()
			mediaCount += 1
    }

		localUpdateGroup.notify(queue: .main) {
			self.delegate?.update(with: self.dataToUpdate)
			self.dataToUpdate.removeAll()
		}

    mediaUploadGroup.notify(queue: .global(qos: .default), execute: {
      self.mediaToSend.forEach({ (element) in
				self.updateDatabase(at: element.reference, with: element.values, toID: toID, fromID: fromID)
      })
    })
  }
 
  // MARK: TEXT MESSAGE
  fileprivate func sendTextMessage() {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid, let text = self.text else {
      self.mediaCount -= 1
      self.mediaUploadGroup.leave()
			self.localUpdateGroup.leave()
      return
    }
    
    guard text != "" else {
      self.mediaCount -= 1
      self.mediaUploadGroup.leave()
			self.localUpdateGroup.leave()
      return
    }
   
    let reference = Database.database().reference().child("messages").childByAutoId()
    
		guard let messageUID = reference.key else { return }
    let messageStatus = messageStatusDelivered
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    
    let defaultData: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
                                            "toId": toID as AnyObject,
                                            "status": messageStatus as AnyObject,
                                            "seen": false as AnyObject,
                                            "fromId": fromID as AnyObject,
                                            "timestamp": timestamp,
                                            "text": text as AnyObject]

		dataToUpdate.append(defaultData)
		self.localUpdateGroup.leave()

   // delegate?.update(with: defaultData)
    self.mediaToSend.append((values: defaultData, reference: reference))
    self.mediaUploadGroup.leave()


    self.progress.setProgress(1.0, id: messageUID)
    self.updateProgress(self.progress, mediaCount: self.mediaCount)
  }
  
  // MARK: PHOTO MESSAGE
  fileprivate func sendPhotoMessage(object: MediaObject) {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid else {
      self.mediaUploadGroup.leave()
			self.localUpdateGroup.leave()
      return
    }
   
    let reference = Database.database().reference().child("messages").childByAutoId()
		guard let messageUID = reference.key else { return }
    let messageStatus = messageStatusDelivered
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    
    let defaultData: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
                                           "toId": toID as AnyObject,
                                           "status": messageStatus as AnyObject,
                                           "seen": false as AnyObject,
                                           "fromId": fromID as AnyObject,
                                           "timestamp": timestamp,
                                           "imageWidth": object.object!.asUIImage!.size.width as AnyObject,
                                           "imageHeight": object.object!.asUIImage!.size.height as AnyObject]

    var localData: [String: AnyObject] = ["localImage": object.object!.asUIImage!]
		defaultData.forEach({ localData[$0] = $1 })



    //delegate?.update(with: localData)
		dataToUpdate.append(localData)
		localUpdateGroup.leave()


		storageUploader.uploadThumbnail(createImageThumbnail(object.object!.asUIImage!), progress: { (snapshot) in
//			if let progressCount = snapshot?.progress?.fractionCompleted {
//
//				self.progress.setProgress(progressCount * 0.98, id: messageUID)
//				self.updateProgress(self.progress, mediaCount: self.mediaCount)
//			}
		}) { (thumbnailImageUrl) in
			self.uploadOriginalImage(object: object,
															 defaultData: defaultData,
															 messageUID: messageUID,
															 reference: reference,
															 thumbnailImageUrl: thumbnailImageUrl)
		}
  }

	fileprivate func uploadOriginalImage(object: MediaObject,
																			 defaultData: [String: AnyObject],
																			 messageUID: String,
																			 reference: DatabaseReference,
																			 thumbnailImageUrl: String) {
		storageUploader.upload(object.object!.asUIImage!, progress: { (snapshot) in

			if let progressCount = snapshot?.progress?.fractionCompleted {

				self.progress.setProgress(progressCount * 0.98, id: messageUID)
				self.updateProgress(self.progress, mediaCount: self.mediaCount)
			}

		}) { (imageURL) in
			self.progress.setProgress(1.0, id: messageUID)
			self.updateProgress(self.progress, mediaCount: self.mediaCount)
			var remoteData: [String: AnyObject] = ["imageUrl": imageURL as AnyObject,
																						 "thumbnailImageUrl": thumbnailImageUrl as AnyObject]
			defaultData.forEach({ remoteData[$0] = $1 })

			self.mediaToSend.append((values: remoteData, reference: reference))
			self.mediaUploadGroup.leave()
		}
	}
  
  // MARK: VIDEO MESSAGE
  fileprivate func sendVideoMessage(object: MediaObject) {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid, let path = object.fileURL else {
      self.mediaUploadGroup.leave()
			self.localUpdateGroup.leave()
      return
    }
  
    let reference = Database.database().reference().child("messages").childByAutoId()
    
		guard let messageUID = reference.key else { return }
	//	guard let imageIDKey = reference.key else { return }
    let messageStatus = messageStatusDelivered
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))

    let videoID = messageUID
    let imageID = messageUID + "image"

    let defaultData: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
                                            "toId": toID as AnyObject,
                                            "status": messageStatus as AnyObject,
                                            "seen": false as AnyObject,
                                            "fromId": fromID as AnyObject,
                                            "timestamp": timestamp,
                                            "imageWidth": object.object!.asUIImage!.size.width as AnyObject,
                                            "imageHeight": object.object!.asUIImage!.size.height as AnyObject]

		var localData: [String: AnyObject] =  ["localImage": object.object!.asUIImage!,
																					 "localVideoUrl": path as AnyObject,
																					 "localVideoIdentifier": object.phAsset?.localIdentifier as AnyObject]
    defaultData.forEach({ localData[$0] = $1 })

   // delegate?.update(with: localData)
		dataToUpdate.append(localData)
		self.localUpdateGroup.leave()

    storageUploader.upload(object.videoObject!, progress: { [unowned self] (snapshot) in
      if let progressCount = snapshot?.progress?.fractionCompleted {
       self.progress.setProgress(progressCount * 0.98, id: videoID)
       self.updateProgress(self.progress, mediaCount: self.mediaCount)
      }
    }) { (videoURL) in
      self.progress.setProgress(1.0, id: messageUID)
      self.updateProgress(self.progress, mediaCount: self.mediaCount)
		self.storageUploader.uploadThumbnail(createImageThumbnail(object.object!.asUIImage!), progress: { (snapshot) in
//				if let progressCount = snapshot?.progress?.fractionCompleted {
//
//					self.progress.setProgress(progressCount * 0.98, id: messageUID)
//					self.updateProgress(self.progress, mediaCount: self.mediaCount)
//				}
			}) { (thumbnailImageUrl) in
				self.uploadVideoPreviewImage(object: object,
																defaultData: defaultData,
																messageUID: messageUID,
																reference: reference,
																thumbnailImageUrl: thumbnailImageUrl,
																imageID: imageID, videoURL: videoURL)
			}
    }
  }

	fileprivate func uploadVideoPreviewImage(object: MediaObject,
																					 defaultData: [String: AnyObject],
																					 messageUID: String,
																					 reference: DatabaseReference,
																					 thumbnailImageUrl: String, imageID: String,
																					 videoURL: String) {

		storageUploader.upload(object.object!.asUIImage!, progress: { [unowned self] (snapshot) in

			if let progressCount = snapshot?.progress?.fractionCompleted {
				self.progress.setProgress(progressCount * 0.98, id: imageID)
				self.updateProgress(self.progress, mediaCount: self.mediaCount)
			}
			}, completion: { (imageURL) in
				self.progress.setProgress(1.0, id: messageUID)
				self.updateProgress(self.progress, mediaCount: self.mediaCount)

				var remoteData: [String: AnyObject] = ["imageUrl": imageURL as AnyObject,
																							 "videoUrl": videoURL as AnyObject,
																							 "thumbnailImageUrl": thumbnailImageUrl as AnyObject]
				defaultData.forEach({ remoteData[$0] = $1 })

				self.mediaToSend.append((values: remoteData, reference: reference))
				self.mediaUploadGroup.leave()
		})
	}



  // MARK: VOICE MESSAGE
  fileprivate func sendVoiceMessage(object: MediaObject) {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid else {
      self.mediaUploadGroup.leave()
			self.localUpdateGroup.leave()
      return
    }

    let reference = Database.database().reference().child("messages").childByAutoId()
    
		guard let messageUID = reference.key else { return }
    let messageStatus = messageStatusDelivered
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    let bae64string = object.audioObject?.base64EncodedString()

    let defaultData: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
                                            "toId": toID as AnyObject,
                                            "status": messageStatus as AnyObject,
                                            "seen": false as AnyObject,
                                            "fromId": fromID as AnyObject,
                                            "timestamp": timestamp,
                                            "voiceEncodedString": bae64string as AnyObject]
   // delegate?.update(with: defaultData)
		dataToUpdate.append(defaultData)
		self.localUpdateGroup.leave()

    mediaToSend.append((values: defaultData, reference: reference))
    mediaUploadGroup.leave()
    progress.setProgress(1.0, id: messageUID)
    updateProgress(progress, mediaCount: mediaCount)
  }
  
  fileprivate func updateProgress(_ array: [UploadProgress], mediaCount: CGFloat) {
    let totalProgressArray = array.map({$0.progress})
    let completedUploadsCount = totalProgressArray.reduce(0, +)
    let progress = completedUploadsCount/Double(mediaCount)
    
    delegate?.update(mediaSending: progress, animated: true)

    guard progress >= 0.99999 else { return }
    self.delegate?.update(mediaSending: 0.0, animated: false)
  }

  fileprivate func updateDatabase(at reference: DatabaseReference, with values: [String: AnyObject], toID: String, fromID: String) {

    reference.updateChildValues(values) { (error, _) in
			guard let messageID = reference.key else { return }

      if let isGroupChat = self.conversation?.isGroupChat.value, isGroupChat {

        let groupMessagesRef = Database.database().reference().child("groupChats").child(toID).child(userMessagesFirebaseFolder)
        groupMessagesRef.updateChildValues([messageID: fromID])

        // needed to update ui for current user as fast as possible
        //for other members this update handled by backend
        let userMessagesRef = Database.database().reference().child("user-messages").child(fromID).child(toID).child(userMessagesFirebaseFolder)
        userMessagesRef.updateChildValues([messageID: fromID])
				//userMessagesRef.database.purgeOutstandingWrites()

				//userMessagesRef.database.purgeOutstandingWrites()

        // incrementing badge for group chats handled by backend, to reduce number of write operations from device
        self.updateGroupLastMessage()
      } else {

        let userMessagesRef = Database.database().reference().child("user-messages").child(fromID).child(toID).child(userMessagesFirebaseFolder)
       // userMessagesRef.updateChildValues([messageID: fromID])
				userMessagesRef.updateChildValues([messageID: fromID], withCompletionBlock: { (error, reference) in
					guard error == nil else { print("Updating error"); return }
					print("updateing completed")
				})
        
        let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toID).child(fromID).child(userMessagesFirebaseFolder)
        recipientUserMessagesRef.updateChildValues([messageID: fromID])

        self.incrementBadge()
        self.updateDefaultChatLastMessage()
      }
    }
  }

  fileprivate func incrementBadge() { /* default chats only, group chats badges handled by backend */
    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid, toId != fromId else { return }
    runTransaction(firstChild: toId, secondChild: fromId)
  }

  fileprivate func updateDefaultChatLastMessage() {
    guard let fromID = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID else { return }

    let lastMessageQORef = Database.database().reference()
      .child("user-messages").child(fromID).child(conversationID).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(1))

    lastMessageQORef.observeSingleEvent(of: .childAdded) { (snapshot) in
      let ref = Database.database().reference().child("user-messages").child(fromID).child(conversationID).child(messageMetaDataFirebaseFolder)
      let childValues: [String: Any] = ["chatID": conversationID, "lastMessageID": snapshot.key, "isGroupChat": false]
      ref.updateChildValues(childValues)
    }

    let lastMessageQIRef = Database.database().reference()
      .child("user-messages").child(conversationID).child(fromID).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(1))

    lastMessageQIRef.observeSingleEvent(of: .childAdded) { (snapshot) in
      let ref = Database.database().reference().child("user-messages").child(conversationID).child(fromID).child(messageMetaDataFirebaseFolder)
      let childValues: [String: Any] = ["chatID": fromID, "lastMessageID": snapshot.key, "isGroupChat": false]
      ref.updateChildValues(childValues)
    }
  }
  
  fileprivate func updateGroupLastMessage() {
    // updates only for current user
    // for other users this update handled by Backend to reduce write operations on device
    guard let fromID = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID else { return }

    let lastMessageQRef = Database.database().reference()
      .child("user-messages").child(fromID).child(conversationID).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(1))
    
    lastMessageQRef.observeSingleEvent(of: .childAdded) { (snapshot) in
      let ref = Database.database().reference().child("user-messages").child(fromID).child(conversationID).child(messageMetaDataFirebaseFolder)
      let childValues: [String: Any] = ["lastMessageID": snapshot.key]
      ref.updateChildValues(childValues)
    }
  }
}
