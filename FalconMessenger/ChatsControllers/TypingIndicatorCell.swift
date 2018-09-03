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
    typingIndicator.frame = CGRect(x: 10, y: 2, width: 72, height: TypingIndicatorCell.typingIndicatorHeight).integral
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    restart()
  }
  
  deinit {
    typingIndicator.stopAnimating()
  }
  
  func restart() {
    typingIndicator.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    if typingIndicator.isAnimating {
      typingIndicator.stopAnimating()
      typingIndicator.startAnimating()
    } else {
      typingIndicator.startAnimating()
    }
  }
}
