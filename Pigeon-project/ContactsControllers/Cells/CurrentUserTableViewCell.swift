//
//  CurrentUserTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/24/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class CurrentUserTableViewCell: UITableViewCell {
  
  var icon: UIImageView = {
    var icon = UIImageView()
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.contentMode = .scaleAspectFill
    
    icon.layer.cornerRadius = 26
    icon.layer.masksToBounds = true
    icon.image = ThemeManager.currentTheme().personalStorageImage
    
    return icon
  }()
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    return title
  }()
  
  
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    

    backgroundColor = .clear
    title.backgroundColor = backgroundColor
    icon.backgroundColor = backgroundColor
    
    contentView.addSubview(icon)
    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
    icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
    icon.widthAnchor.constraint(equalToConstant: 55).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 55).isActive = true
    
    contentView.addSubview(title)
    title.centerYAnchor.constraint(equalTo: icon.centerYAnchor, constant: 0).isActive = true
    title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true
    title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    title.heightAnchor.constraint(equalToConstant: 55).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    print("prepare for reuser")
    
    icon.image = UIImage(named: "PersonalStorage")
    title.text = ""
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    
  }
  
}

