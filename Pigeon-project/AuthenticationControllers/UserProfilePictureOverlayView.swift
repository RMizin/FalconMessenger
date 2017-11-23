//
//  UserProfilePictureOverlayView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


class UserProfilePictureOverlayView: UIView {
  
  let navigationItem = UINavigationItem(title: "Profile photo")
  
  weak var photosViewController: INSPhotosViewController?
  
  var viewForSatausbarSafeArea: UIView = {
     var viewForSatausbarSafeArea = UIView()
    viewForSatausbarSafeArea.backgroundColor = UIColor.black
    viewForSatausbarSafeArea.alpha = 0.8
    viewForSatausbarSafeArea.translatesAutoresizingMaskIntoConstraints = false
    
    return viewForSatausbarSafeArea
  }()
  
  var navigationBar: UINavigationBar = {
    var navigationBar = UINavigationBar()
    navigationBar.backgroundColor = UIColor.black
    navigationBar.alpha = 0.8
    navigationBar.barStyle = .blackTranslucent
    navigationBar.shadowImage = UIImage()
    navigationBar.setBackgroundImage(UIImage(), for: .default)
    navigationBar.translatesAutoresizingMaskIntoConstraints = false
    
    return navigationBar
  }()
  
  var toolbar: UIToolbar = {
    var toolbar = UIToolbar()
    toolbar.alpha = 0.8
    toolbar.barTintColor = .black
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    
    return toolbar
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .clear
    
    addSubview(navigationBar)
    addSubview(toolbar)
    addSubview(viewForSatausbarSafeArea)
    
    if #available(iOS 11.0, *) {
      toolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
    } else {
      toolbar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    toolbar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    toolbar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    toolbar.heightAnchor.constraint(equalToConstant: 49).isActive = true
    
    if #available(iOS 11.0, *) {
      navigationBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    } else {
       navigationBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
    navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    navigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    viewForSatausbarSafeArea.topAnchor.constraint(equalTo: topAnchor).isActive = true
    viewForSatausbarSafeArea.bottomAnchor.constraint(equalTo: navigationBar.topAnchor).isActive = true
    viewForSatausbarSafeArea.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    viewForSatausbarSafeArea.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}


extension UserProfilePictureOverlayView: INSPhotosOverlayViewable {
  
  func populateWithPhoto(_ photo: INSPhotoViewable) {}
  
  func setHidden(_ hidden: Bool, animated: Bool) {
    if self.isHidden == hidden {
      return
    }
    
    if animated {
      self.isHidden = false
      self.alpha = hidden ? 1.0 : 0.0
      
      UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowAnimatedContent, .allowUserInteraction], animations: { () -> Void in
        self.alpha = hidden ? 0.0 : 1.0
      }, completion: { result in
        self.alpha = 1.0
        self.isHidden = hidden
      })
    } else {
      self.isHidden = hidden
    }
  }
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if let hitView = super.hitTest(point, with: event) , hitView != self {
      return hitView
    }
    return nil
  }
}
