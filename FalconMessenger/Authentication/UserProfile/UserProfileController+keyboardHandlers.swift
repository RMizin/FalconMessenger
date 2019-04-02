//
//  CreateProfileController+keyboardHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

extension UIViewController {
 final func hideKeyboardWhenTappedAround() {
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                             action: #selector(UIViewController.dismissKeyboard))
    view.addGestureRecognizer(tap)
  }

  @objc final func dismissKeyboard() {
    view.endEditing(true)
  }
}
