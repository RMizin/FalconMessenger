//
//  InputBlockerContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/25/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class InputBlockerContainerView: UIView {
  
  let backButton: UIButton = {
    let backButton = UIButton()
    backButton.setTitleColor(FalconPalette.dismissRed, for: .normal)
    backButton.translatesAutoresizingMaskIntoConstraints = false
    backButton.setTitle("Delete and Exit", for: .normal)
    backButton.backgroundColor = .clear
    
    return backButton
  }()
  
  private var heightConstraint: NSLayoutConstraint!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    
    heightConstraint = heightAnchor.constraint(equalToConstant: InputTextViewLayout.minHeight)
    heightConstraint.isActive = true
    
    changeTheme()

    addSubview(backButton)
    backButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
    backButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    backButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    backButton.heightAnchor.constraint(equalToConstant: InputTextViewLayout.minHeight).isActive = true
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func changeTheme() {
    backgroundColor = ThemeManager.currentTheme().inputTextViewColor
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
