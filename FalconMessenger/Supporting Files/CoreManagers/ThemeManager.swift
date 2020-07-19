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
import ARSLineProgress

extension NSNotification.Name {
  static let themeUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".themeUpdated")
}

struct ThemeManager {

  static func applyTheme(theme: Theme) {
    userDefaults.updateObject(for: userDefaults.selectedTheme, with: theme.rawValue)

		ARSLineProgressConfiguration.backgroundViewColor = ThemeManager.currentTheme().inputTextViewColor.withAlphaComponent(0.5).cgColor
		ARSLineProgressConfiguration.blurStyle = ThemeManager.currentTheme().arsLineProgressBlurStyle
		ARSLineProgressConfiguration.circleColorMiddle = ThemeManager.currentTheme().tintColor.cgColor
		ARSLineProgressConfiguration.circleColorInner = ThemeManager.currentTheme().tintColor.cgColor

    UITabBar.appearance().barStyle = theme.barStyle
    UINavigationBar.appearance().isTranslucent = false
    UINavigationBar.appearance().barStyle = theme.barStyle
    UINavigationBar.appearance().barTintColor = theme.barBackgroundColor

    if #available(iOS 13.0, *) {
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        coloredAppearance.titleTextAttributes = [.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
    }


		UITabBar.appearance().tintColor = theme.tabBarTintColor
    UITabBar.appearance().barTintColor = theme.barBackgroundColor
    UITableViewCell.appearance().selectionColor = ThemeManager.currentTheme().cellSelectionColor
		UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: theme.generalTitleColor]
		UIView.appearance().tintColor = theme.tintColor

		UIView.appearance(whenContainedInInstancesOf: [INSPhotosViewController.self]).tintColor = .white
		UIView.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = theme.barTintColor

    NotificationCenter.default.post(name: .themeUpdated, object: nil)
  }
  
  static func currentTheme() -> Theme {
    if UserDefaults.standard.object(forKey: userDefaults.selectedTheme) == nil {
       return .Dark
    }
    if let storedTheme = userDefaults.currentIntObjectState(for: userDefaults.selectedTheme) {
      return Theme(rawValue: storedTheme)!
    } else {
      return .Default
    }
  }

    static func setNavigationBarAppearance(_ naviationBar: UINavigationBar) {
        if #available(iOS 13.0, *) {
            let coloredAppearance = UINavigationBarAppearance()
            coloredAppearance.configureWithOpaqueBackground()
            coloredAppearance.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            coloredAppearance.titleTextAttributes = [.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
            coloredAppearance.largeTitleTextAttributes = [.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
            naviationBar.standardAppearance = coloredAppearance
            naviationBar.scrollEdgeAppearance = coloredAppearance
            naviationBar.compactAppearance = coloredAppearance
        }
    }
}

enum Theme: Int {
  case Default, Dark, LivingCoral

	var tintColor: UIColor {
		switch self {
		case .Default:
			return TintPalette.blue
		case .Dark:
			return TintPalette.blue
		case .LivingCoral:
			return TintPalette.livingCoral
		}
	}

  var generalBackgroundColor: UIColor {
    switch self {
    case .Default:
      return .white
    case .Dark:
      return .black
		case .LivingCoral:
			return .white
		}
  }

	var barTintColor: UIColor {
		switch self {
		case .Default:
			return tintColor
		case .Dark:
			return tintColor
		case .LivingCoral:
			return tintColor
		}
	}

	var tabBarTintColor: UIColor {
		switch self {
		case .Default:
			return tintColor
		case .Dark:
			return tintColor
		case .LivingCoral:
			return tintColor
		}
	}

	var unselectedButtonTintColor: UIColor {
		switch self {
		case .Default:
			return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
		case .Dark:
			return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
		case .LivingCoral:
			return TintPalette.livingCoralExtraLight
		}
	}

	var selectedButtonTintColor: UIColor {
		switch self {
		case .Default:
			return tintColor
		case .Dark:
			return tintColor
		case .LivingCoral:
			return tintColor
		}
	}
  
  var barBackgroundColor: UIColor {
    switch self {
    case .Default:
      return .white
    case .Dark:
      return .black
		case .LivingCoral:
			return .white
		}
  }

