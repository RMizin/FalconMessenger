//
//  AvatarOpenerOverlay.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 4/4/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

enum AvatarOverlayTitle: String {
  case user = "Profile Picture"
  case group = "Group Photo"
}

class AvatarOpenerOverlay: UIView {
  
  var navigationItem = UINavigationItem(title: AvatarOverlayTitle.user.rawValue)
  
  weak var photosViewController: INSPhotosViewController?
  
  var viewForSatausbarSafeArea: UIView = {
    var viewForSatausbarSafeArea = UIView()
    viewForSatausbarSafeArea.backgroundColor = UIColor.black
    viewForSatausbarSafeArea.alpha = 0.8
    viewForSatausbarSafeArea.translatesAutoresizingMaskIntoConstraints = false
    
    return viewForSatausbarSafeArea
  }()
  
  var viewForBottomSafeArea: UIView = {
    var viewForBottomSafeArea = UIView()
    viewForBottomSafeArea.backgroundColor = UIColor.black
    viewForBottomSafeArea.alpha = 0.8
    viewForBottomSafeArea.translatesAutoresizingMaskIntoConstraints = false
    
    return viewForBottomSafeArea
  }()
  
  var navigationBar: UINavigationBar = {
    var navigationBar = UINavigationBar()
    navigationBar.alpha = 0.8
    navigationBar.barStyle = .black
    navigationBar.isTranslucent = false
    navigationBar.clipsToBounds = true
    navigationBar.barTintColor = .black
    navigationBar.translatesAutoresizingMaskIntoConstraints = false
    
    return navigationBar
  }()
  
  var toolbar: UIToolbar = {
    var toolbar = UIToolbar()
    toolbar.alpha = 0.8
    toolbar.barTintColor = .black
    toolbar.barStyle = .black
    toolbar.isTranslucent = false
    toolbar.clipsToBounds = true
    toolbar.sizeToFit()
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    
    return toolbar
  }()
  
  func setOverlayTitle(title: AvatarOverlayTitle) {
    navigationItem.title = title.rawValue
  }
  
  private func configureNavigationBar() {
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(backButtonTapped))
    navigationBar.setItems([navigationItem], animated: true)
  }
  
  @objc func backButtonTapped() {
    photosViewController?.dismiss(animated: true, completion: nil)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    addSubview(navigationBar)
    addSubview(toolbar)
    addSubview(viewForSatausbarSafeArea)
    addSubview(viewForBottomSafeArea)
    
    toolbar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    toolbar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    toolbar.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    if #available(iOS 11.0, *) {
      toolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
      navigationBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    } else {
      toolbar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
      navigationBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
    
    navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    navigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    viewForSatausbarSafeArea.topAnchor.constraint(equalTo: topAnchor).isActive = true
    viewForSatausbarSafeArea.bottomAnchor.constraint(equalTo: navigationBar.topAnchor).isActive = true
    viewForSatausbarSafeArea.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    viewForSatausbarSafeArea.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    
    viewForBottomSafeArea.topAnchor.constraint(equalTo: toolbar.bottomAnchor).isActive = true
    viewForBottomSafeArea.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    viewForBottomSafeArea.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    viewForBottomSafeArea.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    
    configureNavigationBar()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}

extension AvatarOpenerOverlay: INSPhotosOverlayViewable {
	var bottomView: OverlayDefaultBottomView {
		return OverlayDefaultBottomView()
	}

  func populateWithPhoto(_ photo: INSPhotoViewable) {}
  
  func setHidden(_ hidden: Bool, animated: Bool) {
    if isHidden == hidden {
      return
    }
    
    if animated {
      isHidden = false
      alpha = hidden ? 1.0 : 0.0
      
      UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowAnimatedContent, .allowUserInteraction], animations: { [weak self] () -> Void in
        self?.alpha = hidden ? 0.0 : 1.0
      }, completion: { [weak self] result in
        self?.alpha = 1.0
        self?.isHidden = hidden
      })
    } else {
      isHidden = hidden
    }
  }
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if let hitView = super.hitTest(point, with: event) , hitView != self {
      return hitView
    }
    return nil
  }
}

