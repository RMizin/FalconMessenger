//
//  OnboardingController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class OnboardingController: UIViewController {

  
  
  let onboardingContainerView = OnboardingContainerView(frame: CGRect(x: 0, y: 0, width: deviceScreen.width , height: deviceScreen.height))
  
    override func viewDidLoad() {
        super.viewDidLoad()
     
      view.addSubview(onboardingContainerView)
       
    }
  
 
  


  
  func startMessagingDidTap () {
    //    let navigationController = MainNavigationController(rootViewController: refactoredController)
    //    navigationController.modalPresentationStyle = .custom
    //    navigationController.transitioningDelegate = self.profileTransition
    //    self.present(navigationController, animated: true, completion: nil)
    //
    //
    //    let destination =
    //    navigationController?.pushViewController(destination, animated: true)
    print("tapped")
    let destination = EnterPhoneNumberController()
    navigationController?.pushViewController(destination, animated: true)
  }
   

}
