//
//  GroupProfileTableHeaderContainer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


class GroupProfileTableHeaderContainer: UIView {
  
  lazy var profileImageView: UIImageView = {
    let profileImageView = UIImageView()
    profileImageView.translatesAutoresizingMaskIntoConstraints = false
    profileImageView.contentMode = .scaleAspectFill
    profileImageView.layer.masksToBounds = true
    profileImageView.layer.borderWidth = 1
    profileImageView.layer.borderColor = ThemeManager.currentTheme().generalSubtitleColor.cgColor//ThemeManager.currentTheme().inputTextViewColor.cgColor
    profileImageView.layer.cornerRadius = 48
    profileImageView.isUserInteractionEnabled = true
  
    return profileImageView
  }()

  
  let addPhotoLabelAdminText = "Add\nphoto"
  let addPhotoLabelRegularText = "No photo\nprovided"
  
  let addPhotoLabel: UILabel = {
    let addPhotoLabel = UILabel()
    addPhotoLabel.translatesAutoresizingMaskIntoConstraints = false
    addPhotoLabel.numberOfLines = 2
    addPhotoLabel.textColor = FalconPalette.defaultBlue
    addPhotoLabel.textAlignment = .center
    
    return addPhotoLabel
  }()

  var name: PasteRestrictedTextField = {
    let name = PasteRestrictedTextField()
    name.enablesReturnKeyAutomatically = true
    name.font = UIFont.systemFont(ofSize: 20)
    name.translatesAutoresizingMaskIntoConstraints = false
    name.textAlignment = .center
    name.attributedPlaceholder = NSAttributedString(string:"Group name", attributes:[NSAttributedStringKey.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor])
    name.borderStyle = .none
    name.autocorrectionType = .no
    name.returnKeyType = .done
    name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
   
    return name
  }()

  let userData: UIView = {
    let userData = UIView()
    userData.translatesAutoresizingMaskIntoConstraints = false
    userData.layer.cornerRadius = 30
    userData.layer.borderWidth = 1
    userData.layer.borderColor = ThemeManager.currentTheme().generalSubtitleColor.cgColor
    
    return userData
  }()

  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(addPhotoLabel)
    addSubview(profileImageView)
    addSubview(userData)
   
    userData.addSubview(name)
   
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    addPhotoLabel.text = addPhotoLabelAdminText
    
    NSLayoutConstraint.activate([
      profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 30),
      profileImageView.widthAnchor.constraint(equalToConstant: 100),
      profileImageView.heightAnchor.constraint(equalToConstant: 100),
      
      addPhotoLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
      addPhotoLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
      addPhotoLabel.widthAnchor.constraint(equalToConstant: 100),
      addPhotoLabel.heightAnchor.constraint(equalToConstant: 100),
      
      userData.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 0),
      userData.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 10),
      userData.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 0),
      
      name.centerYAnchor.constraint(equalTo: userData.centerYAnchor, constant: 0),
      name.leftAnchor.constraint(equalTo: userData.leftAnchor, constant: 0),
      name.rightAnchor.constraint(equalTo: userData.rightAnchor, constant: 0),
      name.heightAnchor.constraint(equalToConstant: 50),
    ])

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        profileImageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
        userData.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
      ])
    } else {
      NSLayoutConstraint.activate([
        profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        userData.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      ])
    }
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}
