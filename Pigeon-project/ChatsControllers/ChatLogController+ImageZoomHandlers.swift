//
//  ChatLogController+ImageZoomHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit


private var inputContainerViewWasFirstResponder = false


extension ChatLogController {
  
//  func configureImageViewBackgroundView() {
////    blackBackgroundView.navigationItem.title = "Media"
////    blackBackgroundView.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "   Done", style: .done, target: self, action: #selector(UserProfileController.handleZoomOut))
////    blackBackgroundView.navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 15)
////    blackBackgroundView.navigationBar.setItems([blackBackgroundView.navigationItem], animated: true)
//  }

  
//  func configureToolbar() {
////    let item1 = UIBarButtonItem(image: UIImage(named: "ShareExternalIcon"), style: .plain, target: self, action:nil)
////
////    item1.imageInsets = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 15)
////    blackBackgroundView.toolbar.setItems([item1], animated: true)
//  }
  
  
  func performZoomInForVideo( url: URL) {
  
    let player = AVPlayer(url: url)
    
    let inBubblePlayerViewController = AVPlayerViewController()
  
    inBubblePlayerViewController.player = player
    
    inBubblePlayerViewController.modalTransitionStyle = .crossDissolve
    
    inBubblePlayerViewController.modalPresentationStyle = .overCurrentContext
    
    if self.inputContainerView.inputTextView.isFirstResponder {
      self.inputContainerView.inputTextView.resignFirstResponder()
    }
  
    present(inBubblePlayerViewController, animated: true, completion: nil)
  }
  
  
  func performZoomInForStartingImageView(_ initialImageView: UIImageView, indexPath: IndexPath) {
  
   setupPhotos(indexPath: indexPath)
   
    /*
    inputContainerViewWasFirstResponder = false
  
    self.startingImageView = initialImageView
    
    self.startingImageView?.isHidden = true
    
    self.startingFrame = initialImageView.superview?.convert(initialImageView.frame, to: nil)
    
    zoomingImageView = UIImageView(frame: self.startingFrame!)
    
    zoomingImageView.image = startingImageView?.image
    
    zoomingImageView.isUserInteractionEnabled = true
    
    zoomingImageView.addGestureRecognizer(zoomOutGesture)
    
    
    if let keyWindow = UIApplication.shared.keyWindow {
      self.blackBackgroundView = ImageViewBackgroundView(frame: keyWindow.frame)
      self.blackBackgroundView.alpha = 0
      keyWindow.addSubview(self.blackBackgroundView)
      keyWindow.addSubview(zoomingImageView)
      
      configureImageViewBackgroundView()
      configureToolbar()

      guard let zoomingImage = zoomingImageView.image else {
        return
      }
      guard let scaledImage = imageWithImage(sourceImage: zoomingImage, scaledToWidth: deviceScreen.width) else {
        return
      }
      let centerY = blackBackgroundView.center.y - (scaledImage.size.height/2)
      
      
      UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
        
        self.blackBackgroundView.alpha = 1
        
        if self.inputContainerView.inputTextView.isFirstResponder {
          inputContainerViewWasFirstResponder = true
          self.inputContainerView.inputTextView.resignFirstResponder()
        }
        
        
         self.inputContainerView.frame = CGRect(x: 0, y: 50, width: self.view.frame.width, height: 50)
        self.inputContainerView.isHidden = true
        
        
        if scaledImage.size.height > deviceScreen.height - 64 - 50 {
         let image = imageWithImageHeight(sourceImage: scaledImage, scaledToHeight:  scaledImage.size.height - 65 - 55)
          let centerY = self.blackBackgroundView.center.y - (image.size.height/2)
          let centerX = self.blackBackgroundView.center.x - (image.size.width/2)
          
          
           self.zoomingImageView.frame = CGRect(x: centerX, y: centerY+7 , width: image.size.width, height: image.size.height)
        } else {
           self.zoomingImageView.frame = CGRect(x: 0, y: centerY+5 , width: scaledImage.size.width, height: scaledImage.size.height)
        }
        
      }, completion: { (completed) in
        // do nothing
      })
    }
    
    
    */
  }
  
//  func handleZoomOut() {
//  
//    if let zoomOutImageView = zoomOutGesture.view {
//    
//      zoomOutImageView.layer.masksToBounds = true
//      
//      UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
//        
//        zoomOutImageView.frame = self.startingFrame!
//        
//        self.blackBackgroundView.alpha = 0
//        self.inputContainerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
//          self.inputContainerView.isHidden = false
//        
//        zoomOutImageView.layer.cornerRadius = 16
//       // zoomOutImageView.contentMode = .scaleAspectFill
//        
//        if inputContainerViewWasFirstResponder {
//           self.inputContainerView.inputTextView.becomeFirstResponder()
//        }
//        
//      }, completion: { (completed) in
//        
//        zoomOutImageView.removeFromSuperview()
//        self.blackBackgroundView = nil
//       
//        
//        self.startingImageView?.isHidden = false
//      })
//    }
//  }
}
