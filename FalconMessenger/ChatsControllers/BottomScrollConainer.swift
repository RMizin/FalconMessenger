//
//  BottomScrollConainer.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/27/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class BottomScrollConainer: UIView {

  var scrollButton: UIButton = {
    let scrollButton = UIButton()
    scrollButton.translatesAutoresizingMaskIntoConstraints = false
    scrollButton.imageView?.contentMode = .scaleAspectFit
    scrollButton.contentMode = .center

    scrollButton.imageEdgeInsets = UIEdgeInsets(top: 7, left: 10, bottom: 3, right: 10)

    return scrollButton
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    changeTheme()
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    
    addSubview(scrollButton)
    scrollButton.layer.cornerRadius = 22.5
    scrollButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
    scrollButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    scrollButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    scrollButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc fileprivate func changeTheme() {
    scrollButton.setImage(ThemeManager.currentTheme().scrollDownImage, for: .normal)
    scrollButton.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
  }
}
