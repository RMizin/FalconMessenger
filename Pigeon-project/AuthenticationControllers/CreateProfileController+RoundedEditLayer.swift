//
//  CreateProfileController+RoundedEditLayer.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


extension CreateProfileController {
  
  func pictureCaptured() {
    addRoundedEditLayer(to: picker , forCamera: true)
  }
  
  func pictureRejected() {
    editLayer.removeFromSuperlayer()
    label.removeFromSuperview()
  }
  
  func addRoundedEditLayer(to viewController: UIViewController, forCamera: Bool) {
    hideDefaultEditOverlay(view: viewController.view)
    
    // Circle in edit layer - y position
    let bottomBarHeight: CGFloat = 72.0
    let position = (forCamera) ? viewController.view.center.y - viewController.view.center.x - bottomBarHeight/2 : viewController.view.center.y - viewController.view.center.x
    
    let viewWidth = viewController.view.frame.width
    let viewHeight = viewController.view.frame.height
    
    let emptyShapePath = UIBezierPath(ovalIn: CGRect(x: 0, y: position, width: viewWidth, height: viewWidth))
    emptyShapePath.usesEvenOddFillRule = true
    
    let filledShapePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight - bottomBarHeight), cornerRadius: 0)
    filledShapePath.append(emptyShapePath)
    filledShapePath.usesEvenOddFillRule = true
    
    editLayer = CAShapeLayer()
    editLayer.path = filledShapePath.cgPath
    editLayer.fillRule = kCAFillRuleEvenOdd
    editLayer.fillColor = UIColor.black.cgColor
    editLayer.opacity = 0.5
    viewController.view.layer.addSublayer(editLayer)
    
    // Move and Scale label
    label = UILabel(frame: CGRect(x: 0, y: 10, width: viewWidth, height: 50))
    label.text = "Move and Scale"
    label.textAlignment = .center
    label.textColor = UIColor.white
    viewController.view.addSubview(label)
  }
  
  
  private func hideDefaultEditOverlay(view: UIView) {
    for subview in view.subviews
    {
      if let cropOverlay = NSClassFromString("PLCropOverlayCropView")
      {
        if subview.isKind(of: cropOverlay) {
          subview.isHidden = true
          break
        }
        else {
          hideDefaultEditOverlay(view: subview)
        }
      }
    }
  }

}
