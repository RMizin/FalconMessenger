//
//  UserProfileContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class UserProfileContainerView: UIView, UITextFieldDelegate {
  
  lazy var profileImageView: UIImageView = {
    let profileImageView = UIImageView()
    profileImageView.translatesAutoresizingMaskIntoConstraints = false
    profileImageView.contentMode = .scaleAspectFill
    profileImageView.layer.masksToBounds = true
    profileImageView.layer.borderColor = UIColor.lightGray.cgColor
    profileImageView.layer.borderWidth = 1
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
  
 lazy var name: UITextField = {
    let name = UITextField()
    name.font = UIFont.systemFont(ofSize: 21)
    name.translatesAutoresizingMaskIntoConstraints = false
    name.textAlignment = .center
    //name.keyboardType = .numberPad
    name.placeholder = "Enter name"
    name.borderStyle = .roundedRect
    name.delegate = self
    //name.returnKeyType = .done
    name.autocorrectionType = .no
    //verificationCode.addTarget(self, action: #selector(EnterPhoneNumberController.textFieldDidChange(_:)), for: .editingChanged)
    
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
    //verificationCode.addTarget(self, action: #selector(EnterPhoneNumberController.textFieldDidChange(_:)), for: .editingChanged)
    
    return phone
  }()
  
// lazy var bio: UITextView = {
//    var bio = UITextView()
//    bio.translatesAutoresizingMaskIntoConstraints = false
//    
//  //  bio.translatesAutoresizingMaskIntoConstraints = false
//    bio.delegate = self
//    bio.font = UIFont.systemFont(ofSize: 16)
//    bio.sizeToFit()
//    bio.isScrollEnabled = false
//    bio.layer.borderColor = UIColor.lightGray.cgColor
//    bio.layer.borderWidth = 0.3
//    bio.layer.cornerRadius = 10
//    bio.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 8, right: 30)
//
//    return bio
//  }()
//  
//  let placeholderLabel: UILabel = {
//    let placeholderLabel = UILabel()
//    placeholderLabel.text = "Add bio"
//    placeholderLabel.sizeToFit()
//    placeholderLabel.textColor = UIColor.lightGray
//    
//    return placeholderLabel
//  }()
  
//  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//    textField.resignFirstResponder()
//    return true
//  }

  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(addPhotoLabel)
    addSubview(profileImageView)
    addSubview(name)
    addSubview(phone)
    addSubview(subtitleLabel)
    //addSubview(bio)
    //bio.addSubview(placeholderLabel)
    
//    placeholderLabel.font = UIFont.systemFont(ofSize: (bio.font?.pointSize)!)
//    placeholderLabel.frame.origin = CGPoint(x: 12, y: (bio.font?.pointSize)! / 2)
//    placeholderLabel.isHidden = !bio.text.isEmpty
    
    NSLayoutConstraint.activate([
      
     // profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
      profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
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
      subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
  
      name.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
      name.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      name.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      name.heightAnchor.constraint(equalToConstant: 50),
      
      phone.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 10),
      phone.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      phone.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      phone.heightAnchor.constraint(equalToConstant: 50)
  
//      bio.topAnchor.constraint(equalTo: phone.bottomAnchor, constant: 10),
//      bio.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
//      bio.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
//      bio.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
      
    ])
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  
  
//  func textViewDidChange(_ textView: UITextView) {
//    placeholderLabel.isHidden = !textView.text.isEmpty
//  }

}


