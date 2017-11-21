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
  
  
  func openSelectedPhoto(at indexPath : IndexPath) {
    
    let numberOfPhotos = mediaMessages.count
    
    guard let uid = Auth.auth().currentUser?.uid, let chatPartnerName = user?.name  else {
      return
    }
    
    let photos: [INSPhotoViewable] = {
      
      var mutablePhotos: [INSPhotoViewable] = []
      
      for photoIndex in 0 ..< numberOfPhotos {
        
        let isChattingWithSelf = user?.id == uid ?  true : false
        
        var titleString = (mediaMessages[photoIndex].fromId == user?.id ? chatPartnerName + "\n" : "You\n")
        
        if isChattingWithSelf {
          titleString = "You\n"
        }
        
        let title = NSMutableAttributedString(string: titleString , attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)])
        
        let date = NSDate(timeIntervalSince1970:  self.mediaMessages[photoIndex].timestamp!.doubleValue )
        let timestamp = timeAgoSinceDate(date: date, timeinterval: self.mediaMessages[photoIndex].timestamp!.doubleValue, numericDates: false)
        
        let attributedCaptionSummary = NSMutableAttributedString(string: timestamp, attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightGray, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)])
        
        let combination = NSMutableAttributedString()
        combination.append(title)
        combination.append(attributedCaptionSummary)
        
        
        if let downloadURL = self.mediaMessages[photoIndex].imageUrl, let messageID = self.mediaMessages[photoIndex].messageUID {
          
          let imageView = UIImageView()
          imageView.sd_setImage(with: URL(string: downloadURL), completed: { (image, error, cacheType, url) in
            let newPhoto = INSPhoto(image: image, thumbnailImage: nil, messageUID: messageID)
            newPhoto.attributedTitle = combination
            mutablePhotos.append(newPhoto)
          })
        } else if let localImage = self.mediaMessages[photoIndex].localImage {
          let newPhoto = INSPhoto(image: localImage, thumbnailImage: nil, messageUID: nil)
          newPhoto.attributedTitle = combination
          mutablePhotos.append(newPhoto)
        }
      }
      
      return mutablePhotos
    }()
    
    var initialPhotoIndex: Int!
    
    if messages[indexPath.item].localImage != nil {
      guard let initial = photos.index(where: {$0.image == messages[indexPath.item].localImage }) else {
        return
      }
      initialPhotoIndex = initial
    } else {
      guard let initial = photos.index(where: {$0.messageUID == messages[indexPath.item].messageUID }) else {
        return
      }
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
