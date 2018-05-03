//
//  FalconUsersTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

class FalconUsersTableViewCell: UITableViewCell {

  var icon: UIImageView = {
    var icon = UIImageView()
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.contentMode = .scaleAspectFill
    
    icon.layer.cornerRadius = 25
    icon.layer.masksToBounds = true
    icon.image = UIImage(named: "UserpicIcon")
    
    return icon
  }()
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    
    return title
  }()
  
  var subtitle: UILabel = {
    var subtitle = UILabel()
    subtitle.translatesAutoresizingMaskIntoConstraints = false
    subtitle.font = UIFont.systemFont(ofSize: 14.5)
    subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
    
    return subtitle
  }()

  let spacing: CGFloat = 15

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    
    backgroundColor = .clear
    title.backgroundColor = backgroundColor
    icon.backgroundColor = backgroundColor
    
    contentView.addSubview(icon)
    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
    icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing).isActive = true
    icon.widthAnchor.constraint(equalToConstant: 50).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    contentView.addSubview(title)
    title.topAnchor.constraint(equalTo: icon.topAnchor, constant: 0).isActive = true
    title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: spacing).isActive = true
    title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing).isActive = true
    title.heightAnchor.constraint(equalToConstant: 25).isActive = true
    
    contentView.addSubview(subtitle)
    subtitle.bottomAnchor.constraint(equalTo: icon.bottomAnchor, constant: 0).isActive = true
    subtitle.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: spacing).isActive = true
    subtitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing).isActive = true
    subtitle.heightAnchor.constraint(equalToConstant: 25).isActive = true
  }
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
   
    icon.image = UIImage(named: "UserpicIcon")
    icon.sd_cancelCurrentImageLoad()
    title.text = ""
    subtitle.text = ""
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
  }

}
