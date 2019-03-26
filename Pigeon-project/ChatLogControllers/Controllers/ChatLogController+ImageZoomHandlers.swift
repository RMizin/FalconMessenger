//
//  ChatLogController+ImageZoomHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVKit
import Firebase

private var inputContainerViewWasFirstResponder = false

extension ChatLogController {

  func performZoomInForVideo( url: URL) {
    let player = AVPlayer(url: url)
    let inBubblePlayerViewController = AVPlayerViewController()
    inBubblePlayerViewController.player = player
    inBubblePlayerViewController.modalTransitionStyle = .crossDissolve
    inBubblePlayerViewController.modalPresentationStyle = .overCurrentContext
    
    if inputContainerView.inputTextView.isFirstResponder {
      inputContainerView.inputTextView.resignFirstResponder()
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
		let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
													 NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
    let title = NSMutableAttributedString(string: titleString , attributes: titleAttributes)
    let date = Date(timeIntervalSince1970:  messagesWithPhotos[photoIndex].timestamp!.doubleValue)
    let timestamp = timeAgoSinceDate(date)
		let summaryAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor,
														 NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
    let attributedCaptionSummary = NSMutableAttributedString(string: timestamp, attributes: summaryAttributes)
    
    let combination = NSMutableAttributedString()
    combination.append(title)
    combination.append(attributedCaptionSummary)
    return combination
  }
  
  func openSelectedPhoto(at indexPath: IndexPath) {
    var photos: [INSPhotoViewable] = setupPhotosData()
    var initialPhotoIndex: Int!
    
    if messages[indexPath.item].localImage != nil {
			guard let initial = photos.firstIndex(where: {$0.image == messages[indexPath.item].localImage }) else { return }
      initialPhotoIndex = initial
    } else {
			guard let initial = photos.firstIndex(where: {$0.messageUID == messages[indexPath.item].messageUID }) else { return }
      initialPhotoIndex = initial
    }
    
    guard let cell = collectionView?.cellForItem(at: indexPath) as? BaseMediaMessageCell else { return }
    let currentPhoto = photos[initialPhotoIndex]
    let referenceView = cell.messageImageView
    let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: referenceView)
    
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
  
  func setupGalleryDismissHandler(galleryPreview: INSPhotosViewController) {
    galleryPreview.didDismissHandler = { viewController in
      self.inputAccessoryView?.isHidden = false
    }
    galleryPreview.referenceViewForPhotoWhenDismissingHandler = { photo in
      if photo.messageUID == nil {
				guard let indexOfCellWithLocalImage = self.messages.firstIndex(where: {$0.localImage == photo.image}) else { return nil }
        let indexPathOfCell = IndexPath(item: indexOfCellWithLocalImage, section: 0)
        guard let cellForDismiss = self.collectionView?.cellForItem(at: indexPathOfCell) as? BaseMediaMessageCell else { return nil }
        return cellForDismiss.messageImageView
      } else {
				guard let indexOfCell = self.messages.firstIndex(where: {$0.messageUID == photo.messageUID}) else { return nil }
        let indexPathOfCell = IndexPath(item: indexOfCell, section: 0)
        guard let cellForDismiss = self.collectionView?.cellForItem(at: indexPathOfCell) as? BaseMediaMessageCell else { return nil }
        return cellForDismiss.messageImageView
      }
    }
  }
}
