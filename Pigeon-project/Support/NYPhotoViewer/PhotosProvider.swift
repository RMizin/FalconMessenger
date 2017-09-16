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
    var photos = [NYTPhotoModel]()
     
    let NumberOfPhotos = mediaMessages.count

        for photoIndex in 0 ..< NumberOfPhotos {
  
          var titleString = (mediaMessages[photoIndex].fromId == user?.id ? user!.name ?? "" : "You")
          
          if user?.id == Auth.auth().currentUser?.uid {
            titleString = "You"
          }
          
          let title = NSAttributedString(string: titleString , attributes: [NSForegroundColorAttributeName: UIColor.white])
          let timestamp = self.mediaMessages[photoIndex].timestamp?.doubleValue.getShortDateStringFromUTC() ?? ""
          let status = mediaMessages[photoIndex].fromId == Auth.auth().currentUser?.uid ?? "" ? self.mediaMessages[photoIndex].status ?? "" : ""
          let attributedCaptionSummary = NSAttributedString(string: timestamp, attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
          let attributedCaptionCredit = NSAttributedString(string: status, attributes: [NSForegroundColorAttributeName: UIColor.gray])
     
          if self.mediaMessages[photoIndex].imageUrl != nil {
            let imageview = UIImageView()
     
            imageview.sd_setImage(with: URL(string: mediaMessages[photoIndex].imageUrl!), completed: { (image, error, cahce, url) in
              
              if error != nil {
                return
              }
             
              let photo = NYTPhotoModel(image: image, attributedCaptionTitle: title, attributedCaptionSummary: attributedCaptionSummary, attributedCaptionCredit: attributedCaptionCredit )
            
              photos.append(photo)
              
              if self.messages[indexPath.row].imageUrl != nil {
                if url == URL(string: self.messages[indexPath.row].imageUrl!) {
                  initialIndex = photos.count-1
                }
              }
            })
            
          } else if self.mediaMessages[photoIndex].localImage != nil {
            let photo = NYTPhotoModel(image: self.mediaMessages[photoIndex].localImage, attributedCaptionTitle: title, attributedCaptionSummary: attributedCaptionSummary, attributedCaptionCredit: attributedCaptionCredit)
            photos.append(photo)
            
            if self.messages[indexPath.row].localImage == photo.image {
              initialIndex = photos.count-1
            }
          }
        }
    
    inputContainerView.inputTextView.inputView = nil
    inputContainerView.inputTextView.reloadInputViews()
    
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
