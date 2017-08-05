//
//  SettingsViewControllersContainer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/5/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit
import FirebaseAuth

class SettingsViewControllersContainer: UIViewController {
  
  let userDataController = CreateProfileController()
  let accountSettingsController = AccountSettingsController()
  let scrollView = UIScrollView()
  
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.title = "Settings"
        self.edgesForExtendedLayout = UIRectEdge()
        view.backgroundColor = .white
      
        configureScrollView()
        configureContainedViewControllers()
    }
  
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: userDataController.view.frame.height + accountSettingsController.view.frame.height)
    }
  
    fileprivate func configureScrollView() {
    
      view.addSubview(scrollView)
      
      let scrollViewHeight = view.frame.height - tabBarController!.tabBar.frame.size.height - navigationController!.navigationBar.frame.height - 20
      scrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: scrollViewHeight )
      scrollView.delegate = self
      scrollView.alwaysBounceVertical = true
      scrollView.backgroundColor = .white
    }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    configureContainedViewControllersData()
  }
  
  
  fileprivate var lastProfileURL:URL? = nil
  
  fileprivate func configureContainedViewControllersData() {
    userDataController.createProfileContainerView.name.text = Auth.auth().currentUser?.displayName
    userDataController.createProfileContainerView.phone.text = Auth.auth().currentUser?.providerData[0].phoneNumber
    
    if userDataController.createProfileContainerView.profileImageView.image == nil || lastProfileURL != Auth.auth().currentUser?.photoURL {
       userDataController.createProfileContainerView.profileImageView.sd_setImage(with: Auth.auth().currentUser?.photoURL, placeholderImage: nil, options: [.progressiveDownload, .highPriority, .continueInBackground], completed: { (image, error, cacheType, url) in
            self.lastProfileURL = url
       })
      
    }
   
  }
  
    fileprivate func configureContainedViewControllers() {
      
      addChildViewController(userDataController)
      addChildViewController(accountSettingsController)
      
      userDataController.view.frame = CGRect(x: 0, y: -navigationController!.navigationBar.frame.height, width: deviceScreen.width, height: 300)
      accountSettingsController.view.frame = CGRect(x: 0, y: 255, width: deviceScreen.width, height: 270)
     
      scrollView.addSubview(userDataController.view)
      scrollView.addSubview(accountSettingsController.view)
     
      userDataController.didMove(toParentViewController: self)
      accountSettingsController.didMove(toParentViewController: self)
    }


}

extension SettingsViewControllersContainer: UIScrollViewDelegate {}
