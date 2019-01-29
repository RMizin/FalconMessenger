//
//  ThemeManager.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import AVKit

extension NSNotification.Name {
  static let themeUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".themeUpdated")
}

struct ThemeManager {

	static var generalTintColor = TintPalette.blue {
		didSet {
			UIView.appearance().tintColor = generalTintColor
		}
	}
  
  static func applyTheme(theme: Theme) {
    userDefaults.updateObject(for: userDefaults.selectedTheme, with: theme.rawValue)
   
    UITabBar.appearance().barStyle = theme.barStyle
    UINavigationBar.appearance().isTranslucent = false
    UINavigationBar.appearance().barStyle = theme.barStyle
    UINavigationBar.appearance().barTintColor = theme.barBackgroundColor
    UITabBar.appearance().barTintColor = theme.barBackgroundColor
    UITableViewCell.appearance().selectionColor = ThemeManager.currentTheme().cellSelectionColor
		UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: theme.generalTitleColor]

		UIView.appearance().tintColor = generalTintColor
		UIView.appearance(whenContainedInInstancesOf: [AVPlayerViewController.self]).tintColor = .white

    NotificationCenter.default.post(name: .themeUpdated, object: nil)
  }
  
  static func currentTheme() -> Theme {
    if UserDefaults.standard.object(forKey: userDefaults.selectedTheme) == nil {
     // guard DeviceType.iPhoneX else { return .Default }
       return .Dark
    }
    if let storedTheme = userDefaults.currentIntObjectState(for: userDefaults.selectedTheme) {
      return Theme(rawValue: storedTheme)!
    } else {
      return .Default
    }
  }
}

//enum Tint: Int {
//	case Blue, Grey, Red
//}

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
      return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
    }
  }
  
  var cellSelectionColor: UIColor {
    switch self {
    case .Default:
      return  UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) //F1F1F1
    case .Dark:
      return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0) //191919
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
  
  var supplementaryViewTextColor: UIColor {
    switch self {
    case .Default:
      return .gray
    case .Dark:
      return .lightGray
    }
  }

	var sdWebImageActivityIndicator: SDWebImageActivityIndicator {
		switch self {
		case .Default:
			return SDWebImageActivityIndicator.gray
		case .Dark:
			return SDWebImageActivityIndicator.white
		}
	}
  
  var controlButtonsColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
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
  
  var scrollDownImage: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "arrowDownBlack")!
    case .Dark:
      return UIImage(named: "arrowDownWhite")!
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
      return UIImage(named: "FMIncomingFull")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    case .Dark:
      return UIImage(named: "FMIncomingFull")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    }
  }
  
  var incomingPartialBubble: UIImage {
    
    switch self {
    case .Default:
      return UIImage(named: "partialDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    case .Dark:
      return UIImage(named: "partialDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    }
  }
  
  var outgoingBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "FMOutgoingFull")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    case .Dark:
      return UIImage(named: "FMOutgoingFull")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    }
  }
  
  var outgoingPartialBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "partialDefaultOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    case .Dark:
      return UIImage(named: "partialDefaultOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    }
  }


  var outgoingBubbleTintColor: UIColor {
    switch self {
    case .Default:
      return ThemeManager.generalTintColor//UIColor(red: 0.55, green: 0.77, blue: 1.0, alpha: 1.0)//UIColor(red: 0.00, green: 0.50, blue: 1.00, alpha: 1.0)// FalconPalette.defaultBlue
    case .Dark:
      return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
    }
  }
  
  var incomingBubbleTintColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
    }
  }
  
  
  var selectedOutgoingBubbleTintColor: UIColor {
    switch self {
    case .Default:
      return  UIColor(red:0.00, green:0.50, blue:0.80, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1.0)
    }
  }
  
  var selectedIncomingBubbleTintColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.70, green: 0.70, blue: 0.70, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0)
    }
  }
  
  
 
  
  var incomingBubbleTextColor: UIColor {
    switch self {
    case .Default:
      return .black
    case .Dark:
      return .white
    }
  }
  
  var outgoingBubbleTextColor: UIColor {
    switch self {
    case .Default:
      return .white
    case .Dark:
      return .white
    }
  }
  
  var authorNameTextColor: UIColor {
    switch self {
    case .Default:
      return ThemeManager.generalTintColor//FalconPalette.defaultBlue
    case .Dark:
      return UIColor(red: 0.55, green: 0.77, blue: 1.0, alpha: 1.0)//ThemeManager.generalTintColor//UIColor(red: 0.55, green: 0.77, blue: 1.0, alpha: 1.0)
    }
  }

	// tint blue UIColor(red: 0.55, green: 0.77, blue: 1.0, alpha: 1.0)
  
  var outgoingProgressStrokeColor: UIColor {
    switch self {
    case .Default:
      return .white
    case .Dark:
      return .white
    }
  }
  
  var incomingProgressStrokeColor: UIColor {
    switch self {
    case .Default:
      return .black
    case .Dark:
      return .white
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
  
	var scrollBarStyle: UIScrollView.IndicatorStyle {
    switch self {
    case .Default:
      return .default
    case .Dark:
      return .white
    }
  }
  
//  var backgroundColor: UIColor {
//    switch self {
//    case .Default:
//      return UIColor.white
//    case .Dark:
//      return UIColor.black
//    }
//  }

//  var secondaryColor: UIColor {
//    switch self {
//    case .Default:
//      return UIColor(red: 242.0/255.0, green: 101.0/255.0, blue: 34.0/255.0, alpha: 1.0)
//    case .Dark:
//      return UIColor(red: 34.0/255.0, green: 128.0/255.0, blue: 66.0/255.0, alpha: 1.0)
//    }
//  }
}

struct TintPalette {
	static let blue = UIColor(red: 0.00, green: 0.55, blue: 1.00, alpha: 1.0)//UIColor(red: 0.00, green: 0.50, blue: 1.00, alpha: 1.0)
	static let grey = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
	static let red = UIColor.red
}

struct FalconPalette {
  //static let defaultBlue = UIColor(red:0.00, green:0.50, blue:1.00, alpha: 1.0)
  static let dismissRed = UIColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 1.0)
  static let appStoreGrey = UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
}
