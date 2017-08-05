//
//  CreateProfileController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class CreateProfileController: UIViewController {
  
  let createProfileContainerView = CreateProfileContainerView()
  let picker = UIImagePickerController()
  var editLayer: CAShapeLayer!
  var label: UILabel!
  

    override func viewDidLoad() {
        super.viewDidLoad()
      
        view.backgroundColor = .white
        configureNavigationBar()
        setConstraints()
        configurePickerController()
        hideKeyboardWhenTappedAround()
       // setupKeyboardObservers()
        createProfileContainerView.profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
    }
  
    fileprivate func setConstraints() {
      view.addSubview(createProfileContainerView)
      createProfileContainerView.translatesAutoresizingMaskIntoConstraints = false
      createProfileContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: navigationController!.navigationBar.frame.height).isActive = true
      createProfileContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
      createProfileContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
      createProfileContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    }
  
    fileprivate func configurePickerController() {
      picker.delegate = self
      navigationController?.delegate = self
      NotificationCenter.default.addObserver(self, selector: #selector(pictureCaptured), name: NSNotification.Name(rawValue: "_UIImagePickerControllerUserDidCaptureItem"), object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(pictureRejected), name: NSNotification.Name(rawValue: "_UIImagePickerControllerUserDidRejectItem"), object: nil)
    }

    fileprivate func configureNavigationBar () {
      let rightBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(rightBarButtonDidTap))
      self.navigationItem.rightBarButtonItem = rightBarButton
      self.title = "Profile"
      self.navigationItem.setHidesBackButton(true, animated: true)
    }
  
    func rightBarButtonDidTap () {
      
      if createProfileContainerView.name.text == "" {
        createProfileContainerView.name.shake()
      } else {
        dismiss(animated: true, completion: nil)
      }
      
    }
  
    deinit {
      NotificationCenter.default.removeObserver(self)
    }
}
