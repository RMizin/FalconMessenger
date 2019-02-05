//
//  MessageSender.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/19/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos

protocol MessageSenderDelegate: class {
  func update(with values: [String: AnyObject])
  func update(mediaSending progress: Double, animated: Bool)
}

class MessageSender: NSObject {
  
  fileprivate let storageUploader = StorageMediaUploader()
  fileprivate var conversation: Conversation?
  fileprivate var attachedMedia = [MediaObject]()
  fileprivate var text: String?
  fileprivate let reference = Database.database().reference()
  
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
      let isPhotoMessage = (mediaObject.phAsset?.mediaType == PHAssetMediaType.image || mediaObject.phAsset == nil) && mediaObject.audioObject == nil
      let isVideoMessage = mediaObject.phAsset?.mediaType == PHAssetMediaType.video
      
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
  fileprivate var mediaCount = CGFloat()
  fileprivate var mediaToSend = [(values: [String: AnyObject], reference: DatabaseReference)]()
  fileprivate var progress = [UploadProgress]()
  
  fileprivate func syncronizeMediaSending() {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid else { return }
    mediaUploadGroup = DispatchGroup()
    mediaCount = CGFloat()
    mediaToSend.removeAll()
    progress.removeAll()
    
    mediaUploadGroup.enter() // for text message
    mediaCount += 1 // for text message
    
    attachedMedia.forEach { (object) in
      mediaUploadGroup.enter()
      mediaCount += 1
    }
    
    mediaUploadGroup.notify(queue: .global(qos: .default), execute: {
      self.mediaToSend.forEach({ (element) in
        self.updateDatabase(at: element.reference, with: element.values, toID: toID, fromID: fromID)
      })
    })
  }
  
