//
//  Country.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/3/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import Foundation

class Country: NSObject {
  
  var countries = [[String : String]]()
  
  override init() {
    super.init()
    
    fetchCountries()
  }
  
  func fetchCountries () {
    let path = Bundle.main.path(forResource: "CallingCodes", ofType: "plist")!
    let url = URL(fileURLWithPath: path)
    let data = try! Data(contentsOf: url)
    let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
    countries = plist as! [[String : String]]
  }
}
