//
//  ChangePhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ChangePhoneNumberController: EnterPhoneNumberController, VerificationDelegate {
  
  func verificationFinished(with success: Bool, error: String?) {
    guard success, error == nil else {
      basicErrorAlertWith(title: "Error", message: error ?? "", controller: self)
      return
    }
    let destination = ChangeNumberVerificationController()
    destination.enterVerificationContainerView.titleNumber.text = phoneNumberContainerView.countryCode.text! + phoneNumberContainerView.phoneNumber.text!
    navigationController?.pushViewController(destination, animated: true)
  }
  
  override func configurePhoneNumberContainerView() {
    super.configurePhoneNumberContainerView()
    
    let leftBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(leftBarButtonDidTap))
    navigationItem.leftBarButtonItem = leftBarButton
    phoneNumberContainerView.termsAndPrivacy.isHidden = true
    phoneNumberContainerView.instructions.text = "Please confirm your country code\nand enter your NEW phone number."
    let attributes = [NSAttributedStringKey.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor]
    phoneNumberContainerView.phoneNumber.attributedPlaceholder = NSAttributedString(string: "New phone number", attributes: attributes)
    verificationDelegate = self
  }
}
