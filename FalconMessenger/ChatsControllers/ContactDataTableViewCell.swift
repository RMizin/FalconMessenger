//
//  ContactDataTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 2/3/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ContactDataTableViewCell: UITableViewCell {

  let textField: UITextField = {
    let textField = UITextField()
    textField.placeholder = ""
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.font = UIFont.systemFont(ofSize: 20)
    textField.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    
    return textField
  }()
  
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    
    addSubview(textField)
    
    if #available(iOS 11.0, *) {
      textField.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
    } else {
      textField.leftAnchor.constraint(equalTo: leftAnchor, constant: 20).isActive = true
    }
    textField.heightAnchor.constraint(equalTo: heightAnchor, constant: 0).isActive = true
    textField.widthAnchor.constraint(equalTo: widthAnchor, constant: 0).isActive = true
    textField.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
  }
  override func prepareForReuse() {
    super.prepareForReuse()
    textField.keyboardType = .default
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