	var barTextColor: UIColor {
		switch self {
		case .Default:
			return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
		case .Dark:
			return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
		case .LivingCoral:
			return tintColor
		}
	}

	var controlButtonTintColor: UIColor {
		switch self {
		case .Default:
			return tintColor
		case .Dark:
			return tintColor
		case .LivingCoral:
			return tintColor
		}
	}

  var generalTitleColor: UIColor {
    switch self {
    case .Default:
      return UIColor.black
    case .Dark:
      return UIColor.white
		case .LivingCoral:
			return UIColor.black
		}
  }

	var chatLogTitleColor: UIColor {
		switch self {
		case .Default:
			return .black
		case .Dark:
			return .white
		case .LivingCoral:
			return .black
		}
	}
  
  var generalSubtitleColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
		case .LivingCoral:
			return UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0)
		}
  }
  
  var cellSelectionColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) //F1F1F1
    case .Dark:
      return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0) //191919
		case .LivingCoral:
			return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) //F1F1F1
		}
  }
  
  var inputTextViewColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
		case .LivingCoral:
			return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
		}
  }
  
  var supplementaryViewTextColor: UIColor {
    switch self {
    case .Default:
      return .gray
    case .Dark:
      return .lightGray
		case .LivingCoral:
			return .gray
		}
  }

	var sdWebImageActivityIndicator: SDWebImageActivityIndicator {
		switch self {
		case .Default:
			return SDWebImageActivityIndicator.gray
		case .Dark:
			return SDWebImageActivityIndicator.white
		case .LivingCoral:
			return SDWebImageActivityIndicator.gray
		}
	}
  
  var controlButtonColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
		case .LivingCoral:
			return UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
		}
  }

	var controlButtonHighlightingColor: UIColor {
		switch self {
		case .Default:
			return UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0) //F1F1F1
		case .Dark:
			return UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0) //191919
		case .LivingCoral:
			return UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0) //F1F1F1
		}
	}

	var muteRowActionBackgroundColor: UIColor {
		switch self {
		case .Default:
			return TintPalette.lightBlue
		case .Dark:
			return controlButtonHighlightingColor
		case .LivingCoral:
			return TintPalette.livingCoralLight
		}
	}

	var pinRowActionBackgroundColor: UIColor {
		switch self {
		case .Default:
			return TintPalette.blue
		case .Dark:
			return controlButtonColor
		case .LivingCoral:
			return TintPalette.livingCoral
		}
	}

  var searchBarColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 0.5)
    case .Dark:
      return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 0.8)
		case .LivingCoral:
			return UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 0.5)
		}
  }

  var mediaPickerControllerBackgroundColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 209.0/255.0, green: 213.0/255.0, blue: 218.0/255.0, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)
		case .LivingCoral:
			return UIColor(red: 209.0/255.0, green: 213.0/255.0, blue: 218.0/255.0, alpha: 1.0)
		}
  }

  var scrollDownImage: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "arrowDownBlack")!
    case .Dark:
      return UIImage(named: "arrowDownWhite")!
		case .LivingCoral:
			return UIImage(named: "arrowDownBlack")!
		}
  }
  
  var personalStorageImage: UIImage {
    switch self {
    case .Default:
      return  UIImage(named: "PersonalStorage")!
    case .Dark:
      return UIImage(named: "PersonalStorage")!
		case .LivingCoral:
			return UIImage(named: "PersonalStorage")!
		}
  }
  
  var incomingBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "FMIncomingFull")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    case .Dark:
      return UIImage(named: "FMIncomingFull")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
		case .LivingCoral:
			 return UIImage(named: "FMIncomingFull")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
		}
  }
  
  var incomingPartialBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "partialDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    case .Dark:
      return UIImage(named: "partialDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
		case .LivingCoral:
			 return UIImage(named: "partialDefaultIncoming")!.stretchableImage(withLeftCapWidth: 23, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
		}
  }
  
  var outgoingBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "FMOutgoingFull")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    case .Dark:
      return UIImage(named: "FMOutgoingFull")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
		case .LivingCoral:
			return UIImage(named: "FMOutgoingFull")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
		}
  }
  
  var outgoingPartialBubble: UIImage {
    switch self {
    case .Default:
      return UIImage(named: "partialDefaultOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
    case .Dark:
      return UIImage(named: "partialDefaultOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
		case .LivingCoral:
			return UIImage(named: "partialDefaultOutgoing")!.stretchableImage(withLeftCapWidth: 17, topCapHeight: 16).withRenderingMode(.alwaysTemplate)
		}
  }

  var outgoingBubbleTintColor: UIColor {
    switch self {
    case .Default:
      return tintColor
    case .Dark:
      return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
		case .LivingCoral:
			return tintColor
		}
  }
  
  var incomingBubbleTintColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
		case .LivingCoral:
			return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
		}
  }
  
  var selectedOutgoingBubbleTintColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.00, green: 0.50, blue: 0.80, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1.0)
		case .LivingCoral:
			return TintPalette.livingCoralExtraLight
		}
  }
  
  var selectedIncomingBubbleTintColor: UIColor {
    switch self {
    case .Default:
      return UIColor(red: 0.70, green: 0.70, blue: 0.70, alpha: 1.0)
    case .Dark:
      return UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0)
		case .LivingCoral:
			return UIColor(red: 0.70, green: 0.70, blue: 0.70, alpha: 1.0)
		}
  }
  
  var incomingBubbleTextColor: UIColor {
    switch self {
    case .Default:
      return .black
    case .Dark:
      return .white
		case .LivingCoral:
			return .black
		}
  }
  
  var outgoingBubbleTextColor: UIColor {
    switch self {
    case .Default:
      return .white
    case .Dark:
      return .white
		case .LivingCoral:
			return .white
		}
  }
  
  var authorNameTextColor: UIColor {
    switch self {
    case .Default:
      return tintColor
    case .Dark:
      return UIColor(red: 0.55, green: 0.77, blue: 1.0, alpha: 1.0)
		case .LivingCoral:
			return tintColor
		}
  }

  var outgoingProgressStrokeColor: UIColor {
    switch self {
    case .Default:
      return .white
    case .Dark:
      return .white
		case .LivingCoral:
			return .white
		}
  }
  
  var incomingProgressStrokeColor: UIColor {
    switch self {
    case .Default:
      return .black
    case .Dark:
      return .white
		case .LivingCoral:
			return .black
		}
  }
  
  var keyboardAppearance: UIKeyboardAppearance {
    switch self {
    case .Default:
      return .default
    case .Dark:
      return .dark
		case .LivingCoral:
			return .default
		}
  }

  var barStyle: UIBarStyle {
    switch self {
    case .Default:
      return .default
    case .Dark:
      return .black
		case .LivingCoral:
			return .default
		}
  }
  
  var statusBarStyle: UIStatusBarStyle {
    switch self {
    case .Default:
      return .default
    case .Dark:
      return .lightContent
		case .LivingCoral:
			return .default
		}
  }
  
	var scrollBarStyle: UIScrollView.IndicatorStyle {
    switch self {
    case .Default:
      return .default
    case .Dark:
      return .white
		case .LivingCoral:
			return .default
		}
  }

	var arsLineProgressBlurStyle: UIBlurEffect.Style {
		switch self {
		case .Default:
			return .light
		case .Dark:
			return .dark
		case .LivingCoral:
			return .light
		}
	}
}

struct TintPalette {
	static let blue = UIColor(red: 0.00, green: 0.55, blue: 1.00, alpha: 1.0)
	static let lightBlue = UIColor(red: 0.13, green: 0.61, blue: 1.00, alpha: 1.0)
	static let grey = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
	static let red = UIColor.red
	static let livingCoral = UIColor(red: 0.98, green: 0.45, blue: 0.41, alpha: 1.0)
	static let livingCoralLight = UIColor(red: 0.99, green: 0.69, blue: 0.67, alpha: 1.0)
	static let livingCoralExtraLight = UIColor(red: 0.99, green: 0.81, blue: 0.80, alpha: 1.0)
}

struct FalconPalette {
  static let dismissRed = UIColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 1.0)
  static let appStoreGrey = UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
}
