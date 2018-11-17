//
//  SplashScreenContainer+BiometricalControl.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 4/16/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import LocalAuthentication

extension SplashScreenContainer {

  func showSecuredData() {
    restoreNotificationsState()

    let isBiometricalAuthEnabled = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
    guard isBiometricalAuthEnabled else { return }
    DispatchQueue.main.async {
      self.removeFromSuperview()
    }
  }

  func temporaryDisableNotifications() {
    guard bannersState == nil, soundsState == nil, vibrationState == nil else { return }
    bannersState = userDefaults.currentBoolObjectState(for: userDefaults.inAppNotifications)
    soundsState = userDefaults.currentBoolObjectState(for: userDefaults.inAppSounds)
    vibrationState = userDefaults.currentBoolObjectState(for: userDefaults.inAppVibration)
    userDefaults.updateObject(for: userDefaults.inAppNotifications, with: false)
    userDefaults.updateObject(for: userDefaults.inAppSounds, with: false)
    userDefaults.updateObject(for: userDefaults.inAppVibration, with: false)
  }
  
  func restoreNotificationsState() {
    guard bannersState != nil, soundsState != nil, vibrationState != nil else { return }
    userDefaults.updateObject(for: userDefaults.inAppNotifications, with: bannersState)
    userDefaults.updateObject(for: userDefaults.inAppSounds, with: soundsState)
    userDefaults.updateObject(for: userDefaults.inAppVibration, with: vibrationState)
  }
  
  @objc func authenticationWithTouchID() {
    var authError: NSError?
    let reason = "To get access to the Falcon Messenger"
    temporaryDisableNotifications()

    guard localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
      guard let error = authError else { return }
      self.showPasscodeController(error: error, reason: reason)
      let biometricType = userDefaults.currentIntObjectState(for: userDefaults.biometricType)
      if biometricType == 0 {
        DispatchQueue.main.async {
          self.configureSplashForBiometrics()
        }
      }
      return
    }

    DispatchQueue.main.async {
      self.configureSplashForBiometrics()
    }
    
    localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evaluateError in
      guard !success else { self.showSecuredData(); return }
      guard let error = evaluateError else { return }
      self.showPasscodeController(error: error as NSError, reason: reason)
    }
  }
  
  func showPasscodeController(error: NSError?, reason: String) {
    var error = error
    
    guard localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      self.showSecuredData()
      return
    }
    
    localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason, reply: { (success, error) in
      guard !success else { self.showSecuredData(); return }
      print("Authentication was error")
    })
  }
}
