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
import FirebaseAuth
import FirebaseDatabase
import RealmSwift
import SDWebImage

private var inputContainerViewWasFirstResponder = false

extension ChatLogViewController {

  func handleOpen(madiaAt indexPath: IndexPath) {
    guard let viewController = openSelectedPhoto(at: indexPath) else { return }
    present(viewController, animated: true, completion: nil)
  }

  func configurePhotoToolbarInfo(for messagesWithPhotos: Results<Message>, at photoIndex: Int) -> NSMutableAttributedString? {
    guard let uid = Auth.auth().currentUser?.uid, let chatPartnerName = conversation?.chatName  else { return nil }
    var titleString = String()
  
    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat,
      let senderName = messagesWithPhotos[photoIndex].senderName {
      titleString = senderName + "\n"
    } else {
      titleString = chatPartnerName + "\n"
    }
    
    let isChattingWithSelf = messagesWithPhotos[photoIndex].fromId == uid ?  true : false
    if isChattingWithSelf { titleString = "You\n" }
		let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
													 NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
    let title = NSMutableAttributedString(string: titleString, attributes: titleAttributes)
		let date = Date(timeIntervalSince1970: TimeInterval(messagesWithPhotos[photoIndex].timestamp.value!))
    let timestamp = timeAgoSinceDate(date)
		let summaryAttributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor,
														 NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
    let attributedCaptionSummary = NSMutableAttributedString(string: timestamp, attributes: summaryAttributes)
    
    let combination = NSMutableAttributedString()
    combination.append(title)
    combination.append(attributedCaptionSummary)
    return combination
  }

  func openSelectedPhoto(at indexPath: IndexPath) -> UIViewController? {
    let photos: [INSPhotoViewable] = setupPhotosData()
    var initialPhotoIndex: Int!

		guard let initial = photos.firstIndex(where: {$0.messageUID == groupedMessages[indexPath.section].messages[indexPath.row].messageUID }) else { return nil }
		initialPhotoIndex = initial

    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseMediaMessageCell else { return nil }
    let currentPhoto = photos[initialPhotoIndex]
    let referenceView = cell.messageImageView
    let galleryPreview = INSPhotosViewController(photos: photos,
                                                 initialPhoto: currentPhoto,
                                                 referenceView: referenceView)    
    setupGalleryDismissHandler(galleryPreview: galleryPreview)
    self.inputContainerView.resignAllResponders()
    galleryPreview.modalPresentationStyle = .overFullScreen
    galleryPreview.modalPresentationCapturesStatusBarAppearance = true
    return galleryPreview
  }

  func setupPhotosData() -> [INSPhotoViewable] {
    var photos: [INSPhotoViewable] = []

		guard let messagesWithPhotos = conversation?.messages
			.filter("localImage != nil OR imageUrl != nil")
			.sorted(byKeyPath: "timestamp", ascending: true) else {
			print("returning from message with photos")
			return photos
		}
    
    let numberOfPhotos = messagesWithPhotos.count
    for photoIndex in 0 ..< numberOfPhotos {
      let combination = configurePhotoToolbarInfo(for: messagesWithPhotos, at: photoIndex)
      
    	if let localImage = messagesWithPhotos[photoIndex].localImage?.uiImage(), let messageID = messagesWithPhotos[photoIndex].messageUID {
				let videoURL = messagesWithPhotos[photoIndex].videoUrl// ?? ""
				let localVideoURL = messagesWithPhotos[photoIndex].localVideoUrl// ?? ""

        let newPhoto = INSPhoto(image: localImage, thumbnailImage: nil, messageUID: messageID, videoURL: videoURL, localVideoURL: localVideoURL)
        newPhoto.attributedTitle = combination
        photos.append(newPhoto)
			} else if let downloadURL = messagesWithPhotos[photoIndex].imageUrl,
				let messageID = messagesWithPhotos[photoIndex].messageUID {
				let thumbnail = messagesWithPhotos[photoIndex].thumbnailImageUrl ?? ""
				let videoURL = messagesWithPhotos[photoIndex].videoUrl// ?? ""
				let localVideoURL = messagesWithPhotos[photoIndex].localVideoUrl// ?? ""




				let newPhoto = 	INSPhoto(imageURL: URL(string: downloadURL),
																	thumbnailImageURL: URL(string: thumbnail),
																	messageUID: messageID, videoURL: videoURL, localVideoURL: localVideoURL)
				newPhoto.attributedTitle = combination
				photos.append(newPhoto)
			}
    }
    return photos
  }
  
  func setupGalleryDismissHandler(galleryPreview: INSPhotosViewController) {
    galleryPreview.didDismissHandler = { [weak self] viewController in
			guard let unwrappedSelf = self else { return }
      unwrappedSelf.inputAccessoryView?.isHidden = false
			unwrappedSelf.collectionView.performBatchUpdates({
				unwrappedSelf.collectionView.reloadItems(at: unwrappedSelf.collectionView.indexPathsForVisibleItems)
			}, completion: nil)
    }

    galleryPreview.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
			guard let indexPath = Message.get(indexPathOf: photo.messageUID,
																				localPhoto: nil,
																				in: self?.groupedMessages) else { return nil }
			guard let cellForDismiss = self?.collectionView.cellForItem(at: indexPath) as? BaseMediaMessageCell else { return nil }

			return cellForDismiss.messageImageView
    }
  }
}
