//
//  UserDefaultsManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


let userDefaults = UserDefaultsManager()

class UserDefaultsManager: NSObject {
  
  fileprivate let defaults = UserDefaults.standard

	let chatLogDefaultFontSizeID = "chatLogDefaultFontSizeID"
  let authVerificationID = "authVerificationID"
  let changeNumberAuthVerificationID = "ChangeNumberAuthVerificationID"
  let selectedTheme = "SelectedTheme"
  let hasRunBefore = "hasRunBefore"
  let biometricType = "biometricType"
  let inAppNotifications = "In-AppNotifications"
  let inAppSounds = "In-AppSounds"
  let inAppVibration = "In-AppVibration"
  let biometricalAuth = "BiometricalAuth"
  let contactsContiniousSync = "ContactsContiniousSync"
  let contactsSyncronizationStatus = "ContactsSyncronizationStatus"
  let contactsCount = "ContactsCount"
  
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

	func currentFloatObjectState(for key: String) -> Float {
		return defaults.float(forKey: key)
	}
  //
  
  //existence
  func isContactsCountExists() -> Bool {
    guard defaults.object(forKey: contactsCount) == nil else { return true }
    return false
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
    
    if defaults.object(forKey: contactsContiniousSync) == nil {
      updateObject(for: contactsContiniousSync, with: true)
    }

		if defaults.object(forKey: chatLogDefaultFontSizeID) == nil {
			if DeviceType.IS_IPAD_PRO {
				updateObject(for: chatLogDefaultFontSizeID, with: 19)
			} else if DeviceType.isIPad {
				updateObject(for: chatLogDefaultFontSizeID, with: 17)
			} else {
				updateObject(for: chatLogDefaultFontSizeID, with: 17)
			}
		}
  }
}
