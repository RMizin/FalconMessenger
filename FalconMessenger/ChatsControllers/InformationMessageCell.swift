//
//  InformationMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/25/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class InformationMessageCell: UICollectionViewCell {
  
  let information: UILabel = {
    let information = UILabel()
    information.font = MessageFontsAppearance.defaultInformationMessageTextFont
    information.numberOfLines = 2
    information.textAlignment = .center
    information.lineBreakMode = .byWordWrapping
    information.textColor = ThemeManager.currentTheme().generalSubtitleColor
    information.translatesAutoresizingMaskIntoConstraints = false
   
    return information
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame.integral)
    backgroundColor = .clear
    contentView.backgroundColor = backgroundColor
    information.backgroundColor = backgroundColor
    
    addSubview(information)
    information.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    information.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
    information.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setupData(message: Message) {
    guard let messageText = message.text else { return }
    information.text = messageText
  }
}
