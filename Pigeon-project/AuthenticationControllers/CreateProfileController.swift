//
//  CreateProfileController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class CreateProfileController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
      
        view.backgroundColor = .white
        configureNavigationBar()
    }
  
  fileprivate func configureNavigationBar () {
    let rightBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(rightBarButtonDidTap))
    self.navigationItem.rightBarButtonItem = rightBarButton
   self.title = "Profile"
    self.navigationItem.setHidesBackButton(true, animated: true)
  }
  
  
  func rightBarButtonDidTap () {
    print("Done")
    dismiss(animated: true, completion: nil)
  }
}
