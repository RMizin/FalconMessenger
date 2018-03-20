//
//  GroupAdminControlls.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class GroupAdminControlls: NSObject {
  var controlName:String?
  var controlIcon:UIImage?
  
  init(name:String, icon: UIImage) {
    super.init()
    
    controlName = name
    controlIcon = icon
  }
}
