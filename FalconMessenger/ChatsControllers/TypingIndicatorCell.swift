//
//  TypingIndicatorCell.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class TypingIndicatorCell: UICollectionViewCell {
  
  static let typingIndicatorHeight: CGFloat = 45
  
  var typingIndicator: TypingBubble = {
    var typingIndicator = TypingBubble()
    typingIndicator.typingIndicator.isBounceEnabled = true
    typingIndicator.typingIndicator.isFadeEnabled = true
    typingIndicator.isPulseEnabled = true
  
    return typingIndicator
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame.integral)
   
    addSubview(typingIndicator)
    typingIndicator.frame = CGRect(x: 10, y: 0, width: 72, height: TypingIndicatorCell.typingIndicatorHeight).integral
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func restart() {
 
    if typingIndicator.isAnimating {
      typingIndicator.stopAnimating()
      typingIndicator.startAnimating()
    } else {
      typingIndicator.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
      typingIndicator.startAnimating()
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    restart()
  }
}
