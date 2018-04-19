//
//  ViewControllerPlaceholder.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/6/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


enum ViewControllerPlaceholderPriority: CGFloat {
  case low = 0.1
  case medium = 0.5
  case high = 1.0
}

enum ViewControllerPlaceholderPosition {
  case top
  case center
}

class ViewControllerPlaceholder: UIView {
  
  var title = UILabel()
  var subtitle = UILabel()

  var placeholderPriority:ViewControllerPlaceholderPriority = .low
  
  let contactsAuthorizationDeniedtitle = "Falcon doesn't have access to your contacts"
  let contactsAuthorizationDeniedSubtitle = "Please go to your iPhone Settings –– Privacy –– Contacts. Then select ON for Falcon."
  
  let emptyFalconUsersTitle = "No Falcon users in your contacts yet."
  let emptyFalconUsersSubtitle = "You can invite your friends to Flacon Messenger at the Contacts tab  "
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .clear
  
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
  
  func addViewControllerPlaceholder(for view: UIView, title: String, subtitle: String, priority: ViewControllerPlaceholderPriority, position: ViewControllerPlaceholderPosition) {
    
    guard priority.rawValue >= placeholderPriority.rawValue else { return }
    placeholderPriority = priority
    self.title.text = title
    self.subtitle.text = subtitle
    
    if position == .center {
       self.title.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
    }
    if position == .top {
       self.title.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
    }

     DispatchQueue.main.async {
        view.addSubview(self)
    }
  }
  
  func removeViewControllerPlaceholder(from view: UIView, priority: ViewControllerPlaceholderPriority) {
    
    guard priority.rawValue >= placeholderPriority.rawValue else { return }
    for subview in view.subviews {
      if subview is ViewControllerPlaceholder {
        subview.removeFromSuperview()
      }
    }
  }
}
