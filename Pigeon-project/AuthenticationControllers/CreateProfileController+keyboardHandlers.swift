//
//  CreateProfileController+keyboardHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


extension UIViewController {
  func hideKeyboardWhenTappedAround() {
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
    view.addGestureRecognizer(tap)
  }
  
  func dismissKeyboard() {
    view.endEditing(true)
  }
}


//extension CreateProfileController {/* keyboard */
//  
//  func setupKeyboardObservers() {
//    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
//  }
//  
//  
//  func handleKeyboardWillShow(_ notification: Notification) {
//    let keyboardFrame = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
//    let keyboardDuration = ((notification as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
//    
//    if  createProfileContainerView.bio.isFirstResponder  {
//      createProfileContainerView.frame.origin.y = -keyboardFrame!.height
//    } else {
//       createProfileContainerView.frame.origin.y = 0
//    }
//    
//    UIView.animate(withDuration: keyboardDuration!, animations: {
//      self.view.layoutIfNeeded()
//    })
//  }
//  
//  
//  func handleKeyboardWillHide(_ notification: Notification) {
//    let keyboardDuration = ((notification as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
//    
//    
//    createProfileContainerView.frame.origin.y = 0
//    
//    UIView.animate(withDuration: keyboardDuration!, animations: {
//      self.view.layoutIfNeeded()
//    })
//  }
//}
