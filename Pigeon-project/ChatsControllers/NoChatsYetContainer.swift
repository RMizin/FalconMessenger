//
//  NoChatsYetContainer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/13/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class NoChatsYetContainer: UIView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .white
    
    let noChatsYetTitle = UILabel()
    noChatsYetTitle.text = "You don't have any active conversations yet."
    noChatsYetTitle.font = .systemFont(ofSize: 18)
    noChatsYetTitle.textColor = .gray
    noChatsYetTitle.textAlignment = .center
    noChatsYetTitle.numberOfLines = 0
    noChatsYetTitle.translatesAutoresizingMaskIntoConstraints = false
    
    let noChatsYetFAQ = UILabel()
    noChatsYetFAQ.text = "You can select somebody in Contacts, and send you first message."
    noChatsYetFAQ.font = .systemFont(ofSize: 13)
    noChatsYetFAQ.textColor = .gray
    noChatsYetFAQ.textAlignment = .center
    noChatsYetFAQ.numberOfLines = 0
    noChatsYetFAQ.translatesAutoresizingMaskIntoConstraints = false
    
    addSubview(noChatsYetTitle)
    noChatsYetTitle.topAnchor.constraint(equalTo: topAnchor, constant: 100).isActive = true
    noChatsYetTitle.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
    noChatsYetTitle.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
    noChatsYetTitle.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    addSubview(noChatsYetFAQ)
    noChatsYetFAQ.topAnchor.constraint(equalTo: noChatsYetTitle.bottomAnchor, constant: 20).isActive = true
    noChatsYetFAQ.leftAnchor.constraint(equalTo: leftAnchor, constant: 35).isActive = true
    noChatsYetFAQ.rightAnchor.constraint(equalTo: rightAnchor, constant: -35).isActive = true
    noChatsYetFAQ.heightAnchor.constraint(equalToConstant: 60).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

