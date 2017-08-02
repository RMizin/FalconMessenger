//
//  EnterPhoneNumberContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class EnterPhoneNumberContainerView: UIView {

  
  let viewTitle: UILabel = {
    let viewTitle = UILabel()
   // viewTitle.text = NSLocalizedString("PasswordResetContainerView.viewTitle.text", comment: "")
    viewTitle.font =  UIFont.systemFont(ofSize: 24)
    viewTitle.translatesAutoresizingMaskIntoConstraints = false
    
    return viewTitle
  }()
  
  let email: UITextField = {
    let email = UITextField()
  //  email.placeholder = NSLocalizedString("PasswordResetContainerView.email.placeholder", comment: "")
    email.translatesAutoresizingMaskIntoConstraints = false
   // email.addTarget(self, action: #selector(PasswordResetViewController.recoverEmailTextFieldEditingChanged(_:)), for: .editingChanged)
    email.keyboardType = .emailAddress
    
    return email
  }()
  
 
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    
    
    addSubview(viewTitle)
    viewTitle.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
    viewTitle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    
    addSubview(email)
    email.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    email.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -26).isActive = true
    email.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
    email.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
    email.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  

}
