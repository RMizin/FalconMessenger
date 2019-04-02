//
//  VerificationContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/3/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

final class VerificationContainerView: UIView {

  let titleNumber: UILabel = {
    let titleNumber = UILabel()
    titleNumber.translatesAutoresizingMaskIntoConstraints = false
    titleNumber.textAlignment = .center
    titleNumber.textColor = ThemeManager.currentTheme().generalTitleColor
    titleNumber.font = UIFont.boldSystemFont(ofSize: 32)

    return titleNumber
  }()

  let subtitleText: UILabel = {
    let subtitleText = UILabel()
    subtitleText.translatesAutoresizingMaskIntoConstraints = false
    subtitleText.font = UIFont.boldSystemFont(ofSize: 15)//(ofSize: 15)
    subtitleText.textAlignment = .center
    subtitleText.textColor = ThemeManager.currentTheme().generalTitleColor
    subtitleText.text = "We have sent you an SMS with the code"

    return subtitleText
  }()

  let verificationCode: UITextField = {
    let verificationCode = UITextField()
    verificationCode.font = UIFont.boldSystemFont(ofSize: 20)
    verificationCode.translatesAutoresizingMaskIntoConstraints = false
    verificationCode.textAlignment = .center
    verificationCode.keyboardType = .numberPad
		if #available(iOS 12.0, *) {
			verificationCode.textContentType = .oneTimeCode
		}
    verificationCode.textColor = ThemeManager.currentTheme().generalTitleColor
    verificationCode.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    verificationCode.backgroundColor = .clear
    verificationCode.layer.cornerRadius = 25
    verificationCode.layer.borderWidth = 1
    verificationCode.attributedPlaceholder = NSAttributedString(string: "Code",
																																attributes: [NSAttributedString.Key.foregroundColor:
      ThemeManager.currentTheme().generalSubtitleColor])
    verificationCode.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor
    if !DeviceType.isIPad {
      verificationCode.addDoneButtonOnKeyboard()
    }
    
    return verificationCode
  }()

  let resend: UIButton = {
    let resend = UIButton()
    resend.translatesAutoresizingMaskIntoConstraints = false
    resend.setTitle("Resend", for: .normal)
    resend.contentVerticalAlignment = .center
    resend.contentHorizontalAlignment = .center
    resend.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .highlighted)
    resend.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .disabled)

    return resend
  }()

  weak var enterVerificationCodeController: VerificationCodeController?

  var seconds = 120

  var timer = Timer()

  var timerLabel: UILabel = {
    var timerLabel = UILabel()
    timerLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
    timerLabel.font = UIFont.systemFont(ofSize: 13)
    timerLabel.translatesAutoresizingMaskIntoConstraints = false
    timerLabel.textAlignment = .center
    timerLabel.sizeToFit()
    timerLabel.numberOfLines = 0

    return timerLabel
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

		resend.setTitleColor(ThemeManager.currentTheme().tintColor, for: .normal)

    addSubview(titleNumber)
    addSubview(subtitleText)
    addSubview(verificationCode)
    addSubview(resend)
    addSubview(timerLabel)

    NSLayoutConstraint.activate([
      titleNumber.topAnchor.constraint(equalTo: topAnchor),
      titleNumber.leadingAnchor.constraint(equalTo: leadingAnchor),
      titleNumber.trailingAnchor.constraint(equalTo: trailingAnchor),
      titleNumber.heightAnchor.constraint(equalToConstant: 70),

      subtitleText.topAnchor.constraint(equalTo: titleNumber.bottomAnchor),
      subtitleText.leadingAnchor.constraint(equalTo: leadingAnchor),
      subtitleText.trailingAnchor.constraint(equalTo: trailingAnchor),
      subtitleText.heightAnchor.constraint(equalToConstant: 30),

      verificationCode.topAnchor.constraint(equalTo: subtitleText.bottomAnchor, constant: 30),
      verificationCode.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      verificationCode.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      verificationCode.heightAnchor.constraint(equalToConstant: 50),

      resend.topAnchor.constraint(equalTo: verificationCode.bottomAnchor, constant: 5),
      resend.leadingAnchor.constraint(equalTo: leadingAnchor),
      resend.trailingAnchor.constraint(equalTo: trailingAnchor),
      resend.heightAnchor.constraint(equalToConstant: 45),

      timerLabel.topAnchor.constraint(equalTo: resend.bottomAnchor, constant: 0),
      timerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      timerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      timerLabel.heightAnchor.constraint(equalToConstant: 35)
    ])
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}
