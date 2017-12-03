//
//  UserProfileController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


class UserProfileController: UIViewController {
  
  let userProfileContainerView = UserProfileContainerView()
  let userProfilePictureOpener = UserProfilePictureOpener()
  typealias CompletionHandler = (_ success: Bool) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        view.addSubview(userProfileContainerView)
      
        configureNavigationBar()
        configureContainerView()
    }
  
    fileprivate func configureNavigationBar () {
      let rightBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(rightBarButtonDidTap))
      self.navigationItem.rightBarButtonItem = rightBarButton
      self.title = "Profile"
      self.navigationItem.setHidesBackButton(true, animated: true)
    }
  
    fileprivate func configureContainerView() {
      userProfileContainerView.frame = view.bounds
      userProfileContainerView.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openUserProfilePicture)))
    }
  
    override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
      userProfileContainerView.frame = view.bounds
      userProfileContainerView.layoutIfNeeded()
    }
  
    @objc fileprivate func openUserProfilePicture() {
      userProfilePictureOpener.controllerWithUserProfilePhoto = self
      userProfilePictureOpener.userProfileContainerView = userProfileContainerView
      userProfilePictureOpener.openUserProfilePicture()
    }
}


extension UserProfileController {
  
  @objc func rightBarButtonDidTap () {
   userProfileContainerView.name.resignFirstResponder()
    if userProfileContainerView.name.text?.count == 0 ||
       userProfileContainerView.name.text!.trimmingCharacters(in: .whitespaces).isEmpty {
       userProfileContainerView.name.shake()
    } else {
       
      if currentReachabilityStatus == .notReachable {
        basicErrorAlertWith(title: "No internet connection", message: noInternetError, controller: self)
        return
      }
      
      updateUserData()
      
      if Messaging.messaging().fcmToken != nil {
         setUserNotificationToken(token: Messaging.messaging().fcmToken!)
      }
     
      setOnlineStatus()
    }
  }
  
  func checkIfUserDataExists(completionHandler: @escaping CompletionHandler) {
    
    let nameReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("name")
    nameReference.observe(.value, with: { (snapshot) in
      if snapshot.exists() {
        self.userProfileContainerView.name.text = (snapshot.value as! String)
      }
    })
    
    
    let photoReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("photoURL")
    photoReference.observe(.value, with: { (snapshot) in
      
      if snapshot.exists() {
        let urlString:String = snapshot.value as! String
        self.userProfileContainerView.profileImageView.sd_setImage(with:  URL(string: urlString) , placeholderImage: nil, options: [ .highPriority, .continueInBackground, .progressiveDownload], completed: { (image, error, cacheType, url) in
    
           completionHandler(true)
        })
      } else {
         
         completionHandler(true)
      }
    })
  }
  
  func updateUserData() {
    
    ARSLineProgress.ars_showOnView(self.view)
      NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadUserConversations"), object: nil)
     
    let userReference = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
    userReference.updateChildValues(["name" : userProfileContainerView.name.text! , "phoneNumber" : userProfileContainerView.phone.text! ]) { (error, reference) in
      ARSLineProgress.hide()
      self.dismiss(animated: true) {
        AppUtility.lockOrientation(.allButUpsideDown)
      }
    }
  }
}
