//
//  AuthPhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import ARSLineProgress

final class AuthPhoneNumberController: PhoneNumberController, VerificationDelegate {

  final func verificationFinished(with success: Bool, error: String?) {
		ARSLineProgress.hide()
    guard success, error == nil else {
      basicErrorAlertWith(title: "Error", message: error ?? "", controller: self)
      return
    }
    let destination = AuthVerificationController()
    destination.enterVerificationContainerView.titleNumber.text = phoneNumberContainerView.countryCode.text! + phoneNumberContainerView.phoneNumber.text!
    navigationController?.pushViewController(destination, animated: true)
  }

  override func configurePhoneNumberContainerView() {
    super.configurePhoneNumberContainerView()
    phoneNumberContainerView.termsAndPrivacy.isHidden = false
    phoneNumberContainerView.instructions.text = "Please confirm your country code\nand enter your phone number."
		let attributes = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor]
    phoneNumberContainerView.phoneNumber.attributedPlaceholder = NSAttributedString(string: "Phone number", attributes: attributes)
    verificationDelegate = self
  }
}
