//
//  ThemeManager.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//



import UIKit

let SelectedThemeKey = "SelectedTheme"

enum Theme: Int {
  case Default, Dark
  
  var generalBackgroundColor: UIColor {
    switch self {
    case .Default:
      return UIColor.white
    case .Dark:
      return .black
    }
  }
  
  var barBackgroundColor: UIColor {
    switch self {
    case .Default:
      return .white
    case .Dark:
      return .black
    }
  }
  
  
  var generalTitleColor: UIColor {
    switch self {
    case .Default:
      return UIColor.black
    case .Dark:
      return UIColor.white
    }
  }
  
  var generalSubtitleColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red:0.67, green:0.67, blue:0.67, alpha:1.0)
    case .Dark:
      return UIColor(red:0.67, green:0.67, blue:0.67, alpha:1.0)
    }
  }
  
  var cellSelectionColor: UIColor {
    switch self {
    case .Default:
      return  UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0) //F1F1F1
    case .Dark:
      return UIColor(red:0.10, green:0.10, blue:0.10, alpha:1.0) //191919
    }
  }
  
  var inputTextViewColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
    }
  }
  
  var controlButtonsColor: UIColor {
    switch self {
    case .Default:
      return   UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.0)
    case .Dark:
      return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
    }
  }
  
  var searchBarColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 0.5)
    case .Dark:
      return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 0.8)
    }
  }
  
  var mediaPickerControllerBackgroundColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 209.0/255.0, green: 213.0/255.0, blue: 218.0/255.0, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)
    }
  }
  
  var splashImage: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "whiteSplash")!
    case .Dark:
      return UIImage(named: "blackSplash")!
    }
  }
  
  var enterPhoneNumberBackground: UIImage {
    switch self {
    case .Default:
      return  UIImage(named: "LightAuthCountryButtonNormal")!
    case .Dark:
      return UIImage(named: "DarkAuthCountryButtonNormal")!
    }
  }
  
  var enterPhoneNumberBackgroundSelected: UIImage {
    switch self {
    case .Default:
      return UIImage(named:"LightAuthCountryButtonHighlighted")!
    case .Dark:
      return UIImage(named:"DarkAuthCountryButtonHighlighted")!
    }
  }
  
  var personalStorageImage: UIImage {
    switch self {
    case .Default:
      return  UIImage(named: "PersonalStorage")!
    case .Dark:
      return UIImage(named: "PersonalStorage")!
    }
  }
  
  var incomingBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "FMIncomingFull")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16)
    case .Dark:
      return UIImage(named: "FMIncomingFull")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16)
    }
  }
  
  var selectedIncomingBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "FMIncomingFullHighlighted")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16)
    case .Dark:
      return UIImage(named: "FMIncomingFullHighlighted")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16)
    }
  }
  
  var incomingPartialBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "partialDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16)
    case .Dark:
      return UIImage(named: "partialDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16)
    }
  }
  
  var selectedIncomingPartialBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "partialSelectedDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16)
    case .Dark:
      return UIImage(named: "partialSelectedDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16)
    }
  }
  
  var outgoingBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "FMOutgoingFull")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16)
    case .Dark:
      return UIImage(named: "FMOutgoingFull")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16)
    }
  }
  
  var selectedOutgoingBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "FMOutgoingFullHighlighted")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16)
    case .Dark:
      return UIImage(named: "FMOutgoingFullHighlighted")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16)
    }
  }
  
  var outgoingPartialBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "partialDefaultOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16)
    case .Dark:
      return UIImage(named: "partialDefaultOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16)
    }
  }
  
  var selectedOutgoingPartialBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "partialSelectedOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16)
    case .Dark:
      return UIImage(named: "partialSelectedOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16)
    }
  }
  
  var keyboardAppearance: UIKeyboardAppearance {
    switch self {
    case .Default:
      return  .default
    case .Dark:
      return .dark
    }
  }

  var barStyle: UIBarStyle {
    switch self {
    case .Default:
      return .default
    case .Dark:
      return .black
    }
  }
  
  var statusBarStyle: UIStatusBarStyle {
    switch self {
    case .Default:
      return .default
    case .Dark:
      return .lightContent
    }
  }
  
  var scrollBarStyle: UIScrollViewIndicatorStyle {
    switch self {
    case .Default:
      return .default
    case .Dark:
      return .white
    }
  }
  
  var backgroundColor: UIColor {
    switch self {
    case .Default:
      return UIColor.white
    case .Dark:
      return UIColor.black
    }
  }
  
  var secondaryColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 242.0/255.0, green: 101.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    case .Dark:
      return UIColor(red: 34.0/255.0, green: 128.0/255.0, blue: 66.0/255.0, alpha: 1.0)
  
    }
  }
}


func setGlobalNavigationBarSettingsAccordingToTheme(theme: Theme) {
  UITabBar.appearance().barStyle = theme.barStyle
  UINavigationBar.appearance().isTranslucent = false
  UINavigationBar.appearance().barStyle = theme.barStyle
  UINavigationBar.appearance().barTintColor = theme.barBackgroundColor
  UITabBar.appearance().barTintColor = theme.barBackgroundColor
  UITableViewCell.appearance().selectionColor = ThemeManager.currentTheme().cellSelectionColor
  UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: theme.generalTitleColor]
}

struct ThemeManager {
  
  static func applyTheme(theme: Theme) {
    UserDefaults.standard.set(theme.rawValue, forKey: SelectedThemeKey)
    UserDefaults.standard.synchronize()
    setGlobalNavigationBarSettingsAccordingToTheme(theme: theme)
  }
  
  static func currentTheme() -> Theme {
    if let storedTheme = UserDefaults.standard.value(forKey: SelectedThemeKey) as? Theme.RawValue {
      return Theme(rawValue: storedTheme)!
    } else {
      return .Default
    }
  }
}


struct FalconPalette {
  static let defaultBlue = UIColor(red:0.00, green:0.50, blue:1.00, alpha: 1.0)
  static let dismissRed = UIColor(red:1.00, green:0.23, blue:0.19, alpha:1.0)
  static let appStoreGrey = UIColor(red:0.94, green:0.94, blue:0.96, alpha:1.0)
}
