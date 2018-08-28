//
//  SplitPlaceholderViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SplitPlaceholderViewController: UIViewController {

  let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = UIImage(named: "GrayLogo")
    imageView.contentMode = .scaleAspectFill
    imageView.backgroundColor = .clear
    
    return imageView
  }()
  
  func updateBackgrounColor() {
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }

  override func viewDidLoad() {
   super.viewDidLoad()
    updateBackgrounColor()
    view.addSubview(imageView)
    imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
  }
}
