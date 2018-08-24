//
//  TimestampView.swift
//  RevealableCell
//
//  Created by Shaps Mohsenin on 03/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class TimestampView: RevealableView {
  
  var titleLabel: UILabel = {
    var titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0
    titleLabel.font = MessageFontsAppearance.defaultTimestampTextFont
  
    return titleLabel
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)   
    width = CellSizes.timestampWidth()
    
    addSubview(titleLabel)
    titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
    titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    titleLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    titleLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    
    titleLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}
