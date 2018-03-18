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


private var inputContainerViewWasFirstResponder = false

extension ChatLogController {

  func performZoomInForVideo( url: URL) {
  
    let player = AVPlayer(url: url)
    
    let inBubblePlayerViewController = AVPlayerViewController()
  
    inBubblePlayerViewController.player = player
    
    inBubblePlayerViewController.modalTransitionStyle = .crossDissolve
    
    inBubblePlayerViewController.modalPresentationStyle = .overCurrentContext
    
    if self.inputContainerView.inputTextView.isFirstResponder {
      self.inputContainerView.inputTextView.resignFirstResponder()
    }
  
    present(inBubblePlayerViewController, animated: true, completion: nil)
  }
  
  
  func configurePhotoToolbarInfo(for messagesWithPhotos: [Message], at photoIndex: Int) -> NSMutableAttributedString? {
    
    guard let uid = Auth.auth().currentUser?.uid, let chatPartnerName = conversation?.chatName  else { return nil }
    
    let isChattingWithSelf = conversation?.chatID == uid ?  true : false
    var titleString = (messagesWithPhotos[photoIndex].fromId == conversation?.chatID ? chatPartnerName + "\n" : "You\n")
    if isChattingWithSelf { titleString = "You\n" }
    
    let title = NSMutableAttributedString(string: titleString , attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)])
    let date = Date(timeIntervalSince1970:  messagesWithPhotos[photoIndex].timestamp!.doubleValue )
    let timestamp = timeAgoSinceDate(date)
    let attributedCaptionSummary = NSMutableAttributedString(string: timestamp, attributes: [NSAttributedStringKey.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)])
    
    let combination = NSMutableAttributedString()
    combination.append(title)
    combination.append(attributedCaptionSummary)
    return combination
  }
  
  
  func openSelectedPhoto(at indexPath : IndexPath) {
    
      var photos: [INSPhotoViewable] = []
      
      let messagesWithPhotos = self.messages.filter({ (message) -> Bool in
        return (message.imageUrl != nil || message.localImage != nil) && message.localVideoUrl == nil && message.videoUrl == nil
      })
      
      let numberOfPhotos = messagesWithPhotos.count
      
      for photoIndex in 0 ..< numberOfPhotos {
        let combination = configurePhotoToolbarInfo(for: messagesWithPhotos, at: photoIndex)
        if let downloadURL = messagesWithPhotos[photoIndex].imageUrl, let messageID = messagesWithPhotos[photoIndex].messageUID {
          var imageView: UIImageView? = UIImageView()
          imageView?.sd_setImage(with: URL(string: downloadURL), completed: { (image, error, cacheType, url) in
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

  
    var initialPhotoIndex: Int!
    
    if messages[indexPath.item].localImage != nil {
      guard let initial = photos.index(where: {$0.image == messages[indexPath.item].localImage }) else { return }
      initialPhotoIndex = initial
    } else {
      guard let initial = photos.index(where: {$0.messageUID == messages[indexPath.item].messageUID }) else { return }
      initialPhotoIndex = initial
    }
    
    let cell = collectionView?.cellForItem(at: indexPath) as! BaseMediaMessageCell
    let currentPhoto = photos[initialPhotoIndex]
    let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: cell.messageImageView)
    
    galleryPreview.didDismissHandler = { viewController in
      self.inputAccessoryView?.isHidden = false
    }
    
    galleryPreview.referenceViewForPhotoWhenDismissingHandler = { photo in
      
      if photo.messageUID == nil {
        guard let indexOfCellWithLocalImage = self.messages.index(where: {$0.localImage == photo.image}) else {
          return nil
        }
        
        let indexPathOfCell = IndexPath(item: indexOfCellWithLocalImage, section: 0)
        
        guard let cellForDismiss = self.collectionView?.cellForItem(at: indexPathOfCell) as? BaseMediaMessageCell else {
          return nil
        }
        return cellForDismiss.messageImageView
        
      } else {
        guard let indexOfCell = self.messages.index(where: {$0.messageUID == photo.messageUID}) else {
          return nil
        }
        
        let indexPathOfCell = IndexPath(item: indexOfCell, section: 0)
        guard let cellForDismiss = self.collectionView?.cellForItem(at: indexPathOfCell) as? BaseMediaMessageCell else {
          return nil
        }
        return cellForDismiss.messageImageView
      }
    }
    
    inputContainerView.inputTextView.resignFirstResponder()
    galleryPreview.modalPresentationStyle = .overFullScreen
    galleryPreview.modalPresentationCapturesStatusBarAppearance = true
    present(galleryPreview, animated: true, completion: {
      self.inputAccessoryView?.isHidden = true
    })
  }
  
}
