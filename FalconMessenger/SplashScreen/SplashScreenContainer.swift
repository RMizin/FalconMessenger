//
//  SplashScreenContainer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 4/16/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import LocalAuthentication

enum BiometricType: Int {
  case none = 0
  case touch = 1
  case face = 2
}

class SplashScreenContainer: UIView {

  let localAuthenticationContext = LAContext()
  var bannersState: Bool!
  var soundsState: Bool!
  var vibrationState: Bool!

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    doesDeviceHaveBiometrics()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }

  func doesDeviceHaveBiometrics() {
    let type = SplashScreenContainer.biometricType()
    userDefaults.updateObject(for: userDefaults.biometricType, with: type.rawValue)
  }

  static func biometricType() -> BiometricType {
    let authContext = LAContext()
    if #available(iOS 11, *) {
      _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
      switch authContext.biometryType {
      case .none:
        return .none
      case .touchID:
        return .touch
      case .faceID:
        return .face
			@unknown default:
				fatalError()
			}
    } else {
      return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touch : .none
    }
  }

  func configureSplashForBiometrics() {

    var title = ""
    let biometricType = SplashScreenContainer.biometricType()

    switch biometricType {
    case .touch:
      title = "Unlock with Touch ID"
      break
    case .face:
      title = "Unlock with Face ID"
      break
    default:
      title = "Unlock with Passcode"
      break
    }

    let biometricsButton = UIButton()
    biometricsButton.setTitle(title, for: .normal)
    biometricsButton.setTitleColor(ThemeManager.currentTheme().generalTitleColor, for: .normal)
    biometricsButton.addTarget(self, action: #selector(authenticationWithTouchID), for: .touchUpInside)
    biometricsButton.backgroundColor = ThemeManager.currentTheme().controlButtonColor
    biometricsButton.layer.cornerRadius = 20
    biometricsButton.translatesAutoresizingMaskIntoConstraints = false

    addSubview(biometricsButton)
    biometricsButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    biometricsButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
    biometricsButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
		biometricsButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
  }
}
