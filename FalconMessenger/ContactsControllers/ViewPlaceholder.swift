//
//  ViewPlaceholder.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/6/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

enum ViewPlaceholderPriority: CGFloat {
  case low = 0.1
  case medium = 0.5
  case high = 1.0
}

enum ViewPlaceholderPosition {
  case top
  case center
}

enum ViewPlaceholderTitle: String {
  case denied = "Falcon doesn't have access to your contacts"
  case empty = "You don't have any Falcon Users yet."
  case emptyChat = "You don't have any active conversations yet."
	case emptySharedMedia = "You don't have any shared media yet."
}

enum ViewPlaceholderSubtitle: String {
  case denied = "Please go to your iPhone Settings –– Privacy –– Contacts. Then select ON for Falcon."
  case empty = "You can invite your friends to Flacon Messenger at the Contacts tab  "
  case emptyChat = "You can select somebody in Contacts, and send your first message."
	case emptyString = ""
}

class ViewPlaceholder: UIView {

  var title = UILabel()
  var subtitle = UILabel()

  var placeholderPriority: ViewPlaceholderPriority = .low

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    translatesAutoresizingMaskIntoConstraints = false
  
    title.font = .systemFont(ofSize: 18)
    title.textColor = ThemeManager.currentTheme().generalSubtitleColor
    title.textAlignment = .center
    title.numberOfLines = 0
    title.translatesAutoresizingMaskIntoConstraints = false

    subtitle.font = .systemFont(ofSize: 13)
    subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
    subtitle.textAlignment = .center
    subtitle.numberOfLines = 0
    subtitle.translatesAutoresizingMaskIntoConstraints = false

    addSubview(title)

    title.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
    title.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
    title.heightAnchor.constraint(equalToConstant: 45).isActive = true

    addSubview(subtitle)
    subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5).isActive = true
    subtitle.leftAnchor.constraint(equalTo: leftAnchor, constant: 35).isActive = true
    subtitle.rightAnchor.constraint(equalTo: rightAnchor, constant: -35).isActive = true
    subtitle.heightAnchor.constraint(equalToConstant: 50).isActive = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func add(for view: UIView, title: ViewPlaceholderTitle, subtitle: ViewPlaceholderSubtitle,
           priority: ViewPlaceholderPriority, position: ViewPlaceholderPosition) {

    guard priority.rawValue >= placeholderPriority.rawValue else { return }
    placeholderPriority = priority
    self.title.text = title.rawValue
    self.subtitle.text = subtitle.rawValue

    if position == .center {
      self.title.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
    }
    if position == .top {
      self.title.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
    }

     DispatchQueue.main.async {
      view.addSubview(self)
      self.topAnchor.constraint(equalTo: view.topAnchor, constant: 135).isActive = true
      self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
      self.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20).isActive = true
    }
  }

  func remove(from view: UIView, priority: ViewPlaceholderPriority) {
    guard priority.rawValue >= placeholderPriority.rawValue else { return }
    for subview in view.subviews where subview is ViewPlaceholder {
      DispatchQueue.main.async {
        subview.removeFromSuperview()
      }
    }
  }
}
