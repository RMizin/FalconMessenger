//
//  Biometrics.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class Biometrics: NSObject {
  var title: String?
  
  override init() {
    super.init()
    self.title = selectBiometricsType()
  }
  
  fileprivate func selectBiometricsType() -> String {
    let biometricType = userDefaults.currentIntObjectState(for: userDefaults.biometricType)
    
    switch biometricType {
    case 0:
      return "Unlock with Passcode"
    case 1:
      return "Unlock with Touch ID"
    case 2:
      return "Unlock with Face ID"
    default: return ""
    }
  }
}
