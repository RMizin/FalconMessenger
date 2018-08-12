//
//  PrivacyTableViewCell.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class PrivacyTableViewCell: UITableViewCell {
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.systemFont(ofSize: 18)
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    
    return title
  }()
  
  var switchAccessory: UISwitch = {
    var switchAccessory = UISwitch()
    switchAccessory.translatesAutoresizingMaskIntoConstraints = false
   
    return switchAccessory
  }()
  
  var switchTapAction: ((Bool)->Void)?

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    switchAccessory.addTarget(self, action: #selector(switchStateDidChange(_:)), for: .valueChanged)
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    selectionStyle = .none
    
    addSubview(switchAccessory)
    addSubview(title)

    switchAccessory.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    switchAccessory.widthAnchor.constraint(equalToConstant: 60).isActive = true
    
    if #available(iOS 11.0, *) {
      switchAccessory.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
    } else {
      switchAccessory.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }

    title.centerYAnchor.constraint(equalTo: switchAccessory.centerYAnchor).isActive = true
    title.rightAnchor.constraint(equalTo: switchAccessory.leftAnchor).isActive = true
    
    if #available(iOS 11.0, *) {
      title.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
    } else {
      title.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc func switchStateDidChange(_ sender: UISwitch) {
    switchTapAction?(sender.isOn)
  }
}
