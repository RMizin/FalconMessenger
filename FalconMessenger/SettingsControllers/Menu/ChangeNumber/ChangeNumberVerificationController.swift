//
//  ChangeNumberVerificationController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


class ChangeNumberVerificationController: VerificationCodeController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setRightBarButton(with: "Confirm")
  }
  
  override func rightBarButtonDidTap() {
    super.rightBarButtonDidTap()
    changeNumber()
  }
}
