//
//  Country.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/26/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

final class Country: NSObject {

  @objc var name: String?
  var code: String?
  var dialCode: String?
  var isSelected = false

  init(dictionary: [String: String]) {
    super.init()

    name = dictionary["name"]
    code = dictionary["code"]
    dialCode = dictionary["dial_code"]
  }
}
