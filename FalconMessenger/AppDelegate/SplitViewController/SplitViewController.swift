//
//  SplitViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

final class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.delegate = self
    preferredDisplayMode = .allVisible
  }

  override var traitCollection: UITraitCollection {
    if DeviceType.isIPad {
      return super.traitCollection
    } else {
      return UITraitCollection(horizontalSizeClass: .compact)
    }
  }

  func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
   return true
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }
}

extension SplitViewController {
  
  var masterViewController: UIViewController? {
    return viewControllers.first
  }
  
  var detailViewController: UIViewController? {
    guard viewControllers.count == 2 else { return nil }
    return viewControllers.last
  }
}

extension UINavigationController {
  open override var preferredStatusBarStyle: UIStatusBarStyle {
    return ThemeManager.currentTheme().statusBarStyle
  }
}
