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
    super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
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
    label.font = MessageFontsAppearance.defaultInformationMessageTextFont
    label.numberOfLines = 1
    label.textAlignment = .center
    label.textColor = ThemeManager.currentTheme().generalTitleColor
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = MessageFontsAppearance.defaultInformationMessageTextFont
    label.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    label.layer.masksToBounds = true
    label.layer.cornerRadius = 14
    label.sizeToFit()
    
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
    label.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    label.textColor = ThemeManager.currentTheme().generalTitleColor
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
