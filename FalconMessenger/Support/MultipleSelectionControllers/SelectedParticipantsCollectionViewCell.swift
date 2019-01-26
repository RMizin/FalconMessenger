//
//  SelectedParticipantsCollectionViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SelectedParticipantsCollectionViewCell: UICollectionViewCell {
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.semibold)
    title.textColor = .white
    title.textAlignment = .center
    
    return title
  }()

  
  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.layer.cornerRadius = 10
    backgroundColor = .clear
    title.backgroundColor = backgroundColor

    contentView.addSubview(title)
    title.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
    title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
    title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    title.heightAnchor.constraint(equalToConstant: 25).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    title.text = ""
  }

}

