//
//  ChangeNumberEnterPhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseAuth


class ChangeNumberEnterPhoneNumberController: UIViewController {
  
    let phoneNumberContainerView = ChangeNumberEnterPhoneNumberContainerView()
    let countries = Country().countries
  

    override func viewDidLoad() {
        super.viewDidLoad()
      
      view.backgroundColor = UIColor.white
      configurePhoneNumberContainerView()
      configureNavigationBar()
      setCountry()
    }
  
    fileprivate func configurePhoneNumberContainerView() {
      view.addSubview(phoneNumberContainerView)
      phoneNumberContainerView.frame = view.bounds
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
      
      let leftBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(leftBarButtonDidTap))
      navigationItem.leftBarButtonItem = leftBarButton
    
      
      let rightBarButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(rightBarButtonDidTap))
      navigationItem.rightBarButtonItem = rightBarButton
      navigationItem.rightBarButtonItem?.isEnabled = false
    
      if #available(iOS 11.0, *) {
        self.navigationItem.largeTitleDisplayMode = .never
      }
    }
  
    @objc func openCountryCodesList () {
      let picker = ChangeNumberSelectCountryCodeController()
      picker.delegate = self
      navigationController?.pushViewController(picker, animated: true)
    }
  
    @objc func textFieldDidChange(_ textField: UITextField) {
      setRightBarButtonStatus()
    }
  
    @objc func leftBarButtonDidTap() {
      self.dismiss(animated: true) {
         AppUtility.lockOrientation(.allButUpsideDown)
      }
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
        basicErrorAlertWith(title: "No internet connection", message: noInternetError, controller: self)
        return
      }
    
      let destination = ChangeNumberEnterVerificationCodeController()
    
      destination.enterVerificationContainerView.titleNumber.text = phoneNumberContainerView.countryCode.text! + phoneNumberContainerView.phoneNumber.text!
    
      navigationController?.pushViewController(destination, animated: true)
    
      if !isVerificationSent {
        sendSMSConfirmation()
      }
  }
  
  
  func sendSMSConfirmation () {
    
    print("tappped sms confirmation")
    
    let phoneNumberForVerification = phoneNumberContainerView.countryCode.text! + phoneNumberContainerView.phoneNumber.text!
    
    PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberForVerification, uiDelegate: nil) { (verificationID, error) in
      if let error = error {
        print(error.localizedDescription)
        return
      }
      
      print("verification sent")
      self.isVerificationSent = true
      UserDefaults.standard.set(verificationID, forKey: "ChangeNumberAuthVerificationID")
    }
  }
}

extension ChangeNumberEnterPhoneNumberController: ChangeNumberCountryPickerDelegate {
  
  func countryPicker(_ picker: ChangeNumberSelectCountryCodeController, didSelectCountryWithName name: String, code: String, dialCode: String) {
    phoneNumberContainerView.selectCountry.setTitle(name, for: .normal)
    phoneNumberContainerView.countryCode.text = dialCode
    setRightBarButtonStatus()
    picker.navigationController?.popViewController(animated: true)
  }
}
