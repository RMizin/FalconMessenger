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
    
    icon.layer.cornerRadius = 20
    icon.layer.masksToBounds = true
    
    
    return icon
  }()
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.systemFont(ofSize: 16)
    
    return title
  }()

  
  let separator: UIView = {
    let separator = UIView()
    separator.translatesAutoresizingMaskIntoConstraints = false
    separator.backgroundColor = UIColor.lightGray
    
    return separator
  }()

  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    
    backgroundColor = UIColor.white
    title.backgroundColor = backgroundColor
    icon.backgroundColor = backgroundColor
    
    contentView.addSubview(icon)
    icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
    icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
    icon.widthAnchor.constraint(equalToConstant: 40).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 40).isActive = true
    
    contentView.addSubview(title)
    title.centerYAnchor.constraint(equalTo: icon.centerYAnchor, constant: 0).isActive = true
    title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 15).isActive = true
    title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    title.heightAnchor.constraint(equalToConstant: 30).isActive = true
    
    addSubview(separator)
    separator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 70).isActive = true
    separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
    separator.heightAnchor.constraint(equalToConstant: 0.4).isActive = true
  }
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
