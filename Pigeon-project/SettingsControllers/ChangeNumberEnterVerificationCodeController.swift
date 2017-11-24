//
//  ChangeNumberEnterVerificationCodeController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


class ChangeNumberEnterVerificationCodeController: UIViewController {

  let enterVerificationContainerView = ChangeNumberEnterVerificationContainerView()

    override func viewDidLoad() {
        super.viewDidLoad()
      
      view.backgroundColor = UIColor.white
      view.addSubview(enterVerificationContainerView)
      enterVerificationContainerView.frame = view.bounds
      enterVerificationContainerView.resend.addTarget(self, action: #selector(sendSMSConfirmation), for: .touchUpInside)
      enterVerificationContainerView.enterVerificationCodeController = self
      configureNavigationBar()
  }
  

  fileprivate func configureNavigationBar () {
    let rightBarButton = UIBarButtonItem(title: "Confirm", style: .done, target: self, action: #selector(rightBarButtonDidTap))
    self.navigationItem.rightBarButtonItem = rightBarButton
    self.navigationItem.hidesBackButton = true
  }
  
  
  @objc fileprivate func sendSMSConfirmation () {
    
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: "No internet connection", message: noInternetError, controller: self)
      return
    }
    
    enterVerificationContainerView.resend.isEnabled = false
    
    let phoneNumberForVerification = enterVerificationContainerView.titleNumber.text!
    
    PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumberForVerification, uiDelegate: nil) { (verificationID, error) in
      if let error = error {
        print(error.localizedDescription)
        ARSLineProgress.showFail()
        return
      }
      
      print("verification sent")
      self.enterVerificationContainerView.resend.isEnabled = false
      
      UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
      self.enterVerificationContainerView.runTimer()
    }
  }
  
  @objc func rightBarButtonDidTap () {
    
    let verificationID = UserDefaults.standard.string(forKey: "ChangeNumberAuthVerificationID")
    let verificationCode = enterVerificationContainerView.verificationCode.text

    if verificationID == nil {
      self.enterVerificationContainerView.verificationCode.shake()
      return
    }
    
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: "No internet connection", message: noInternetError, controller: self)
      return
    }
    
    ARSLineProgress.ars_showOnView(self.view)
    
    let credential = PhoneAuthProvider.provider().credential (withVerificationID: verificationID!, verificationCode: verificationCode!)
    
    Auth.auth().currentUser?.updatePhoneNumber(credential, completion: { (error) in
      if error != nil {
        ARSLineProgress.hide()
        basicErrorAlertWith(title: "Error", message: error?.localizedDescription ?? "Number changing process failed. Please try again later.", controller: self)
        return
      }
      
      let userReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
      userReference.updateChildValues(["phoneNumber" : self.enterVerificationContainerView.titleNumber.text! ]) { (error, reference) in
        if error != nil {
          ARSLineProgress.hide()
          basicErrorAlertWith(title: "Error", message: error?.localizedDescription ?? "Number changing process failed. Please try again later.", controller: self)
          return
        }
        
        ARSLineProgress.showSuccess()
        self.dismiss(animated: true) {
          AppUtility.lockOrientation(.allButUpsideDown)
        }
      }
    })
  }
}
