//
//  EnterPhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SafariServices

protocol VerificationDelegate: class {
  func verificationFinished(with success: Bool, error: String?)
}

class EnterPhoneNumberController: UIViewController {
  
  let phoneNumberContainerView = EnterPhoneNumberContainerView()
  let countries = Country().countries
  weak var verificationDelegate: VerificationDelegate?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
      
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    configurePhoneNumberContainerView()
    configureNavigationBar()
    setCountry()
  }
  
  func configurePhoneNumberContainerView() {
    view.addSubview(phoneNumberContainerView)
    phoneNumberContainerView.translatesAutoresizingMaskIntoConstraints = false
    phoneNumberContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    phoneNumberContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    phoneNumberContainerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    phoneNumberContainerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    phoneNumberContainerView.termsAndPrivacy.delegate = self
  }
  
  @objc func leftBarButtonDidTap() {
    phoneNumberContainerView.phoneNumber.resignFirstResponder()
    self.dismiss(animated: true) {
      AppUtility.lockOrientation(.allButUpsideDown)
    }
  }
  
  fileprivate func setCountry() {
    for country in countries {
      if  country["code"] == countryCode {
        phoneNumberContainerView.countryCode.text = country["dial_code"]
        phoneNumberContainerView.selectCountry.setTitle(country["name"], for: .normal)
      }
    }
  }
  
  fileprivate func configureNavigationBar () {
    let rightBarButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(rightBarButtonDidTap))
    self.navigationItem.rightBarButtonItem = rightBarButton
    self.navigationItem.rightBarButtonItem?.isEnabled = false
  }
  
  
  @objc func openCountryCodesList() {
    let picker = SelectCountryCodeController()
    picker.delegate = self
    phoneNumberContainerView.phoneNumber.resignFirstResponder()
    navigationController?.pushViewController(picker, animated: true)
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
      setRightBarButtonStatus()
  }
  
  func setRightBarButtonStatus() {
    if phoneNumberContainerView.phoneNumber.text!.count < 9 || phoneNumberContainerView.countryCode.text == " - " {
      self.navigationItem.rightBarButtonItem?.isEnabled = false
    } else {
      self.navigationItem.rightBarButtonItem?.isEnabled = true
    }
  }
  
  var isVerificationSent = false
  
  @objc func rightBarButtonDidTap () {
    
    if currentReachabilityStatus == .notReachable {
      verificationDelegate?.verificationFinished(with: false, error: noInternetError)
      return
    }
    
    if !isVerificationSent {
      sendSMSConfirmation()
    } else {
      print("verification has already been sent once")
    }
  }

  func sendSMSConfirmation () {
    
    print("tappped sms confirmation")
    
    let phoneNumberForVerification = phoneNumberContainerView.countryCode.text! + phoneNumberContainerView.phoneNumber.text!
    
    PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberForVerification, uiDelegate: nil) { (verificationID, error) in
      print("\n Recieved Phone number verification ID: \(verificationID ?? "nil")\n")
      if let error = error {
        self.verificationDelegate?.verificationFinished(with: false, error: error.localizedDescription)
        return
      } 
      
      print("verification sent")
      self.isVerificationSent = true
      userDefaults.updateObject(for: userDefaults.authVerificationID, with: verificationID)
      self.verificationDelegate?.verificationFinished(with: true, error: nil)
    } 
  }
}

extension EnterPhoneNumberController: CountryPickerDelegate {
  
  func countryPicker(_ picker: SelectCountryCodeController, didSelectCountryWithName name: String, code: String, dialCode: String) {
    phoneNumberContainerView.selectCountry.setTitle(name, for: .normal)
    phoneNumberContainerView.countryCode.text = dialCode
    setRightBarButtonStatus()
    picker.navigationController?.popViewController(animated: true)
  }
}

extension EnterPhoneNumberController : UITextViewDelegate {
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    let safariVC = SFSafariViewController(url: URL)
    present(safariVC, animated: true, completion: nil)
    
    return false
  }
}
