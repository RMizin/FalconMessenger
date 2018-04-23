//
//  ContactsTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/7/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class ContactsTableViewCell: UITableViewCell {

  
  var icon: UIImageView = {
    var icon = UIImageView()
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.contentMode = .scaleAspectFill
    icon.layer.cornerRadius = 25
    icon.layer.masksToBounds = true
    
    return icon
  }()
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    
    return title
  }()
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    
    backgroundColor = .clear
    title.backgroundColor = backgroundColor
    icon.backgroundColor = backgroundColor
    
    contentView.addSubview(icon)
    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
    icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
    icon.widthAnchor.constraint(equalToConstant: 50).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    contentView.addSubview(title)
    title.centerYAnchor.constraint(equalTo: icon.centerYAnchor, constant: 0).isActive = true
    title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true
    title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    title.heightAnchor.constraint(equalToConstant: 46).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    title.text = ""
    icon.image = UIImage(named: "UserpicIcon")
  }
}
