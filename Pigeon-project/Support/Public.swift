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
import SystemConfiguration
import SDWebImage



extension String {
  
  var digits: String {
    return components(separatedBy: CharacterSet.decimalDigits.inverted)
      .joined()
  }
}


extension String {
  var doubleValue: Double {
    return Double(self) ?? 0
  }
}


extension Double {
  func getShortDateStringFromUTC() -> String {
    let date = Date(timeIntervalSince1970: self)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.dateFormat = "dd/MM/yy HH:mm a"
    dateFormatter.amSymbol = "AM"
    dateFormatter.pmSymbol = "PM"
    
    return dateFormatter.string(from: date)
  }
}

extension Double {
  func getDateStringFromUTC() -> String {
    let date = Date(timeIntervalSince1970: self)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
    
    return dateFormatter.string(from: date)
  }
}

extension Array {
  
  func shift(withDistance distance: Int = 1) -> Array<Element> {
    let offsetIndex = distance >= 0 ?
      self.index(startIndex, offsetBy: distance, limitedBy: endIndex) :
      self.index(endIndex, offsetBy: distance, limitedBy: startIndex)
    
    guard let index = offsetIndex else { return self }
    return Array(self[index ..< endIndex] + self[startIndex ..< index])
  }
  
  mutating func shiftInPlace(withDistance distance: Int = 1) {
    self = shift(withDistance: distance)
  }
}


public func rearrange<T>(array: Array<T>, fromIndex: Int, toIndex: Int) -> Array<T>{
  var arr = array
  let element = arr.remove(at: fromIndex)
  arr.insert(element, at: toIndex)
  
  return arr
}


extension UIScrollView {
  
  // Scroll to a specific view so that it's top is at the top our scrollview
  func scrollToView(view:UIView, animated: Bool) {
    if let origin = view.superview {
      // Get the Y position of your child view
      let childStartPoint = origin.convert(view.frame.origin, to: self)
      // Scroll to a rectangle starting at the Y of your subview, with a height of the scrollview
      self.scrollRectToVisible(CGRect(x:0, y:childStartPoint.y, width: 1, height: self.frame.height), animated: animated)
    }
  }
  
  // Bonus: Scroll to top
  func scrollToTop(animated: Bool) {
    let topOffset = CGPoint(x: 0, y: -contentInset.top)
    setContentOffset(topOffset, animated: animated)
  }
  
  // Bonus: Scroll to bottom
  func scrollToBottom() {
    let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.size.height + contentInset.bottom)
    if(bottomOffset.y + 50 > 0) {
      
      DispatchQueue.main.async {
        UIView.animate(withDuration: 0.15, delay: 0, options: [UIViewAnimationOptions.curveLinear, ], animations: {
          self.contentOffset = bottomOffset
          
        }, completion: nil)
      }
    }
  }
}


public let statusOnline = "Online"
public let userMessagesFirebaseFolder = "userMessages"

func setOnlineStatus()  {
  
  if Auth.auth().currentUser != nil {
    let myConnectionsRef = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("OnlineStatus")
    
    let connectedRef = Database.database().reference(withPath: ".info/connected")
    
    connectedRef.observe(.value, with: { (snapshot) in
      guard let connected = snapshot.value as? Bool, connected else {
        return
      }
      
      let con = myConnectionsRef
      con.setValue(statusOnline, withCompletionBlock: { (error, ref) in
        
      })
      
      let date = Date()
      let result = String(describing: date.timeIntervalSince1970)
      con.onDisconnectSetValue(result)
      
    })
    
  }
}
//
//func imageWithImage (sourceImage:UIImage, scaledToWidth: CGFloat) -> UIImage {
//  let oldWidth = sourceImage.size.width
//  let scaleFactor = scaledToWidth / oldWidth
//  
//  let newHeight = sourceImage.size.height * scaleFactor
//  let newWidth = oldWidth * scaleFactor
//  
//  UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
//  sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
//  let newImage = UIGraphicsGetImageFromCurrentImageContext()
//  UIGraphicsEndImageContext()
//  return newImage!
//}


func compressImage (_ image: UIImage) -> UIImage {
  
  let actualHeight:CGFloat = image.size.height
  let actualWidth:CGFloat = image.size.width
  let imgRatio:CGFloat = actualWidth/actualHeight
  let maxWidth:CGFloat = 100.0
  let resizedHeight:CGFloat = maxWidth/imgRatio
  let compressionQuality:CGFloat = 0.2
  
  let rect:CGRect = CGRect(x: 0, y: 0, width: maxWidth, height: resizedHeight)
  UIGraphicsBeginImageContext(rect.size)
  image.draw(in: rect)
  let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
  let imageData:Data = UIImageJPEGRepresentation(img, compressionQuality)!
  UIGraphicsEndImageContext()
  
  return UIImage(data: imageData)!
}

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



protocol Utilities {}

extension NSObject: Utilities {
  
  enum ReachabilityStatus {
    case notReachable
    case reachableViaWWAN
    case reachableViaWiFi
  }
  
  
  var currentReachabilityStatus: ReachabilityStatus {
    
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        SCNetworkReachabilityCreateWithAddress(nil, $0)
      }
    }) else {
      return .notReachable
    }
    
    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
      return .notReachable
    }
    
    if flags.contains(.reachable) == false {
      // The target host is not reachable.
      return .notReachable
    }
    else if flags.contains(.isWWAN) == true {
      // WWAN connections are OK if the calling application is using the CFNetwork APIs.
      return .reachableViaWWAN
    }
    else if flags.contains(.connectionRequired) == false {
      // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
      return .reachableViaWiFi
    }
    else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
      // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
      return .reachableViaWiFi
    }
    else {
      return .notReachable
    }
  }
  
}

