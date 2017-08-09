  //
//  SettingsViewControllersContainer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/5/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit
import FirebaseAuth
import  Firebase


class SettingsViewControllersContainer: UIViewController {
  
  let userDataController = UserProfileController()
  let accountSettingsController = AccountSettingsController()
  let scrollView = UIScrollView()
  
  let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBarButtonPressed))
  let doneBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action:  #selector(doneBarButtonPressed))
  
 
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        configureScrollView()
        configureContainedViewControllers()
        configureContainedViewControllersData()
        userDataController.userProfileContainerView.name.addTarget(self, action: #selector(nameDidBeginEditing), for: .editingDidBegin)
        userDataController.userProfileContainerView.name.addTarget(self, action: #selector(nameEditingChanged), for: .editingChanged)
    }
  
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: userDataController.view.frame.height + accountSettingsController.view.frame.height)
    }
  
    fileprivate func configureScrollView() {
    
      view.addSubview(scrollView)
      let scrollViewHeight = view.frame.height
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
    
    let userName = UserDefaults.standard.string(forKey: "userName")
    let userPhoneNumber = UserDefaults.standard.string(forKey: "userPhoneNumber")
    let userPhotoURL = UserDefaults.standard.string(forKey: "userPhotoURL") //?? ""
  
    if  userPhotoURL != nil {
      if userDataController.userProfileContainerView.profileImageView.image == nil || lastProfileURL != URL(string: userPhotoURL!) {
        
        userDataController.userProfileContainerView.profileImageView.sd_setImage(with: URL(string: userPhotoURL!), placeholderImage: nil, options: [.progressiveDownload, .highPriority, .continueInBackground], completed: { (image, error, cacheType, url) in
          self.lastProfileURL = url
          
        })
      }
    }
    
    userDataController.userProfileContainerView.name.text = userName
    userDataController.userProfileContainerView.phone.text = userPhoneNumber
  }
  
    fileprivate func configureContainedViewControllers() {
      
      addChildViewController(userDataController)
      addChildViewController(accountSettingsController)
      
      userDataController.view.frame = CGRect(x: 0, y: 0/*-navigationController!.navigationBar.frame.height*/, width: deviceScreen.width, height: 300)
      accountSettingsController.view.frame = CGRect(x: 0, y: 255, width: deviceScreen.width, height: 270)
     
      scrollView.addSubview(userDataController.view)
      scrollView.addSubview(accountSettingsController.view)
     
      userDataController.didMove(toParentViewController: self)
      accountSettingsController.didMove(toParentViewController: self)
    }
}


extension SettingsViewControllersContainer: UIScrollViewDelegate {}


extension SettingsViewControllersContainer { /* user name editing */
  
  func nameDidBeginEditing() {
    setEditingBarButtons()
  }
  
  
  func nameEditingChanged() {

    if userDataController.userProfileContainerView.name.text!.characters.count == 0 ||
       userDataController.userProfileContainerView.name.text!.trimmingCharacters(in: .whitespaces).isEmpty {
      
      doneBarButton.isEnabled = false
      
    } else {
      doneBarButton.isEnabled = true
    }
  }
  
  
  func setEditingBarButtons() {
    navigationItem.leftBarButtonItem = cancelBarButton
    navigationItem.rightBarButtonItem = doneBarButton
  }
  
  
  func cancelBarButtonPressed() {
    let userName = UserDefaults.standard.string(forKey: "userName")
    userDataController.userProfileContainerView.name.text = userName
    userDataController.userProfileContainerView.name.resignFirstResponder()
    navigationItem.leftBarButtonItem = nil
    navigationItem.rightBarButtonItem = nil
    
    
  }
  
  func doneBarButtonPressed() {
    ARSLineProgress.ars_showOnView(self.view)
    self.view.isUserInteractionEnabled = false
    navigationItem.leftBarButtonItem = nil
    navigationItem.rightBarButtonItem = nil
    userDataController.userProfileContainerView.name.resignFirstResponder()
    
    
    let userNameReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
    userNameReference.updateChildValues(["name" : userDataController.userProfileContainerView.name.text!]) { (error, reference) in
      
      if error != nil {
        ARSLineProgress.showFail()
        self.view.isUserInteractionEnabled = true
      }
      
      UserDefaults.standard.set(self.userDataController.userProfileContainerView.name.text!, forKey: "userName")
      ARSLineProgress.showSuccess()
      self.view.isUserInteractionEnabled = true
    }
  }
}




