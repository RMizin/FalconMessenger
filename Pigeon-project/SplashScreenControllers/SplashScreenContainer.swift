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

  var navigationItem = UINavigationItem(title: AvatarOverlayTitle.user.rawValue)
  let localAuthenticationContext = LAContext()
  var bannersState: Bool!
  var soundsState: Bool!
  var vibrationState: Bool!
  
  var viewForSatausbarSafeArea: UIView = {
    var viewForSatausbarSafeArea = UIView()
    viewForSatausbarSafeArea.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    viewForSatausbarSafeArea.translatesAutoresizingMaskIntoConstraints = false
    
    return viewForSatausbarSafeArea
  }()
  
  var navigationBar: UINavigationBar = {
    var navigationBar = UINavigationBar()
    navigationBar.barTintColor = ThemeManager.currentTheme().generalBackgroundColor
    navigationBar.translatesAutoresizingMaskIntoConstraints = false
    
    return navigationBar
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    addSubview(navigationBar)
    addSubview(viewForSatausbarSafeArea)
    doesDeviceHaveBiometrics()

    if #available(iOS 11.0, *) {
      navigationBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    } else {
      navigationBar.topAnchor.constraint(equalTo: topAnchor, constant:20).isActive = true
    }
    
    navigationBar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    navigationBar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    navigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    viewForSatausbarSafeArea.topAnchor.constraint(equalTo: topAnchor).isActive = true
    viewForSatausbarSafeArea.bottomAnchor.constraint(equalTo: navigationBar.topAnchor).isActive = true
    viewForSatausbarSafeArea.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    viewForSatausbarSafeArea.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
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
      let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
      switch(authContext.biometryType) {
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
    var image = UIImage()
    let biometricType = SplashScreenContainer.biometricType()

    switch biometricType {
      case .touch:
        title = "Unlock with Touch ID"
        image = UIImage(named: "TouchID")!
        break
      case .face:
        title = "Unlock with Face ID"
        image = UIImage(named: "FaceID")!
        break
      default:
        title = "Unlock with Passcode"
        break
    }
    
    let biometricsButton = UIButton()
    let biometricsImageView = UIImageView()
    
    biometricsButton.setTitle(title, for: .normal)
    biometricsButton.setTitleColor(ThemeManager.currentTheme().generalTitleColor, for: .normal)
    biometricsButton.addTarget(self, action: #selector(authenticationWithTouchID), for: .touchUpInside)
    biometricsImageView.contentMode = .scaleAspectFit
    biometricsImageView.image = image
    biometricsButton.backgroundColor = ThemeManager.currentTheme().controlButtonsColor
    biometricsButton.layer.cornerRadius = 20
    
    biometricsButton.translatesAutoresizingMaskIntoConstraints = false
    biometricsImageView.translatesAutoresizingMaskIntoConstraints = false
    
    addSubview(biometricsButton)
    addSubview(biometricsImageView)
    
    biometricsButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    biometricsButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
    
    biometricsImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
    biometricsImageView.widthAnchor.constraint(equalToConstant: 200).isActive = true
    
    biometricsImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    biometricsImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -25).isActive = true
    
    biometricsButton.topAnchor.constraint(equalTo: biometricsImageView.bottomAnchor, constant: 10).isActive = true
    biometricsButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
  }
}
