//
//  ImageViewBackgroundView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class ImageViewBackgroundView: UIView {
  
  
  var toolbar: UIToolbar = {
    var toolbar = UIToolbar()
    return toolbar
  }()
  
  var navigationBar : UINavigationBar = {
    var navigationBar = UINavigationBar()
    
    return navigationBar
  }()
   let navigationItem = UINavigationItem(title: "Profile photo")
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .white
    alpha = 0
   
    addSubview(navigationBar)
    navigationBar.frame = CGRect(x: 0, y: 0, width: deviceScreen.width, height: 64)
    
    
    addSubview(toolbar)
    toolbar.frame = CGRect(x: 0, y: deviceScreen.height-49, width: deviceScreen.width, height: 49)
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  
}


