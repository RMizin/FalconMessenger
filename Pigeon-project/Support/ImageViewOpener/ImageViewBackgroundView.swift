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
    navigationBar.frame = CGRect(x: 0, y: UIApplication.shared.statusBarFrame.height, width: deviceScreen.width, height: 44)
    
    addSubview(toolbar)
    
    if #available(iOS 11.0, *) {
      
      let window = UIApplication.shared.keyWindow
      let bottomSafeArea = window?.safeAreaInsets.bottom ?? 0.0
      
      toolbar.frame = CGRect(x: 0, y: deviceScreen.height-49-bottomSafeArea, width: deviceScreen.width, height: 49)
    } else {
      toolbar.frame = CGRect(x: 0, y: deviceScreen.height-49, width: deviceScreen.width, height: 49)
    }
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  
}


