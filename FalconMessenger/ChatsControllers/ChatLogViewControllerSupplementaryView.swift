//
//  ChatLogViewControllerSupplementaryView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/29/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SupplementaryLabel: UILabel {
  
  var topInset: CGFloat = 5.0
  var bottomInset: CGFloat = 5.0
  var leftInset: CGFloat = 10.0
  var rightInset: CGFloat = 10.0
  
  override func drawText(in rect: CGRect) {
    let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
    super.drawText(in: rect.inset(by: insets))
  }
  
  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(width: size.width + leftInset + rightInset,
                  height: size.height + topInset + bottomInset)
  }
}

class ChatLogViewControllerSupplementaryView: UICollectionReusableView {

  let label: SupplementaryLabel = {
    let label = SupplementaryLabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 1
    label.textAlignment = .center
    label.layer.masksToBounds = true
    label.layer.cornerRadius = 13
    label.sizeToFit()
    label.textColor = ThemeManager.currentTheme().supplementaryViewTextColor
    label.backgroundColor = ThemeManager.currentTheme().inputTextViewColor.withAlphaComponent(0.85)
    label.font = UIFont.boldSystemFont(ofSize: 13)
 
    return label
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(label)
    label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func changeTheme() {
    label.backgroundColor = ThemeManager.currentTheme().inputTextViewColor.withAlphaComponent(0.85)
    label.textColor = ThemeManager.currentTheme().supplementaryViewTextColor
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
