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
    setColorsAccordingToTheme()
  }
  
  fileprivate func setColorsAccordingToTheme() {
    let theme = ThemeManager.currentTheme()
    ThemeManager.applyTheme(theme: theme)
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    onboardingContainerView.backgroundColor = view.backgroundColor
  }
  
  @objc func startMessagingDidTap () {
    let destination = AuthPhoneNumberController()
    navigationController?.pushViewController(destination, animated: true)
  }

}
