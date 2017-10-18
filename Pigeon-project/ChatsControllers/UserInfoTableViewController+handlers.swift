//
//  UserInfoTableViewController+handlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 10/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import NYTPhotoViewer


extension UserInfoTableViewController: NYTPhotosViewControllerDelegate {
  
 @objc func openPhoto() {
  
    let imageView = UIImageView()
    
    let attributedCaptionSummary = NSAttributedString(string: contactName, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)])
    
    let attributedCaptionCredit = NSAttributedString(string: "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
    
    imageView.sd_setImage(with: contactPhoto! as URL) { (image, error, cacheType, url) in
     
      let photo = NYTPhotoModel(image: image, imageData: nil,
                                attributedCaptionTitle: attributedCaptionCredit,
                                attributedCaptionSummary: attributedCaptionSummary,
                                attributedCaptionCredit: attributedCaptionCredit)
      
      let destination = NYTPhotosViewController(photos: [photo], initialPhoto: photo)
    
      self.present(destination, animated: true, completion: nil)
    }
  }
}
