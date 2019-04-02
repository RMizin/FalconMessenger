//
//  UserProfileContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

final class BioTextView: UITextView {
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(UIResponderStandardEditActions.paste(_:)) {
      return false
    }
    return super.canPerformAction(action, withSender: sender)
  }
}

final class PasteRestrictedTextField: UITextField {
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(UIResponderStandardEditActions.paste(_:)) {
      return false
    }
    return super.canPerformAction(action, withSender: sender)
  }
}

final class FalconProfileImageView: UIImageView {
	override var image: UIImage? {
		didSet {
			NotificationCenter.default.post(name: .profilePictureDidSet, object: nil)
		}
	}
}

final class UserProfileContainerView: UIView {
  
  lazy var profileImageView: FalconProfileImageView = {
    let profileImageView = FalconProfileImageView()
    profileImageView.translatesAutoresizingMaskIntoConstraints = false
    profileImageView.contentMode = .scaleAspectFill
    profileImageView.layer.masksToBounds = true
    profileImageView.layer.borderWidth = 1
    profileImageView.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    profileImageView.layer.cornerRadius = 48
    profileImageView.isUserInteractionEnabled = true

    return profileImageView
  }()
  
  let addPhotoLabel: UILabel = {
    let addPhotoLabel = UILabel()
    addPhotoLabel.translatesAutoresizingMaskIntoConstraints = false
    addPhotoLabel.text = "Add\nphoto"
    addPhotoLabel.numberOfLines = 2
    addPhotoLabel.textAlignment = .center

    return addPhotoLabel
  }()

  var name: PasteRestrictedTextField = {
    let name = PasteRestrictedTextField()
    name.font = UIFont.systemFont(ofSize: 20)
    name.enablesReturnKeyAutomatically = true
    name.translatesAutoresizingMaskIntoConstraints = false
    name.textAlignment = .center

		let placeholder = NSAttributedString(string: "Enter name",
																				 attributes: [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor])
		name.attributedPlaceholder = placeholder

    name.borderStyle = .none
    name.autocorrectionType = .no
    name.returnKeyType = .done
    name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    name.textColor = ThemeManager.currentTheme().generalTitleColor

    return name
  }()
  
  let phone: PasteRestrictedTextField = {
    let phone = PasteRestrictedTextField()
    phone.font = UIFont.systemFont(ofSize: 20)
    phone.translatesAutoresizingMaskIntoConstraints = false
    phone.textAlignment = .center
    phone.keyboardType = .numberPad
		let placeholder = NSAttributedString(string: "Phone number",
																				 attributes: [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor])
		phone.attributedPlaceholder = placeholder

    phone.borderStyle = .none
    phone.isEnabled = false
    phone.textColor = ThemeManager.currentTheme().generalSubtitleColor
    phone.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance

    return phone
  }()

  let bioPlaceholderLabel: UILabel = {
    let bioPlaceholderLabel = UILabel()
    bioPlaceholderLabel.text = "Bio"
    bioPlaceholderLabel.sizeToFit()
    bioPlaceholderLabel.textAlignment = .center
    bioPlaceholderLabel.backgroundColor = .clear
    bioPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
    bioPlaceholderLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor

    return bioPlaceholderLabel
  }()

  let userData: UIView = {
    let userData = UIView()
    userData.translatesAutoresizingMaskIntoConstraints = false
    userData.layer.cornerRadius = 30
    userData.layer.borderWidth = 1
    userData.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor

    return userData
  }()

  let bio: BioTextView = {
    let bio = BioTextView()
    bio.translatesAutoresizingMaskIntoConstraints = false
    bio.layer.cornerRadius = 28
    bio.layer.borderWidth = 1
    bio.textAlignment = .center
    bio.font = UIFont.systemFont(ofSize: 16)
    bio.isScrollEnabled = false
    bio.textContainerInset = UIEdgeInsets(top: 15, left: 35, bottom: 15, right: 35)
    bio.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    bio.backgroundColor = .clear
    bio.textColor = ThemeManager.currentTheme().generalTitleColor
    bio.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    bio.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    bio.textContainer.lineBreakMode = .byTruncatingTail
    bio.returnKeyType = .done

    return bio
  }()

  let countLabel: UILabel = {
    let countLabel = UILabel()
    countLabel.translatesAutoresizingMaskIntoConstraints = false
    countLabel.sizeToFit()
    countLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
    countLabel.isHidden = true

    return countLabel
  }()

  let bioMaxCharactersCount = 70


	fileprivate func configureColors() {
		backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		addPhotoLabel.textColor = ThemeManager.currentTheme().tintColor
	}

  override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(addPhotoLabel)
    addSubview(profileImageView)
    addSubview(userData)
    addSubview(bio)
    addSubview(countLabel)
    userData.addSubview(name)
    userData.addSubview(phone)
    bio.addSubview(bioPlaceholderLabel)

		configureColors()

		NotificationCenter.default.addObserver(self, selector: #selector(profilePictureDidSet), name: .profilePictureDidSet, object: nil)

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

        name.topAnchor.constraint(equalTo: userData.topAnchor, constant: 0),
        name.leftAnchor.constraint(equalTo: userData.leftAnchor, constant: 0),
        name.rightAnchor.constraint(equalTo: userData.rightAnchor, constant: 0),
        name.heightAnchor.constraint(equalToConstant: 50),

        phone.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 0),
        phone.leftAnchor.constraint(equalTo: userData.leftAnchor, constant: 0),
        phone.rightAnchor.constraint(equalTo: userData.rightAnchor, constant: 0),
        phone.heightAnchor.constraint(equalToConstant: 50),

        bio.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),

        countLabel.widthAnchor.constraint(equalToConstant: 30),
        countLabel.heightAnchor.constraint(equalToConstant: 30),
        countLabel.rightAnchor.constraint(equalTo: bio.rightAnchor, constant: -5),
        countLabel.bottomAnchor.constraint(equalTo: bio.bottomAnchor, constant: -5),

        bioPlaceholderLabel.centerXAnchor.constraint(equalTo: bio.centerXAnchor, constant: 0),
        bioPlaceholderLabel.centerYAnchor.constraint(equalTo: bio.centerYAnchor, constant: 0)
      ])

    bioPlaceholderLabel.font = UIFont.systemFont(ofSize: 20)//(bio.font!.pointSize - 1)
    bioPlaceholderLabel.isHidden = !bio.text.isEmpty

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        profileImageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
        bio.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
        bio.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
        userData.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10)
      ])
    } else {
      NSLayoutConstraint.activate([
        profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        bio.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        bio.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        userData.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
      ])
    }
  }

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }

	@objc func profilePictureDidSet() {
		if profileImageView.image == nil {
			addPhotoLabel.isHidden = false
		} else {
			addPhotoLabel.isHidden = true
		}
	}
}
