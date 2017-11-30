//
//  OnboardingController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class OnboardingController: UIViewController {

  let onboardingContainerView = OnboardingContainerView()
  
    override func viewDidLoad() {
        super.viewDidLoad()
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      view.addSubview(onboardingContainerView)
      onboardingContainerView.frame = view.bounds
    }
  
  
  @objc func startMessagingDidTap () {
    let destination = EnterPhoneNumberController()
    navigationController?.pushViewController(destination, animated: true)
  }

}
