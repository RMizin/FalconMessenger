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
    
  let dummyView: UIView = {
     let dummyView = UIView()
    dummyView.translatesAutoresizingMaskIntoConstraints = false

    return dummyView
  }()
  
  let subviewsHeight:CGFloat = 50
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    dummyView.backgroundColor = backgroundColor

    addSubview(dummyView)
    dummyView.addSubview(backButton)
    dummyView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    dummyView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    dummyView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    dummyView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    backButton.topAnchor.constraint(equalTo: dummyView.topAnchor).isActive = true
    backButton.leftAnchor.constraint(equalTo: dummyView.leftAnchor).isActive = true
    backButton.rightAnchor.constraint(equalTo: dummyView.rightAnchor).isActive = true
    backButton.heightAnchor.constraint(equalToConstant: subviewsHeight).isActive = true
  }
  
  func configureHeight(superview: UIView) {
    frame = CGRect(x: 0, y: 0, width: superview.bounds.width, height: accessoryHeight(taking: subviewsHeight, superview: superview))
  }
  
  private func accessoryHeight(taking subviewsHeight: CGFloat, superview: UIView) -> CGFloat {
    var height = subviewsHeight
    if #available(iOS 11.0, *), superview.safeAreaInsets.bottom != 0 {
      let bottomInset: CGFloat = 20
      height = subviewsHeight + bottomInset
    }
    return height
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
