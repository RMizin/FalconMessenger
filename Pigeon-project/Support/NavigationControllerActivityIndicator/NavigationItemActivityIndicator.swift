//
//  NavigationItemActivityIndicator.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/16/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


enum ActivityPriority: CGFloat {
  case low = 0.1
  case lowMedium = 0.3
  case medium = 0.5
  case mediumHigh = 0.7
  case high = 1.0
  case crazy = 2.0
}

enum UINavigationItemMessage: String {
  case noInternet = "No internet connection..."
  case updating = "Updating..."
  case connecting = "Connecting..."
  case loadingFromCache = "Loading from cache..."
  case updatingCache = "Updating cache..."
}


class NavigationItemActivityIndicator: NSObject {

  
  var isActive = false
  var currentPriority:ActivityPriority = .low
  
  func showActivityIndicator(for navigationItem: UINavigationItem, with title: UINavigationItemMessage, activityPriority: ActivityPriority , color: UIColor) {
    guard currentPriority.rawValue <= activityPriority.rawValue else { return }
    currentPriority = activityPriority
    isActive = true
    
		let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)
    let titleLabel = UILabel()
    
    activityIndicatorView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
    activityIndicatorView.color = color
    activityIndicatorView.startAnimating()
    
  
    titleLabel.text = title.rawValue
    titleLabel.font = UIFont.systemFont(ofSize: 14)
    titleLabel.textColor = color
    
    let fittingSize = titleLabel.sizeThatFits(CGSize(width:200.0, height: activityIndicatorView.frame.size.height))
    titleLabel.frame = CGRect(x: activityIndicatorView.frame.origin.x + activityIndicatorView.frame.size.width + 8, y: activityIndicatorView.frame.origin.y, width: fittingSize.width, height: fittingSize.height)
    
    let titleView = UIView(frame: CGRect(  x: (( activityIndicatorView.frame.size.width + 8 + titleLabel.frame.size.width) / 2), y: ((activityIndicatorView.frame.size.height) / 2), width:(activityIndicatorView.frame.size.width + 8 + titleLabel.frame.size.width), height: ( activityIndicatorView.frame.size.height)))
    
    titleView.addSubview(activityIndicatorView)
    titleView.addSubview(titleLabel)
    
    navigationItem.titleView = titleView
  }
  
  func hideActivityIndicator(for navigationItem: UINavigationItem, activityPriority: ActivityPriority) {
    
    guard currentPriority.rawValue <= activityPriority.rawValue, isActive else { return }
    
    currentPriority = .low
    isActive = false
    navigationItem.titleView = nil
  }
}
