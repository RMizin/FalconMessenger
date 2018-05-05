//
//  UserInfoTableViewController+handlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 10/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


extension UserInfoTableViewController {
  
 @objc func openPhoto() {

    let imageView = UIImageView()
  
    let overlay = INSPhotosOverlayView()
    overlay.bottomShadow.isHidden = true

    imageView.sd_setImage(with: URL(string: user!.photoURL!)) { (image, error, cacheType, url) in
      let photo = INSPhoto(image: image, thumbnailImage: nil, messageUID: nil)
      let photos: [INSPhotoViewable] = [photo]
    
      let indexPath = IndexPath(row: 0, section: 0)
      let cell = self.tableView.cellForRow(at: indexPath) as! UserinfoHeaderTableViewCell
      let currentPhoto = photos[indexPath.row]
      let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: cell.icon)
    
      galleryPreview.overlayView = overlay
      galleryPreview.overlayView.setHidden(true, animated: false)
        
      galleryPreview.referenceViewForPhotoWhenDismissingHandler = {  photo in
        return cell.icon
      }
      galleryPreview.modalPresentationStyle = .overFullScreen
      galleryPreview.modalPresentationCapturesStatusBarAppearance = true
      self.present(galleryPreview, animated: true, completion: nil)
    }
  }
}
