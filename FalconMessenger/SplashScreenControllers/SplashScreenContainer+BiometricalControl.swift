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
    DispatchQueue.main.async {
      self.removeFromSuperview()
    }
  }
  
  func temporaryDisableNotifications() {
    guard bannersState == nil, soundsState == nil, vibrationState == nil else { return }
    bannersState = UserDefaults.standard.bool(forKey: "In-AppNotifications")
    soundsState = UserDefaults.standard.bool(forKey: "In-AppSounds")
    vibrationState = UserDefaults.standard.bool(forKey: "In-AppVibration")
    UserDefaults.standard.set(false, forKey: "In-AppNotifications")
    UserDefaults.standard.set(false, forKey: "In-AppSounds")
    UserDefaults.standard.set(false, forKey: "In-AppVibration")
  }
  
  func restoreNotificationsState() {
    guard bannersState != nil, soundsState != nil, vibrationState != nil else { return }
    UserDefaults.standard.set(bannersState, forKey: "In-AppNotifications")
    UserDefaults.standard.set(soundsState, forKey: "In-AppSounds")
    UserDefaults.standard.set(vibrationState, forKey: "In-AppVibration")
  }
  
  @objc func authenticationWithTouchID() {
    var authError: NSError?
    let reason = "To get access to the Falcon Messenger"
    temporaryDisableNotifications()
    
    guard localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
      guard let error = authError else { return }
      self.showPasscodeController(error: error, reason: reason)
      let biometricType = UserDefaults.standard.integer(forKey: "biometricType")
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