  //MARK: TEXT MESSAGE
  fileprivate func sendTextMessage() {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid, let text = self.text else {
      self.mediaCount -= 1
      self.mediaUploadGroup.leave()
      return
    }
    
    guard text != "" else {
      self.mediaCount -= 1
      self.mediaUploadGroup.leave()
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
    
    delegate?.update(with: defaultData)
    self.mediaToSend.append((values: defaultData, reference: reference))
    self.mediaUploadGroup.leave()
    self.progress.setProgress(1.0, id: messageUID)
    self.updateProgress(self.progress, mediaCount: self.mediaCount)
  }
  
  //MARK: PHOTO MESSAGE
  fileprivate func sendPhotoMessage(object: MediaObject) {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid else {
      self.mediaUploadGroup.leave()
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
    
    var localData: [String: AnyObject] = ["localImage": object.object!.asUIImage!]  //"localVideoUrl": path as AnyObject]
    defaultData.forEach({ localData[$0] = $1 })
    
    delegate?.update(with: localData)
    
    storageUploader.upload(object.object!.asUIImage!, progress: { (snapshot) in
      
      if let progressCount = snapshot?.progress?.fractionCompleted {
        
        self.progress.setProgress(progressCount * 0.98, id: messageUID) //= self.setProgress(progressCount * 0.98, id: messageUID, array: self.progress)
        self.updateProgress(self.progress, mediaCount: self.mediaCount)
      }
      
    }) { (imageURL) in
      self.progress.setProgress(1.0, id: messageUID)
      self.updateProgress(self.progress, mediaCount: self.mediaCount)
      var remoteData: [String: AnyObject] = ["imageUrl": imageURL as AnyObject]
      defaultData.forEach({ remoteData[$0] = $1 })
      
      self.mediaToSend.append((values: remoteData, reference: reference))
      self.mediaUploadGroup.leave()
    }
  }
  
  //MARK: VIDEO MESSAGE
  fileprivate func sendVideoMessage(object: MediaObject) {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid, let path = object.fileURL else {
      self.mediaUploadGroup.leave()
      return
    }
    
    let reference = Database.database().reference().child("messages").childByAutoId()
    
    guard let messageUID = reference.key else { return }
    let messageStatus = messageStatusDelivered
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    
    guard let videoID = reference.key else { return }
    let imageID = (reference.key ?? "") + "image"
    
    let defaultData: [String: AnyObject] = ["messageUID": messageUID as AnyObject,
                                            "toId": toID as AnyObject,
                                            "status": messageStatus as AnyObject,
                                            "seen": false as AnyObject,
                                            "fromId": fromID as AnyObject,
                                            "timestamp": timestamp,
                                            "imageWidth": object.object!.asUIImage!.size.width as AnyObject,
                                            "imageHeight": object.object!.asUIImage!.size.height as AnyObject]
    
    
    var localData: [String: AnyObject] = ["localImage": object.object!.asUIImage!, "localVideoUrl": path as AnyObject]
    defaultData.forEach({ localData[$0] = $1 })
    
    delegate?.update(with: localData)
    
    storageUploader.upload(object.videoObject!, progress: { [unowned self] (snapshot) in
      if let progressCount = snapshot?.progress?.fractionCompleted {
        self.progress.setProgress(progressCount * 0.98, id: videoID)
        self.updateProgress(self.progress, mediaCount: self.mediaCount)
      }
    }) { (videoURL) in
      self.progress.setProgress(1.0, id: messageUID)
      self.updateProgress(self.progress, mediaCount: self.mediaCount)
      
      self.storageUploader.upload(object.object!.asUIImage!, progress: { [unowned self] (snapshot) in
        
        if let progressCount = snapshot?.progress?.fractionCompleted {
          self.progress.setProgress(progressCount * 0.98, id: imageID)
          self.updateProgress(self.progress, mediaCount: self.mediaCount)
        }
        
        }, completion: { (imageURL) in
          self.progress.setProgress(1.0, id: messageUID)
          self.updateProgress(self.progress, mediaCount: self.mediaCount)
          
          var remoteData: [String: AnyObject] = ["imageUrl": imageURL as AnyObject, "videoUrl": videoURL as AnyObject]
          defaultData.forEach({ remoteData[$0] = $1 })
          
          self.mediaToSend.append((values: remoteData, reference: reference))
          self.mediaUploadGroup.leave()
      })
    }
  }
  
  //MARK: VOICE MESSAGE
  fileprivate func sendVoiceMessage(object: MediaObject) {
    guard let toID = conversation?.chatID, let fromID = Auth.auth().currentUser?.uid else {
      self.mediaUploadGroup.leave()
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
    delegate?.update(with: defaultData)
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
  
  fileprivate func updateDatabase(at reference: DatabaseReference, with values: [String: AnyObject], toID: String, fromID: String ) {
    reference.updateChildValues(values) { (error, _) in
      guard error == nil else { return }
      guard let messageID = reference.key else { return }
      
      if let isGroupChat = self.conversation?.isGroupChat, isGroupChat, let membersIDs = self.conversation?.chatParticipantsIDs {
        for memberID in membersIDs {
          let userMessagesRef = self.reference.child("user-messages").child(memberID).child(toID).child(userMessagesFirebaseFolder)
          userMessagesRef.updateChildValues([messageID: 1])
        }
      } else {
        let userMessagesRef = self.reference.child("user-messages").child(fromID).child(toID).child(userMessagesFirebaseFolder)
        userMessagesRef.updateChildValues([messageID: 1])
        
        let recipientUserMessagesRef = self.reference.child("user-messages").child(toID).child(fromID).child(userMessagesFirebaseFolder)
        recipientUserMessagesRef.updateChildValues([messageID: 1])
      }
      
      self.incrementBadgeForReciever()
      self.setupMetadataForSender()
      self.updateLastMessage(with: messageID)
    }
  }
  
  fileprivate func updateLastMessage(with messageID: String) {
    guard let conversationID = conversation?.chatID, let participantsIDs = conversation?.chatParticipantsIDs else {
      return
    }
    let isGroupChat = conversation?.isGroupChat ?? false
    
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      for memberID in participantsIDs {
        let ref = reference.child("user-messages").child(memberID).child(conversationID).child(messageMetaDataFirebaseFolder)
        let childValues: [String: Any] = ["lastMessageID": messageID]
        ref.updateChildValues(childValues)
      }
    } else {
      guard let toID = conversation?.chatID, let uID = Auth.auth().currentUser?.uid else { return }
      
      let ref = reference.child("user-messages").child(uID).child(toID).child(messageMetaDataFirebaseFolder)
      let childValues: [String: Any] = ["chatID": toID,
                                        "lastMessageID": messageID,
                                        "isGroupChat": isGroupChat]
      ref.updateChildValues(childValues)
      
      let ref1 = reference.child("user-messages").child(toID).child(uID).child(messageMetaDataFirebaseFolder)
      let childValues1: [String: Any] = ["chatID": uID,
                                         "lastMessageID": messageID,
                                         "isGroupChat": isGroupChat]
      ref1.updateChildValues(childValues1)
    }
  }
  
  fileprivate func setupMetadataForSender() {
    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    var ref = Database.database().reference().child("user-messages").child(fromId).child(toId)
    ref.observeSingleEvent(of: .value, with: { (snapshot) in
      guard !snapshot.hasChild(messageMetaDataFirebaseFolder) else { return }
      ref = ref.child(messageMetaDataFirebaseFolder)
      ref.updateChildValues(["badge": 0])
    })
  }
  
  fileprivate func incrementBadgeForReciever() {
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      guard let conversationID = conversation?.chatID else { return }
      guard let participantsIDs = conversation?.chatParticipantsIDs else { return }
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }
      
      for participantID in participantsIDs where participantID != currentUserID {
        runTransaction(firstChild: participantID, secondChild: conversationID)
      }
    } else {
      guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid, toId != fromId else { return }
      runTransaction(firstChild: toId, secondChild: fromId)
    }
  }
}
