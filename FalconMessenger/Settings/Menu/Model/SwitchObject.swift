//
//  SwitchObject.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SwitchObject: NSObject {
  var title: String?
  var subtitle: String?
  
  var state: Bool! {
    didSet {
      guard defaultsKey != nil else { return }
      userDefaults.updateObject(for: defaultsKey, with: state)
    }
  }
  var defaultsKey:String!
  
  init(_ title: String?, subtitle: String?, state: Bool,defaultsKey: String ) {
    super.init()
    self.title = title
    self.subtitle = subtitle
    self.state = state
    self.defaultsKey = defaultsKey
  }
}
