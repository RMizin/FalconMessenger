//
//  EnterPhoneNumberController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class EnterPhoneNumberController: UIViewController {
  
  
  let phoneNumberContainerView = EnterPhoneNumberContainerView()

    override func viewDidLoad() {
        super.viewDidLoad()
      view.backgroundColor = UIColor.white
      configureNavigationBar()
      
      setConstraints()
     
     
      
    }
  
  fileprivate func setConstraints() {
    
    view.addSubview(phoneNumberContainerView)
    phoneNumberContainerView.translatesAutoresizingMaskIntoConstraints = false
    phoneNumberContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: navigationController!.navigationBar.frame.height).isActive = true
    phoneNumberContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    phoneNumberContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    phoneNumberContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
  }
  
  
  fileprivate func configureNavigationBar () {
    let rightBarButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(rightBarButtonDidTap))
    self.navigationItem.rightBarButtonItem = rightBarButton
  }
  
  func rightBarButtonDidTap () {
    print("tapped")
    let destination = EnterVerificationCodeController()
    navigationController?.pushViewController(destination, animated: true)
  }

   

}
