//
//  UserDefaultsManager.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


let userDefaults = UserDefaultsManager()

class UserDefaultsManager: NSObject {
  
  fileprivate let defaults = UserDefaults.standard
  
  let authVerificationID = "authVerificationID"
  let changeNumberAuthVerificationID = "ChangeNumberAuthVerificationID"
  let selectedTheme = "SelectedTheme"
  let hasRunBefore = "hasRunBefore"
  let biometricType = "biometricType"
  let inAppNotifications = "In-AppNotifications"
  let inAppSounds = "In-AppSounds"
  let inAppVibration = "In-AppVibration"
  let biometricalAuth = "BiometricalAuth"
  
  //updating
  func updateObject(for key: String, with data: Any?) {
    defaults.set(data, forKey: key)
    defaults.synchronize()
  }
  //
  
  //removing
  func removeObject(for key: String) {
    defaults.removeObject(forKey: key)
  }
  //
  
  //current state
  func currentStringObjectState(for key: String) -> String? {
    return defaults.string(forKey: key)
  }
  
  func currentIntObjectState(for key: String) -> Int? {
    return defaults.integer(forKey: key)
  }
  
  func currentBoolObjectState(for key: String) -> Bool {
    return defaults.bool(forKey: key)
  }
  //
  
  // other
  func configureInitialLaunch() {
    if defaults.bool(forKey: hasRunBefore) != true {
      do { try Auth.auth().signOut() } catch {}
      updateObject(for: hasRunBefore, with: true)
    }
    setDefaultsForSettings()
  }
  
  func setDefaultsForSettings() {
    
    if defaults.object(forKey: inAppNotifications) == nil {
      updateObject(for: inAppNotifications, with: true)
    }
    
    if defaults.object(forKey: inAppSounds) == nil {
      updateObject(for: inAppSounds, with: true)
    }
    
    if defaults.object(forKey: inAppVibration) == nil {
      updateObject(for: inAppVibration, with: true)
    }
    
    if defaults.object(forKey: biometricalAuth) == nil {
      updateObject(for: biometricalAuth, with: false)
    }
  }
}
