//
//  TypingIndicatorCell.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class TypingIndicatorCell: UICollectionViewCell {
  
  var typingIndicator: UIImageView = {
    var typingIndicator = UIImageView()
    typingIndicator.image =  UIImage.sd_animatedGIFNamed("typingIndicator")
    typingIndicator.frame = CGRect(x: 10, y: 0, width: 65, height: 40)
    typingIndicator.backgroundColor = .white
    return typingIndicator
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(typingIndicator)
  }
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override func prepareForReuse() {
    super.prepareForReuse()
    typingIndicator.image =  UIImage.sd_animatedGIFNamed("typingIndicator")
  }
}
