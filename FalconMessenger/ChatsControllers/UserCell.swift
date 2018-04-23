//
//  UserCell.swift
//  Avalon-print
//
//  Created by Roman Mizin on 3/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit
import Firebase
import SDWebImage


class UserCell: UITableViewCell {
  
  var typingIndicatorTimer: Timer? = Timer()
  
  let profileImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = 30
    imageView.layer.masksToBounds = true
    imageView.contentMode = .scaleAspectFill
    
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
  
  let muteIndicator: UIImageView = {
    let muteIndicator = UIImageView()
    muteIndicator.translatesAutoresizingMaskIntoConstraints = false
    muteIndicator.layer.masksToBounds = true
    muteIndicator.contentMode = .scaleAspectFit
    muteIndicator.isHidden = true
    muteIndicator.image = UIImage(named: "mute")
    
    return muteIndicator
  }()
  
  let timeLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 13)
    label.textColor = ThemeManager.currentTheme().generalSubtitleColor
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .right

    return label
  }()

  let nameLabel: UILabel = {
    let label = UILabel()
    label.textColor = ThemeManager.currentTheme().generalTitleColor
    label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.sizeToFit()
  
    return label
  }()

  let messageLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = ThemeManager.currentTheme().generalSubtitleColor
    label.numberOfLines = 2
    label.translatesAutoresizingMaskIntoConstraints = false
    label.sizeToFit()
  
    return label
  }()
  
  var badgeLabelWidthConstraint: NSLayoutConstraint!
  var messageLabelRightConstraint: NSLayoutConstraint!
  let badgeLabelWidthConstant: CGFloat = 20
  let badgeLabelRightConstant: CGFloat = -15
  let messageLabelRightConstant: CGFloat = -5
  
  let badgeLabel: UILabel = {
    let badgeLabel = UILabel()
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false
    badgeLabel.backgroundColor = FalconPalette.defaultBlue
    badgeLabel.layer.cornerRadius = 10
    badgeLabel.text = "1"
    badgeLabel.isHidden = true
    badgeLabel.textColor = .white
    badgeLabel.textAlignment = .center
    badgeLabel.layer.masksToBounds = true
    badgeLabel.font = UIFont.systemFont(ofSize: 13)
    badgeLabel.adjustsFontSizeToFitWidth = true
    badgeLabel.sizeToFit()

    return badgeLabel
  }()
  
  var timeLabelWidthAnchor: NSLayoutConstraint!

  
  func timeLabelWidth(text: String) -> CGFloat {
    let font = UIFont.systemFont(ofSize: 14)
    let width = text.capitalized.sizeOfString(usingFont: font).width
    return width
  }
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
  
    backgroundColor = .clear
    contentView.addSubview(newMessageIndicator)
    contentView.addSubview(muteIndicator)
    contentView.addSubview(profileImageView)
    contentView.addSubview(nameLabel)
    contentView.addSubview(messageLabel)
    contentView.addSubview(timeLabel)
    contentView.addSubview(badgeLabel)
  
    newMessageIndicator.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 7).isActive = true
    newMessageIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    newMessageIndicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
    newMessageIndicator.heightAnchor.constraint(equalToConstant: 12).isActive = true
  
    profileImageView.leftAnchor.constraint(equalTo: newMessageIndicator.rightAnchor, constant: 7).isActive = true
    profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    profileImageView.widthAnchor.constraint(equalToConstant: 62).isActive = true
    profileImageView.heightAnchor.constraint(equalToConstant: 62).isActive = true
 
    timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
    timeLabelWidthAnchor = timeLabel.widthAnchor.constraint(equalToConstant: 60)
    timeLabelWidthAnchor.isActive = true
  
    nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor).isActive = true
    nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 7).isActive = true
    nameLabel.rightAnchor.constraint(lessThanOrEqualTo: timeLabel.leftAnchor, constant: -17).isActive = true
  
    messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2).isActive = true
    messageLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 7).isActive = true
    messageLabelRightConstraint = messageLabel.rightAnchor.constraint(equalTo: badgeLabel.leftAnchor, constant: messageLabelRightConstant)
    messageLabelRightConstraint.isActive = true

    timeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
  
    muteIndicator.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 3).isActive = true
    muteIndicator.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor, constant: 0).isActive = true
    muteIndicator.widthAnchor.constraint(equalToConstant: 12).isActive = true
    muteIndicator.heightAnchor.constraint(equalToConstant: 12).isActive = true

    badgeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: badgeLabelRightConstant).isActive = true
    badgeLabelWidthConstraint = badgeLabel.widthAnchor.constraint(equalToConstant: badgeLabelWidthConstant)
    badgeLabelWidthConstraint.isActive = true
    badgeLabel.heightAnchor.constraint(equalToConstant: badgeLabelWidthConstant).isActive = true
    badgeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
 
  @objc func updateTypingIndicatorTimer() {
    guard let messageText = messageLabel.text else { return }
    let dotCount: Int = messageLabel.text!.count - messageText.replacingOccurrences(of: ".", with: "").count + 1
    DispatchQueue.main.async {
      self.messageLabel.text = "typing"
    }
    var addOn: String = "."
    if dotCount <= 4 {
      addOn = "".padding(toLength: dotCount, withPad: ".", startingAt: 0)
    }
    DispatchQueue.main.async {
      self.messageLabel.text = self.messageLabel.text!.appending(addOn)
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    profileImageView.image = nil
    profileImageView.sd_cancelCurrentImageLoad()
    nameLabel.text = ""
    messageLabel.text = nil
    timeLabel.text = nil
    badgeLabel.isHidden = true
    muteIndicator.isHidden = true
    newMessageIndicator.isHidden = true
    nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    typingIndicatorTimer?.invalidate()
  }
}
