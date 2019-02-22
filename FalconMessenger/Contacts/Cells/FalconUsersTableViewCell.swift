//
//  FalconUsersTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import Contacts

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

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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

  func configureCell(for parameter: NSObject?) {
		guard let parameter = parameter else { return }
    if let contact = parameter as? CNContact {
      configureContact(contact)
    } else if let user = parameter as? User {
      configureUser(user)
    }
  }

  fileprivate func configureUser(_ user: User) {
    title.text = user.name ?? ""
		subtitle.text = user.onlineStatusString
		if user.onlineStatusString == statusOnline {
			subtitle.textColor = tintColor
		} else {
			subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
		}

    guard let urlString = user.thumbnailPhotoURL else { return }
    let options: SDWebImageOptions = [.scaleDownLargeImages, .continueInBackground, .avoidAutoSetImage]
    let placeholder = UIImage(named: "UserpicIcon")
    icon.sd_setImage(with: URL(string: urlString),
                     placeholderImage: placeholder,
                     options: options) { (image, _, cacheType, _) in
      guard image != nil else { return }
      guard cacheType != .memory, cacheType != .disk else {
        self.icon.image = image
        return
      }
      UIView.transition(with: self.icon, duration: 0.2, options: .transitionCrossDissolve, animations: {
        self.icon.image = image
      }, completion: nil)
    }
  }

  fileprivate func configureContact(_ contact: CNContact) {
    title.text = contact.givenName + " " + contact.familyName

    if let thumbnail = contact.thumbnailImageData {
      icon.image = UIImage(data: thumbnail)
    } else {
      icon.image = UIImage(named: "UserpicIcon")
    }

    if contact.phoneNumbers.indices.contains(0) {
      let phoneNumber = contact.phoneNumbers[0].value.stringValue
      subtitle.text = phoneNumber
    } else {
      subtitle.text = "No phone number provided"
    }
  }
}
