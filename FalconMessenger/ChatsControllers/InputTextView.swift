//
//  InputTextView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


struct InputTextViewLayout {
 
  static let maxContainerViewHeight: CGFloat = 220
  static let maxContainerViewHeightLandscape4Inch: CGFloat = 88
  static let maxContainerViewHeightLandscape47Inch: CGFloat = 125
  static let maxContainerViewHeightLandscape5558inch: CGFloat = 125
  
  static let maxContainerViewHeightLandscapeIpad: CGFloat = 220
  static let maxContainerViewHeightLandscapeIpadPro: CGFloat = 350
  
  static let maxContainerViewHeightPortraitIpad: CGFloat = 400
  static let maxContainerViewHeightPortraitIpadPro: CGFloat = 550
 
  static let minHeight: CGFloat = 50
  static let extendedInsets = UIEdgeInsets(top: 175, left: 8, bottom: 8, right: 30)
  static let defaultInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 30)
  
  static func maxHeight() -> CGFloat {
    guard UIDevice.current.orientation.isLandscape else {

      if DeviceType.IS_IPAD_PRO {
        return InputTextViewLayout.maxContainerViewHeightPortraitIpadPro
      } else if DeviceType.isIPad {
        return InputTextViewLayout.maxContainerViewHeightPortraitIpad
      } else if DeviceType.iPhone5orSE {
        return InputTextViewLayout.maxContainerViewHeight
      } else if DeviceType.iPhone678 {
        return InputTextViewLayout.maxContainerViewHeight
      } else if DeviceType.iPhone678p || DeviceType.iPhoneX {
        return InputTextViewLayout.maxContainerViewHeight
      } else {
        return InputTextViewLayout.maxContainerViewHeight
      }
    }
    
    if DeviceType.IS_IPAD_PRO {
      return InputTextViewLayout.maxContainerViewHeightLandscapeIpadPro
    } else if DeviceType.isIPad {
      return InputTextViewLayout.maxContainerViewHeightLandscapeIpad
    } else if DeviceType.iPhone5orSE {
      return InputTextViewLayout.maxContainerViewHeightLandscape4Inch
    } else if DeviceType.iPhone678 {
      return InputTextViewLayout.maxContainerViewHeightLandscape47Inch
    } else if DeviceType.iPhone678p || DeviceType.iPhoneX {
      return InputTextViewLayout.maxContainerViewHeightLandscape5558inch
    } else {
      return InputTextViewLayout.maxContainerViewHeightLandscape4Inch
    }
  }
}

class InputTextView: UITextView {
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
   
    font = UIFont.systemFont(ofSize: 18)
    isScrollEnabled = false
    layer.cornerRadius = 18
    textContainerInset = InputTextViewLayout.defaultInsets
    changeTheme()
  }
  
  func changeTheme () {
    keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    textColor = ThemeManager.currentTheme().generalTitleColor
    backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
