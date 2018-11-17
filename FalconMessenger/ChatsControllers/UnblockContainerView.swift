//
//  UnblockContainerView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/11/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class UnblockContainerView: InputBlockerContainerView {

  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backButton.setTitle("Unblock", for: .normal)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
