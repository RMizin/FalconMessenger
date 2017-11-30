//
//  AccountSettingsController+nameEditing.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

extension AccountSettingsController { /* user name editing */
  
  @objc func nameDidBeginEditing() {
    setEditingBarButtons()
  }
  
  @objc func nameEditingChanged() {
    
    if userProfileContainerView.name.text!.count == 0 ||
      userProfileContainerView.name.text!.trimmingCharacters(in: .whitespaces).isEmpty {
      
      doneBarButton.isEnabled = false
      
    } else {
      doneBarButton.isEnabled = true
    }
  }
  
  func setEditingBarButtons() {
    navigationItem.leftBarButtonItem = cancelBarButton
    navigationItem.rightBarButtonItem = doneBarButton
  }
  
  
  @objc func cancelBarButtonPressed() {
    
    userProfileContainerView.name.text = currentName
    userProfileContainerView.name.resignFirstResponder()
    navigationItem.leftBarButtonItem = nil
    navigationItem.rightBarButtonItem = nil
    configureNavigationBarDefaultRightBarButton()
  }
  
  @objc func doneBarButtonPressed() {
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: "No internet", message: noInternetError, controller: self)
      return
    }
    
    ARSLineProgress.ars_showOnView(self.view)
    self.view.isUserInteractionEnabled = false
    navigationItem.leftBarButtonItem = nil
    navigationItem.rightBarButtonItem = nil
    configureNavigationBarDefaultRightBarButton()
    userProfileContainerView.name.resignFirstResponder()
    
    
    let userNameReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
    userNameReference.updateChildValues(["name" : userProfileContainerView.name.text!]) { (error, reference) in
      
      if error != nil {
        ARSLineProgress.showFail()
        self.view.isUserInteractionEnabled = true
      }
      
      ARSLineProgress.showSuccess()
      self.view.isUserInteractionEnabled = true
    }
  }
}
