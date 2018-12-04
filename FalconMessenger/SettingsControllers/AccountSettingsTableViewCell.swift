//
//  AccountSettingsTableViewCell.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class AccountSettingsTableViewCell: UITableViewCell {
  
  var icon: UIImageView = {
    var icon = UIImageView()
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.contentMode = .scaleAspectFit
    
    return icon
  }()
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.systemFont(ofSize: 18)
    title.textColor = ThemeManager.currentTheme().generalTitleColor
  
    return title
  }()
  
  let separator: UIView = {
    let separator = UIView()
    separator.translatesAutoresizingMaskIntoConstraints = false
    separator.backgroundColor = UIColor.clear
    
    return separator
  }()
  
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    
    setColor()
    contentView.addSubview(icon)
    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
    icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
    icon.widthAnchor.constraint(equalToConstant: 30).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 30).isActive = true
    
    contentView.addSubview(title)
    title.centerYAnchor.constraint(equalTo: icon.centerYAnchor, constant: 0).isActive = true
    title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true
    title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    title.heightAnchor.constraint(equalToConstant: 30).isActive = true
    
    addSubview(separator)
    separator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
    separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15).isActive = true
    separator.heightAnchor.constraint(equalToConstant: 0.4).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  fileprivate func setColor() {
    backgroundColor = .clear
    accessoryView?.backgroundColor = .clear
    title.backgroundColor = .clear
    icon.backgroundColor = .clear
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    selectionColor = ThemeManager.currentTheme().cellSelectionColor
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    setColor()
  }
}
