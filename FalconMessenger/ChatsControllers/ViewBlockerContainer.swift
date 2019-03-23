//
//  ViewBlockerContainer.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/18/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ViewBlockerContainer: UIView {
  
  let label: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.textAlignment = .center
    label.sizeToFit()
    label.textColor = ThemeManager.currentTheme().supplementaryViewTextColor
    label.backgroundColor = .clear
    label.font = UIFont.boldSystemFont(ofSize: 16)
    label.text = "This user is not in your Falcon Contacts"

    return label
  }()
  
  let show: UIButton = {
    let show = UIButton()
    show.translatesAutoresizingMaskIntoConstraints = false
    show.setTitle("Show", for: .normal)
    show.contentHorizontalAlignment = .center
    show.contentVerticalAlignment = .center
    show.titleLabel?.sizeToFit()
    show.backgroundColor = ThemeManager.currentTheme().controlButtonColor
    show.layer.cornerRadius = 25
    show.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    show.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
    show.addTarget(self, action: #selector(ChatLogViewController.removeBlockerView), for: .touchUpInside)
    
    return show
  }()
  
  let blockAndDelete: UIButton = {
    let blockAndDelete = UIButton()
    blockAndDelete.translatesAutoresizingMaskIntoConstraints = false
    blockAndDelete.setTitle("Block And Delete", for: .normal)
    blockAndDelete.setTitleColor(FalconPalette.dismissRed, for: .normal)
    blockAndDelete.contentHorizontalAlignment = .center
    blockAndDelete.contentVerticalAlignment = .center
    blockAndDelete.titleLabel?.sizeToFit()
    blockAndDelete.backgroundColor = ThemeManager.currentTheme().controlButtonColor
    blockAndDelete.layer.cornerRadius = 25
    blockAndDelete.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    blockAndDelete.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
    blockAndDelete.addTarget(self, action: #selector(ChatLogViewController.blockAndDelete), for: .touchUpInside)
    
    return blockAndDelete
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		show.setTitleColor(ThemeManager.currentTheme().tintColor, for: .normal)

    addSubview(label)
    label.topAnchor.constraint(equalTo: topAnchor, constant: 40).isActive = true
    if #available(iOS 11.0, *) {
      label.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
      label.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
      
    } else {
      label.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
      label.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
    }
    
    addSubview(show)
    addSubview(blockAndDelete)
    show.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 40).isActive = true
    show.rightAnchor.constraint(equalTo: label.rightAnchor).isActive = true
    show.leftAnchor.constraint(equalTo: label.leftAnchor).isActive = true
    show.heightAnchor.constraint(equalToConstant: 55).isActive = true
    
    blockAndDelete.topAnchor.constraint(equalTo: show.bottomAnchor, constant: 20).isActive = true
    blockAndDelete.rightAnchor.constraint(equalTo: label.rightAnchor).isActive = true
    blockAndDelete.leftAnchor.constraint(equalTo: label.leftAnchor).isActive = true
    blockAndDelete.heightAnchor.constraint(equalToConstant: 55).isActive = true

    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func changeTheme() {
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }

  func remove(from view: UIView) {
    for subview in view.subviews where subview is ViewBlockerContainer {
      DispatchQueue.main.async {
        subview.removeFromSuperview()
      }
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
