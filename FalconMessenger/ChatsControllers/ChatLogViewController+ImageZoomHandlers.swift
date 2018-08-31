//
//  ChatLogController+ImageZoomHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Firebase

private var inputContainerViewWasFirstResponder = false

extension ChatLogViewController {

  func performZoomInForVideo( url: URL) {
    let player = AVPlayer(url: url)
    let inBubblePlayerViewController = AVPlayerViewController()
  
    inBubblePlayerViewController.player = player
    inBubblePlayerViewController.modalTransitionStyle = .crossDissolve
    if DeviceType.isIPad {
      inBubblePlayerViewController.modalPresentationStyle = .overFullScreen
    } else {
      inBubblePlayerViewController.modalPresentationStyle = .overCurrentContext
    }
    
    if self.inputContainerView.inputTextView.isFirstResponder {
      self.inputContainerView.inputTextView.resignFirstResponder()
    }
    present(inBubblePlayerViewController, animated: true, completion: nil)
  }
  
  func configurePhotoToolbarInfo(for messagesWithPhotos: [Message], at photoIndex: Int) -> NSMutableAttributedString? {
    guard let uid = Auth.auth().currentUser?.uid, let chatPartnerName = conversation?.chatName  else { return nil }
    var titleString = String()
  
    if let isGroupChat = conversation?.isGroupChat, isGroupChat, let senderName = messagesWithPhotos[photoIndex].senderName {
      titleString = senderName + "\n"
    } else {
      titleString = chatPartnerName + "\n"
    }
    
    let isChattingWithSelf = messagesWithPhotos[photoIndex].fromId == uid ?  true : false
    if isChattingWithSelf { titleString = "You\n" }
    let titleAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)]
    let title = NSMutableAttributedString(string: titleString , attributes: titleAttributes)
    let date = Date(timeIntervalSince1970:  messagesWithPhotos[photoIndex].timestamp!.doubleValue )
    let timestamp = timeAgoSinceDate(date)
    let summaryAttributes = [NSAttributedStringKey.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor,
                      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)]
    let attributedCaptionSummary = NSMutableAttributedString(string: timestamp, attributes: summaryAttributes)
    
    let combination = NSMutableAttributedString()
    combination.append(title)
    combination.append(attributedCaptionSummary)
    return combination
  }
  
  func openSelectedPhoto(at indexPath : IndexPath) {
    var photos: [INSPhotoViewable] = setupPhotosData()
    var initialPhotoIndex: Int!
    
    if groupedMessages[indexPath.section][indexPath.row].localImage != nil {
      guard let initial = photos.index(where: {$0.image == groupedMessages[indexPath.section][indexPath.row].localImage }) else { return }
      initialPhotoIndex = initial
    } else {
      guard let initial = photos.index(where: {$0.messageUID == groupedMessages[indexPath.section][indexPath.row].messageUID }) else { return }
      initialPhotoIndex = initial
    }
    
    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseMediaMessageCell else { return }
    let currentPhoto = photos[initialPhotoIndex]
    let referenceView = cell.messageImageView
    let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: referenceView)
    galleryPreview.overlayView.setHidden(true, animated: false)
    
    setupGalleryDismissHandler(galleryPreview: galleryPreview)
    inputContainerView.inputTextView.resignFirstResponder()
    galleryPreview.modalPresentationStyle = .overFullScreen
    galleryPreview.modalPresentationCapturesStatusBarAppearance = true
    present(galleryPreview, animated: true, completion: {
      self.inputAccessoryView?.isHidden = true
    })
  }
  
  func setupPhotosData() -> [INSPhotoViewable] {
    var photos: [INSPhotoViewable] = []
    let messagesWithPhotos = self.messages.filter({ (message) -> Bool in
      return (message.imageUrl != nil || message.localImage != nil) && (message.localVideoUrl == nil && message.videoUrl == nil)
    })
    
    let numberOfPhotos = messagesWithPhotos.count
    for photoIndex in 0 ..< numberOfPhotos {
      let combination = configurePhotoToolbarInfo(for: messagesWithPhotos, at: photoIndex)
      
      if let downloadURL = messagesWithPhotos[photoIndex].imageUrl,
         let messageID = messagesWithPhotos[photoIndex].messageUID {
        var imageView: UIImageView? = UIImageView()
        
        imageView?.sd_setImage(with: URL(string: downloadURL), completed: { (image, _, _, _) in
          let newPhoto = INSPhoto(image: image, thumbnailImage: nil, messageUID: messageID)
          newPhoto.attributedTitle = combination
          photos.append(newPhoto)
          imageView = nil
        })
      } else if let localImage = messagesWithPhotos[photoIndex].localImage {
        let newPhoto = INSPhoto(image: localImage, thumbnailImage: nil, messageUID: nil)
        newPhoto.attributedTitle = combination
        photos.append(newPhoto)
      }
    }
    return photos
  }
  
  func setupGalleryDismissHandler(galleryPreview:INSPhotosViewController) {
    galleryPreview.didDismissHandler = { viewController in
      self.inputAccessoryView?.isHidden = false
    }
    galleryPreview.referenceViewForPhotoWhenDismissingHandler = { photo in
      if photo.messageUID == nil {
        guard let indexPath = Message.get(indexPathOf: nil, localPhoto: photo.image, in: self.groupedMessages) else { return nil }
        guard let cellForDismiss = self.collectionView.cellForItem(at: indexPath) as? BaseMediaMessageCell else { return nil }
        return cellForDismiss.messageImageView
      } else {
        guard let indexPath = Message.get(indexPathOf: photo.messageUID, localPhoto: nil, in: self.groupedMessages) else { return nil}
        guard let cellForDismiss = self.collectionView.cellForItem(at: indexPath) as? BaseMediaMessageCell else { return nil }
        return cellForDismiss.messageImageView
      }
    }
  }
}
