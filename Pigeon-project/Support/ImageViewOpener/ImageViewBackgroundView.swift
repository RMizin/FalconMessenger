//
//  ImageViewBackgroundView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class ImageViewBackgroundView: UIView {
  
  
  
  var navigationBar : UINavigationBar = {
    var navigationBar = UINavigationBar()
    navigationBar.isTranslucent = false
    navigationBar.backgroundColor = .white
    
    return navigationBar
  }()
  
  
//  var imageView: UIImageView = {
//    var imageView = UIImageView()
// //   imageView.backgroundColor = .green
//    imageView.layer.masksToBounds = true
//    
//    return imageView
//  }()
  
  
  var toolbar: UIToolbar = {
    var toolbar = UIToolbar()
    return toolbar
  }()

  
  
   let navigationItem = UINavigationItem(title: "Profile photo")
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .white
    alpha = 0
   
    addSubview(navigationBar)
    navigationBar.frame = CGRect(x: 0, y: 20, width: deviceScreen.width, height: 44)
    
    
    addSubview(toolbar)
    toolbar.frame = CGRect(x: 0, y: deviceScreen.height-49, width: deviceScreen.width, height: 49)
    
  //  addSubview(imageView)
   // imageView.frame = CGRect(x: 0, y: 65, width: Int(deviceScreen.width), height: Int(deviceScreen.height-64-49))
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  
}


