//
//  UserCell.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit
import Firebase


class UserCell: UITableViewCell {
  
    let profileImageView: UIImageView = {
      let imageView = UIImageView()
      imageView.translatesAutoresizingMaskIntoConstraints = false
      imageView.layer.cornerRadius = 27
      imageView.layer.masksToBounds = true
      imageView.contentMode = .scaleAspectFill
      imageView.image = UIImage(named: "UserpicIcon")
      
      return imageView
    }()
  
    let newMessageIndicator: UIImageView = {
      let newMessageIndicator = UIImageView()
      newMessageIndicator.translatesAutoresizingMaskIntoConstraints = false
      newMessageIndicator.layer.masksToBounds = true
      newMessageIndicator.contentMode = .scaleAspectFill
      newMessageIndicator.isHidden = true
      newMessageIndicator.image = UIImage(named: "Oval")
    
      return newMessageIndicator
    }()
  
    let timeLabel: UILabel = {
      let label = UILabel()
      label.font = UIFont.systemFont(ofSize: 10)
      label.textColor = UIColor.lightGray
      label.translatesAutoresizingMaskIntoConstraints = false
      label.sizeToFit()
      label.textAlignment = .right

      return label
    }()
  
    let nameLabel: UILabel = {
      let label = UILabel()
      label.font = UIFont.boldSystemFont(ofSize: 15)
      label.translatesAutoresizingMaskIntoConstraints = false
      label.sizeToFit()
    
      return label
    }()
  
    let messageLabel: UILabel = {
      let label = UILabel()
      label.font = UIFont.systemFont(ofSize: 13)
      label.textColor = UIColor.lightGray
      label.numberOfLines = 2
      label.translatesAutoresizingMaskIntoConstraints = false
      label.sizeToFit()
    
      return label
    }()
  
  let badgeLabel: UILabel = {
    let badgeLabel = UILabel()
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false
    badgeLabel.backgroundColor = PigeonPalette.pigeonPaletteBlue
    badgeLabel.layer.cornerRadius = 7
    badgeLabel.text = "1"
    badgeLabel.isHidden = true
    badgeLabel.textColor = .white
    badgeLabel.textAlignment = .center
    badgeLabel.layer.masksToBounds = true
    badgeLabel.font = UIFont.systemFont(ofSize: 10)

    return badgeLabel
  }()

  
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
      
        contentView.addSubview(newMessageIndicator)
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(badgeLabel)
      
        profileImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 26).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 54).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 54).isActive = true
      
        newMessageIndicator.rightAnchor.constraint(equalTo: profileImageView.leftAnchor, constant: -7).isActive = true
        newMessageIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        newMessageIndicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
        newMessageIndicator.heightAnchor.constraint(equalToConstant: 12).isActive = true
      
        let tlWidth = contentView.frame.width - profileImageView.frame.width - 200
        nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 7).isActive = true
        nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: tlWidth).isActive = true
      
        messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 7).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: badgeLabel.leftAnchor, constant: -5).isActive = true
  
        timeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        timeLabel.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 5).isActive = true
      
        badgeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        badgeLabel.widthAnchor.constraint(equalToConstant: 20).isActive = true
        badgeLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        badgeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
    }
  
  
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
  override func prepareForReuse() {
    super.prepareForReuse()
   // if profileImageView.image == nil {
       profileImageView.image = UIImage(named: "UserpicIcon")
    //}
   
    nameLabel.text = ""
    messageLabel.text = nil
    timeLabel.text = nil
    badgeLabel.isHidden = true
  }
}
