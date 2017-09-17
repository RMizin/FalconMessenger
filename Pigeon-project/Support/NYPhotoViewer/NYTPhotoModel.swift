//
//  ExamplePhoto.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//




import UIKit
import NYTPhotoViewer

class NYTPhotoModel: NSObject, NYTPhoto {

    var image: UIImage?
    var imageData: Data?
    var placeholderImage: UIImage?
    let attributedCaptionTitle: NSAttributedString?
    var attributedCaptionSummary: NSAttributedString? = NSAttributedString(string: "", attributes: [NSForegroundColorAttributeName: UIColor.gray])
    var attributedCaptionCredit: NSAttributedString? = NSAttributedString(string: "", attributes: [NSForegroundColorAttributeName: UIColor.darkGray])

  init(image: UIImage? = nil, imageData: NSData? = nil, attributedCaptionTitle: NSAttributedString, attributedCaptionSummary: NSAttributedString, attributedCaptionCredit: NSAttributedString) {
        self.image = image
      if let imd = imageData {
        self.imageData = imd as Data
      }
    
        self.attributedCaptionSummary = attributedCaptionSummary
        self.attributedCaptionCredit = attributedCaptionCredit
        self.attributedCaptionTitle = attributedCaptionTitle
    
        super.init()
    }

}
