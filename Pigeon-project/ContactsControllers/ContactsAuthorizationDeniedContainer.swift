//
//  ContactsAuthorizationDeniedContainer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/6/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class ContactsAuthorizationDeniedContainer: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .white
    
    let accessRestrictedTitle = UILabel()
    accessRestrictedTitle.text = "Falcon does not have access to your contacts"
    accessRestrictedTitle.font = .systemFont(ofSize: 18)
    accessRestrictedTitle.textColor = .gray
    accessRestrictedTitle.textAlignment = .center
    accessRestrictedTitle.numberOfLines = 0
    accessRestrictedTitle.translatesAutoresizingMaskIntoConstraints = false
    
    let accessRestrictedFAQ = UILabel()
    accessRestrictedFAQ.text = "Please go to your iPhone Settings –– Privacy –– Contacts. Then select ON for Falcon."
    accessRestrictedFAQ.font = .systemFont(ofSize: 13)
    accessRestrictedFAQ.textColor = .gray
    accessRestrictedFAQ.textAlignment = .center
    accessRestrictedFAQ.numberOfLines = 0
    accessRestrictedFAQ.translatesAutoresizingMaskIntoConstraints = false
    
    addSubview(accessRestrictedTitle)
    accessRestrictedTitle.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
    accessRestrictedTitle.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
    accessRestrictedTitle.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
    accessRestrictedTitle.heightAnchor.constraint(equalToConstant: 45).isActive = true
    
    addSubview(accessRestrictedFAQ)
    accessRestrictedFAQ.topAnchor.constraint(equalTo: accessRestrictedTitle.bottomAnchor, constant: 5).isActive = true
    accessRestrictedFAQ.leftAnchor.constraint(equalTo: leftAnchor, constant: 35).isActive = true
    accessRestrictedFAQ.rightAnchor.constraint(equalTo: rightAnchor, constant: -35).isActive = true
    accessRestrictedFAQ.heightAnchor.constraint(equalToConstant: 50).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
