//
//  EnterPhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class EnterPhoneNumberController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
      view.backgroundColor = UIColor.white
      configureNavigationBar()
    }
  
  
  fileprivate func configureNavigationBar () {
    let rightBarButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(rightBarButtonDidTap))
    self.navigationItem.rightBarButtonItem = rightBarButton
    self.title = "Phone"
  }
  
  func rightBarButtonDidTap () {
    print("tapped")
    let destination = EnterVerificationCodeController()
    navigationController?.pushViewController(destination, animated: true)
  }

   

}
