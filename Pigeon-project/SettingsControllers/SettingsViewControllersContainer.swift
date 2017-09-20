  //
//  SettingsViewControllersContainer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/5/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//


import UIKit
import Firebase


class SettingsViewControllersContainer: UIViewController {
  
  let userDataController = UserProfileController()
  let accountSettingsController = AccountSettingsController()
  let scrollView = UIScrollView()
  
  let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBarButtonPressed))
  let doneBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action:  #selector(doneBarButtonPressed))
  
  var currentName = String()
  
 
    override func viewDidLoad() {
        super.viewDidLoad()
      
        view.backgroundColor = .white
        extendedLayoutIncludesOpaqueBars = true
        
        configureScrollView()
        configureContainedViewControllers()
      
        userDataController.userProfileContainerView.name.addTarget(self, action: #selector(nameDidBeginEditing), for: .editingDidBegin)
        userDataController.userProfileContainerView.name.addTarget(self, action: #selector(nameEditingChanged), for: .editingChanged)
      
        listenChanges()
    }
  
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: userDataController.view.frame.height + accountSettingsController.view.frame.height)
    }
  
  
  
  func listenChanges() {
    
    if let currentUser = Auth.auth().currentUser?.uid {
      
      let photoURLReference = Database.database().reference().child("users").child(currentUser).child("photoURL")
      photoURLReference.observe(.value, with: { (snapshot) in
        if let url = snapshot.value as? String {
          self.userDataController.userProfileContainerView.profileImageView.sd_setImage(with: URL(string: url) , placeholderImage: nil, options: [.highPriority, .continueInBackground], completed: {(image, error, cacheType, url) in
          })
        }
        
      })
      
      
       let nameReference = Database.database().reference().child("users").child(currentUser).child("name")
       nameReference.observe(.value, with: { (snapshot) in
        if let name = snapshot.value as? String {
          self.userDataController.userProfileContainerView.name.text = name
          self.currentName = name
        }
      })
      
      
       let phoneNumberReference = Database.database().reference().child("users").child(currentUser).child("phoneNumber")
       phoneNumberReference.observe(.value, with: { (snapshot) in
        if let phoneNumber = snapshot.value as? String {
          self.userDataController.userProfileContainerView.phone.text = phoneNumber
        }
      })

    }
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

    listenChanges()
  }
  

    fileprivate func configureContainedViewControllers() {
      
      addChildViewController(userDataController)
      addChildViewController(accountSettingsController)
      
      userDataController.view.frame = CGRect(x: 0, y: 0, width: deviceScreen.width, height: 300)
      accountSettingsController.view.frame = CGRect(x: 0, y: 255, width: deviceScreen.width, height: 270)
     
      scrollView.addSubview(userDataController.view)
      scrollView.addSubview(accountSettingsController.view)
     
      userDataController.didMove(toParentViewController: self)
      accountSettingsController.didMove(toParentViewController: self)
    }
}


extension SettingsViewControllersContainer: UIScrollViewDelegate {}


extension SettingsViewControllersContainer { /* user name editing */
  
  @objc func nameDidBeginEditing() {
    setEditingBarButtons()
  }
  
  
  @objc func nameEditingChanged() {

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
  
  
  @objc func cancelBarButtonPressed() {
    
    userDataController.userProfileContainerView.name.text = currentName
    userDataController.userProfileContainerView.name.resignFirstResponder()
    navigationItem.leftBarButtonItem = nil
    navigationItem.rightBarButtonItem = nil
  }
  
  @objc func doneBarButtonPressed() {
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
      
      ARSLineProgress.showSuccess()
      self.view.isUserInteractionEnabled = true
    }
  }
}




