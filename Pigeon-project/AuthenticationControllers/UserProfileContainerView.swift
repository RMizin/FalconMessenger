//
//  UserProfileContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class UserProfileContainerView: UIView {
  
  lazy var profileImageView: UIImageView = {
    let profileImageView = UIImageView()
    profileImageView.translatesAutoresizingMaskIntoConstraints = false
    profileImageView.contentMode = .scaleAspectFill
    profileImageView.layer.masksToBounds = true
    profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    profileImageView.layer.borderWidth = 0.5
    profileImageView.layer.cornerRadius = 48
    profileImageView.isUserInteractionEnabled = true
    
    return profileImageView
  }()
  
  let addPhotoLabel: UILabel = {
    let addPhotoLabel = UILabel()
    addPhotoLabel.translatesAutoresizingMaskIntoConstraints = false
    addPhotoLabel.text = "Add\nphoto"
    addPhotoLabel.numberOfLines = 2
    addPhotoLabel.textColor = PigeonPalette.pigeonPaletteBlue
    addPhotoLabel.textAlignment = .center
    
    return addPhotoLabel
  }()
  
  let subtitleLabel: UILabel = {
    let subtitleLabel = UILabel()
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.text = "Enter your name and add an optional profile picture"
    subtitleLabel.numberOfLines = 2
    subtitleLabel.textColor = UIColor.lightGray
    subtitleLabel.font = UIFont.systemFont(ofSize: 15)
    subtitleLabel.textAlignment = .left
    
    return subtitleLabel
  }()
  
  var name: UITextField = {
    let name = UITextField()
    name.font = UIFont.systemFont(ofSize: 21)
    name.translatesAutoresizingMaskIntoConstraints = false
    name.textAlignment = .center
    name.placeholder = "Enter name"
    name.borderStyle = .roundedRect
    name.autocorrectionType = .no
  
    return name
  }()
  
  let phone: UITextField = {
    let phone = UITextField()
    phone.font = UIFont.systemFont(ofSize: 21)
    phone.translatesAutoresizingMaskIntoConstraints = false
    phone.textAlignment = .center
    phone.keyboardType = .numberPad
    phone.placeholder = "Phone number"
    phone.borderStyle = .roundedRect
    phone.isEnabled = false
    phone.textColor = UIColor.gray
   
    return phone
  }()
  
  let placeholderLabel: UILabel = {
    let placeholderLabel = UILabel()
    placeholderLabel.text = "Add bio"
    placeholderLabel.sizeToFit()
    placeholderLabel.textColor = UIColor.lightGray
    
    return placeholderLabel
  }()
  
 
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(addPhotoLabel)
    addSubview(profileImageView)
    addSubview(name)
    addSubview(phone)
    addSubview(subtitleLabel)
    
    name.delegate = self
    phone.delegate = self
  
      NSLayoutConstraint.activate([
        profileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 30),
        profileImageView.widthAnchor.constraint(equalToConstant: 100),
        profileImageView.heightAnchor.constraint(equalToConstant: 100),
        
        addPhotoLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
        addPhotoLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
        addPhotoLabel.widthAnchor.constraint(equalToConstant: 100),
        addPhotoLabel.heightAnchor.constraint(equalToConstant: 100),
        
        subtitleLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 0),
        subtitleLabel.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 0),
        subtitleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
        
        name.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
        name.heightAnchor.constraint(equalToConstant: 50),
        
        phone.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 10),
        phone.heightAnchor.constraint(equalToConstant: 50)
      ])
    
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        profileImageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
        subtitleLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
        name.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
        name.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
        phone.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
        phone.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
    } else {
      NSLayoutConstraint.activate([
        profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        name.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        name.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        phone.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        phone.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
      ])
    }
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}

extension UserProfileContainerView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
