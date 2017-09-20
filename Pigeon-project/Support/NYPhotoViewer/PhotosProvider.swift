//
//  PhotosProvider.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import NYTPhotoViewer
import Firebase


let CustomEverythingPhotoIndex = 1, DefaultLoadingSpinnerPhotoIndex = 3//, NoReferenceViewPhotoIndex = 4

extension ChatLogController: NYTPhotosViewControllerDelegate {
  
  func setupPhotos(indexPath : IndexPath) {
    
    var initialIndex = 0
    
    let numberOfPhotos = mediaMessages.count
    
    guard let uid = Auth.auth().currentUser?.uid, let chatPartnerName = user?.name  else {
      return
    }
    
    let photos: [NYTPhotoModel] = {
      
      var mutablePhotos: [NYTPhotoModel] = []
      
      for photoIndex in 0 ..< numberOfPhotos {
        
        let isChattingWithSelf = user?.id == uid ?  true : false
        
        var titleString = (mediaMessages[photoIndex].fromId == user?.id ? chatPartnerName : "You")
        
        if isChattingWithSelf {
          titleString = "You"
        }
        
        let title = NSAttributedString(string: titleString , attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        
        let date = NSDate(timeIntervalSince1970:  self.mediaMessages[photoIndex].timestamp!.doubleValue )
        let timestamp = timeAgoSinceDate(date: date, timeinterval: self.mediaMessages[photoIndex].timestamp!.doubleValue, numericDates: false) 
        
        let status = mediaMessages[photoIndex].fromId == uid ? self.mediaMessages[photoIndex].status ?? "" : ""
        let attributedCaptionSummary = NSAttributedString(string: timestamp, attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightGray])
        let attributedCaptionCredit = NSAttributedString(string: status, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        
        if let downloadURL = self.mediaMessages[photoIndex].imageUrl {
          
          let imageview = UIImageView()
          
          imageview.sd_setImage(with: URL(string: downloadURL), completed: { (image, error, cahce, url) in
            
            if error != nil {
              return
            }
            
            let photo = NYTPhotoModel(image: image, attributedCaptionTitle: title, attributedCaptionSummary: attributedCaptionSummary, attributedCaptionCredit: attributedCaptionCredit )
            
            mutablePhotos.append(photo)
            
            if let selectedImageURL = self.messages[indexPath.row].imageUrl {
              
              if url == URL(string: selectedImageURL) {
                initialIndex = mutablePhotos.count - 1
              }
            }
          })
          
        } else if let localImage = self.mediaMessages[photoIndex].localImage {
          let photo = NYTPhotoModel(image: localImage, attributedCaptionTitle: title, attributedCaptionSummary: attributedCaptionSummary, attributedCaptionCredit: attributedCaptionCredit)
          
          mutablePhotos.append(photo)
          
          if self.messages[indexPath.row].localImage == photo.image {
            initialIndex = mutablePhotos.count - 1
          }
        }
      }
      
      return mutablePhotos
      
    }()

    if photos.count - 1 < initialIndex {
      print("Initial index not exists. Returning to avoid app crash.")
      return
    }
    
    inputContainerView.inputTextView.resignFirstResponder()
    
    let nytPhotosViewController = NYTPhotosViewController(photos: photos, initialPhoto: photos[initialIndex])
    nytPhotosViewController.delegate = self
    
    present(nytPhotosViewController, animated: true, completion: {
    self.inputAccessoryView?.isHidden = true
    })
  }
  
  func photosViewControllerWillDismiss(_ photosViewController: NYTPhotosViewController) {
    UIView.performWithoutAnimation {
       self.resignFirstResponder()
    }
  }
  
  func photosViewControllerDidDismiss(_ photosViewController: NYTPhotosViewController) {
    self.inputAccessoryView?.isHidden = false
    self.becomeFirstResponder()
  }
}
