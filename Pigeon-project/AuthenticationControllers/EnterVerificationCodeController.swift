//
//  EnterVerificationCodeController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class EnterVerificationCodeController: UIViewController {

  let enterVerificationContainerView = EnterVerificationContainerView()
  
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
      view.backgroundColor = UIColor.white
      configureNavigationBar()
      setConstraints()
  }
  
  
  fileprivate func setConstraints() {
    
    view.addSubview(enterVerificationContainerView)
    enterVerificationContainerView.translatesAutoresizingMaskIntoConstraints = false
    enterVerificationContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: navigationController!.navigationBar.frame.height).isActive = true
    enterVerificationContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    enterVerificationContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    enterVerificationContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
  }
  
  fileprivate func configureNavigationBar () {
    let rightBarButton = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(rightBarButtonDidTap))
    self.navigationItem.rightBarButtonItem = rightBarButton
  }
  
  
  func rightBarButtonDidTap () {
    print("tapped")
    
    if enterVerificationContainerView.verificationCode.text == "" {
      enterVerificationContainerView.verificationCode.shake()
    } else {
      let destination = CreateProfileController()
      destination.createProfileContainerView.phone.text = enterVerificationContainerView.titleNumber.text
      navigationController?.pushViewController(destination, animated: true)
    }
    
   
  }
  
}
