//
//  OnboardingContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

final class OnboardingContainerView: UIView {

  let logoImageView: UIImageView = {
    let logoImageView = UIImageView()
    logoImageView.translatesAutoresizingMaskIntoConstraints = false
    logoImageView.image = UIImage(named: "FalconLogo")
    logoImageView.contentMode = .scaleAspectFit

    return logoImageView
  }()

  let welcomeTitle: UILabel = {
    let welcomeTitle = UILabel()
    welcomeTitle.translatesAutoresizingMaskIntoConstraints = false
    welcomeTitle.text = "Welcome to Falcon"
    welcomeTitle.font = UIFont.boldSystemFont(ofSize: 20)
    welcomeTitle.textAlignment = .center
    welcomeTitle.textColor = ThemeManager.currentTheme().generalTitleColor
    welcomeTitle.sizeToFit()
    return welcomeTitle
  }()

  let startMessaging: UIButton = {
    let startMessaging = UIButton()
    startMessaging.translatesAutoresizingMaskIntoConstraints = false
    startMessaging.setTitle("Start messaging", for: .normal)
    startMessaging.titleLabel?.backgroundColor = .clear
    startMessaging.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
    startMessaging.addTarget(self, action: #selector(OnboardingController.startMessagingDidTap), for: .touchUpInside)
    startMessaging.sizeToFit()
    return startMessaging
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		startMessaging.setTitleColor(tintColor, for: .normal)
    addSubview(logoImageView)
    addSubview(welcomeTitle)
    addSubview(startMessaging)

    NSLayoutConstraint.activate([
      logoImageView.topAnchor.constraint(equalTo: topAnchor),
      logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 55),
      logoImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -55),
      logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),

      welcomeTitle.heightAnchor.constraint(equalToConstant: 50),
      welcomeTitle.bottomAnchor.constraint(equalTo: startMessaging.topAnchor, constant: -10),
      startMessaging.centerXAnchor.constraint(equalTo: centerXAnchor),
      welcomeTitle.centerXAnchor.constraint(equalTo: centerXAnchor)
      ])

    if #available(iOS 11.0, *) {
       startMessaging.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
    } else {
       startMessaging.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50).isActive = true
    }
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}
