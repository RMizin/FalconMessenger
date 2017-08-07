//
//  Public.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseStorage
import Firebase


public extension UIView {
  
  func shake(count : Float? = nil,for duration : TimeInterval? = nil,withTranslation translation : Float? = nil) {
    
    // You can change these values, so that you won't have to write a long function
    let defaultRepeatCount = 3
    let defaultTotalDuration = 0.1
    let defaultTranslation = -8
    
    let animation : CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.x")
    animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
    
    animation.repeatCount = count ?? Float(defaultRepeatCount)
    animation.duration = (duration ?? defaultTotalDuration)/TimeInterval(animation.repeatCount)
    animation.autoreverses = true
    animation.byValue = translation ?? defaultTranslation
    layer.add(animation, forKey: "shake")
    
  }
}

func uploadAvatarForUserToFirebaseStorageUsingImage(_ image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
  let imageName = UUID().uuidString
  let ref = Storage.storage().reference().child("message_images").child(imageName)
  
  if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
    ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
      
      if error != nil {
        print("Failed to upload image:", error as Any)
        return
      }
      
      if let imageUrl = metadata?.downloadURL()?.absoluteString {
        completion(imageUrl)
        
      }
      
    })
  }
}



private var backgroundView: UIView = {
  let backgroundView = UIView()
  backgroundView.backgroundColor = UIColor.black
  backgroundView.alpha = 0.8
  backgroundView.layer.cornerRadius = 0
  backgroundView.layer.masksToBounds = true
  backgroundView.frame = CGRect(origin: CGPoint(x: 0 , y: 0), size: CGSize(width: 100, height: 100))
  
  return backgroundView
}()

private var activityIndicator: UIActivityIndicatorView = {
  var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
  activityIndicator.hidesWhenStopped = true
  activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);
  activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
  activityIndicator.autoresizingMask = [.flexibleLeftMargin , .flexibleRightMargin , .flexibleTopMargin , .flexibleBottomMargin]
  activityIndicator.isUserInteractionEnabled = false
  
  return activityIndicator
}()


extension UIImageView {
  
  func showActivityIndicator() {
    
    self.addSubview(backgroundView)
    self.addSubview(activityIndicator)
    
    activityIndicator.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
    backgroundView.center = activityIndicator.center

    DispatchQueue.main.async {
      activityIndicator.startAnimating()
    }
    
  }
  
  
  func hideActivityIndicator() {
    DispatchQueue.main.async {
      activityIndicator.stopAnimating()
    }
    
      activityIndicator.removeFromSuperview()
      backgroundView.removeFromSuperview()
  }
  
}

