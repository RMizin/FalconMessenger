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
        // Do any additional setup after loading the view.
    }

  
  
  fileprivate func configureNavigationBar () {
    let rightBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(rightBarButtonDidTap))
    self.navigationItem.rightBarButtonItem = rightBarButton
   self.title = "Profile"
  }
  
  
  func rightBarButtonDidTap () {
    print("Done")
  //  mainController = GeneralTabBarController()
    
  //  let newNavigationController = UINavigationController(rootViewController: GeneralTabBarController())
    //newNavigationController.navigationBar.isTranslucent = false
    //UIApplication.shared.keyWindow?.rootViewController = newNavigationController
    //UIApplication.shared.keyWindow?.makeKeyAndVisible()
   

   // navigationController?.popToRootViewController(animated: true)
    //popViewController(animated: true)
    
    dismiss(animated: true, completion: nil)
  }
  
//    var presentingViewController: UIViewController! = self.presentingViewController
//    
//    self.dismissViewControllerAnimated(false) {
//      // go back to MainMenuView as the eyes of the user
//      presentingViewController.dismissViewControllerAnimated(false, completion: nil)
//    }  }


}
