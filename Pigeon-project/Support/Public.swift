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
import Photos



public let messageStatusRead = "Read"
public let messageStatusSent = "Sent"
public let messageStatusSending = "Sending"
public let messageStatusDelivered = "Delivered"

let cameraAccessDeniedMessage = "Pigeon needs access to your camera to take photos and videos.\n\nPlease go to Settings –– Privacy –– Camera –– and set Pigeon to ON."
let photoLibraryAccessDeniedMessage = "Pigeon needs access to your photo library to send photos and videos.\n\nPlease go to Settings –– Privacy –– Photos –– and set Pigeon to ON."

let cameraAccessDeniedMessageProfilePicture = "Pigeon needs access to your camera to take photo for your profile.\n\nPlease go to Settings –– Privacy –– Camera –– and set Pigeon to ON."
let photoLibraryAccessDeniedMessageProfilePicture = "Pigeon needs access to your photo library to select photo for your profile.\n\nPlease go to Settings –– Privacy –– Photos –– and set Pigeon to ON."

let videoRecordedButLibraryUnavailableError = "To send a recorded video, it has to be saved to your photo library first. Please go to Settings –– Privacy –– Photos –– and set Pigeon to ON."

let basicErrorTitleForAlert = "Error"
let basicTitleForAccessError = "Please Allow Access"
let noInternetError = "Internet is not available. Please try again later"

extension String {
  
  var digits: String {
    return components(separatedBy: CharacterSet.decimalDigits.inverted)
      .joined()
  }
}

extension Int {
  func toString() -> String {
    let myString = String(self)
    return myString
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
    dateFormatter.dateFormat = "dd/MM/yy"
   // dateFormatter.amSymbol = "AM"
   // dateFormatter.pmSymbol = "PM"
    
    return dateFormatter.string(from: date)
  }
}

extension Double {
  func getTimeStringFromUTC() -> String {
    let date = Date(timeIntervalSince1970: self)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.dateFormat = "hh:mm a"
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
    dateFormatter.dateFormat = "dd.MM.yyyy hh:mm a"
    
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


extension SystemSoundID {
  static func playFileNamed(fileName: String, withExtenstion fileExtension: String) {
    var sound: SystemSoundID = 0
    if let soundURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
      AudioServicesCreateSystemSoundID(soundURL as CFURL, &sound)
      AudioServicesPlaySystemSound(sound)
    }
  }
}

func basicErrorAlertWith (title: String, message: String, controller: UIViewController) {
  
  let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
  alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil))
  controller.present(alert, animated: true, completion: nil)
}


func libraryAccessChecking() -> Bool {
  
  let status = PHPhotoLibrary.authorizationStatus()
  
  switch status {
  case .authorized:
    return true
    
  case .denied, .restricted :
    return false
    
  case .notDetermined:
    return false
  }
}

func cameraAccessChecking() -> Bool  {
  
  if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
    
    return true
    
  } else {
    
    return false
  }
}


func timeAgoSinceDate(date:NSDate, timeinterval: Double, numericDates:Bool) -> String {
  let calendar = NSCalendar.current
  let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
  let now = NSDate()
  let earliest = now.earlierDate(date as Date)
  let latest = (earliest == now as Date) ? date : now
  let components = calendar.dateComponents(unitFlags, from: earliest as Date,  to: latest as Date)
  
  if (components.year! >= 2) {
    return timeinterval.getShortDateStringFromUTC()//"\(components.year!) years ago"
  } else if (components.year! >= 1){
    if (numericDates){
      return timeinterval.getShortDateStringFromUTC()//"1 year ago"
    } else {
      return timeinterval.getShortDateStringFromUTC()//"last year"
    }
  } else if (components.month! >= 2) {
    return timeinterval.getShortDateStringFromUTC()//"\(components.month!) months ago"
  } else if (components.month! >= 1){
    if (numericDates){
      return timeinterval.getShortDateStringFromUTC()//"1 month ago"
    } else {
      return timeinterval.getShortDateStringFromUTC()
    }
  } else if (components.weekOfYear! >= 2) {
    return "\(components.weekOfYear!) weeks ago"
  } else if (components.weekOfYear! >= 1){
    if (numericDates){
      return "1 week ago"
    } else {
      return "last week"
    }
  } else if (components.day! >= 2) {
    return "\(components.day!) days ago"
  } else if (components.day! >= 1){
    if (numericDates){
      return "1 day ago"
    } else {
      return "yesterday"
    }
  } else if (components.hour! >= 2) {
    return "\(components.hour!) hours ago"
  } else if (components.hour! >= 1){
    if (numericDates){
      return "1 hour ago"
    } else {
      return "an hour ago"
    }
  } else if (components.minute! >= 2) {
    return "\(components.minute!) minutes ago"
  } else if (components.minute! >= 1){
    if (numericDates){
      return "1 minute ago"
    } else {
      return "a minute ago"
    }
  } else if (components.second! >= 30) {
    return "\(components.second!) seconds ago"
  } else {
    return "just now"
  }
  
}

//struct AppUtility {
//
//  static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
//
//    if let delegate = UIApplication.shared.delegate as? AppDelegate {
//      delegate.orientationLock = orientation
//    }
//  }
//
//  /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
//  static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
//    
//    self.lockOrientation(orientation)
//    
//    UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
//  }
//  
//}


extension UINavigationItem {
  
  func setTitle(title:String, subtitle:String) {
    
    let one = UILabel()
    one.text = title
  //  one.textAlignment = .center
    one.font = UIFont.systemFont(ofSize: 17)
    one.sizeToFit()
    
    
    let two = UILabel()
    two.text = subtitle
    two.font = UIFont.systemFont(ofSize: 12)
    two.textAlignment = .center
    two.textColor = UIColor.lightGray
    two.sizeToFit()
    
    
    
    let stackView = UIStackView(arrangedSubviews: [one, two])
    stackView.distribution = .equalCentering
    stackView.axis = .vertical
    
    let width = max(one.frame.size.width, two.frame.size.width)
    stackView.frame = CGRect(x: 0, y: 0, width: width, height: 35)
    
    one.sizeToFit()
    two.sizeToFit()
    
    
    
    self.titleView = stackView
  }
}

extension UIImage {
  var asJPEGData: Data? {
    return UIImageJPEGRepresentation(self, 1)   // QUALITY min = 0 / max = 1
  }
  var asPNGData: Data? {
    return UIImagePNGRepresentation(self)
  }
}


extension PHAsset {
  
  var originalFilename: String? {
    
    var fname:String?
    
    if #available(iOS 9.0, *) {
      let resources = PHAssetResource.assetResources(for: self)
      if let resource = resources.first {
        fname = resource.originalFilename
      }
    }
    
    if fname == nil {
      // this is an undocumented workaround that works as of iOS 9.1
      fname = self.value(forKey: "filename") as? String
    }
    
    return fname
  }
}


extension Data {
  var asUIImage: UIImage? {
    return UIImage(data: self)
  }
}

extension FileManager {
  func clearTemp() {
    do {
      let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
      try tmpDirectory.forEach { file in
        let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
        try FileManager.default.removeItem(atPath: path)
      }
    } catch {
      print(error)
    }
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
}


public let statusOnline = "Online"
public let userMessagesFirebaseFolder = "userMessages"
public let messageMetaDataFirebaseFolder = "metaData"

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

func imageWithImage (sourceImage:UIImage, scaledToWidth: CGFloat) -> UIImage? {
  let oldWidth = sourceImage.size.width
  let scaleFactor = scaledToWidth / oldWidth
  
  let newHeight = sourceImage.size.height * scaleFactor
  let newWidth = oldWidth * scaleFactor
  
  UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
  sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
  let newImage = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  return newImage
}

func imageWithImageHeight (sourceImage:UIImage, scaledToHeight: CGFloat) -> UIImage {
  let oldHeight = sourceImage.size.height
  let scaleFactor = scaledToHeight / oldHeight
  
  let newWidth = sourceImage.size.width * scaleFactor
  let newHeight = oldHeight * scaleFactor
  
  UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
  sourceImage.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
  let newImage = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  return newImage!
}

func createImageThumbnail (_ image: UIImage) -> UIImage {
  
  let actualHeight:CGFloat = image.size.height
  let actualWidth:CGFloat = image.size.width
  let imgRatio:CGFloat = actualWidth/actualHeight
  let maxWidth:CGFloat = 150.0
  let resizedHeight:CGFloat = maxWidth/imgRatio
  let compressionQuality:CGFloat = 0.5
  
  let rect:CGRect = CGRect(x: 0, y: 0, width: maxWidth, height: resizedHeight)
  UIGraphicsBeginImageContext(rect.size)
  image.draw(in: rect)
  let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
  let imageData:Data = UIImageJPEGRepresentation(img, compressionQuality)!
  UIGraphicsEndImageContext()
  
  return UIImage(data: imageData)!
}


func compressImage(image: UIImage) -> Data {
  // Reducing file size to a 10th
  
  var actualHeight : CGFloat = image.size.height
  var actualWidth : CGFloat = image.size.width
  let maxHeight : CGFloat = 1136.0
  let maxWidth : CGFloat = 640.0
  var imgRatio : CGFloat = actualWidth/actualHeight
  let maxRatio : CGFloat = maxWidth/maxHeight
  var compressionQuality : CGFloat = 0.5
  
  if (actualHeight > maxHeight || actualWidth > maxWidth) {
    
    if (imgRatio < maxRatio) {
      
      //adjust width according to maxHeight
      imgRatio = maxHeight / actualHeight;
      actualWidth = imgRatio * actualWidth;
      actualHeight = maxHeight;
    } else if (imgRatio > maxRatio) {
      
      //adjust height according to maxWidth
      imgRatio = maxWidth / actualWidth;
      actualHeight = imgRatio * actualHeight;
      actualWidth = maxWidth;
      
    } else {
      
      actualHeight = maxHeight;
      actualWidth = maxWidth;
      compressionQuality = 1;
    }
  }
  
  let rect = CGRect(x:0.0, y:0.0, width:actualWidth, height:actualHeight);
  UIGraphicsBeginImageContext(rect.size);
  image.draw(in: rect)
  let img = UIGraphicsGetImageFromCurrentImageContext();
  let imageData = UIImageJPEGRepresentation(img!, compressionQuality);
  UIGraphicsEndImageContext();
  
  return imageData!
}

func uiImageFromAsset(phAsset: PHAsset) -> UIImage? {
  
  var img: UIImage?
  let manager = PHImageManager.default()
  let options = PHImageRequestOptions()
  options.version = .original
  options.deliveryMode = .fastFormat
  options.resizeMode = .fast
  options.isSynchronous = true
  manager.requestImageData(for: phAsset, options: options) { data, _, _, _ in
    
    if let data = data {
      img = UIImage(data: data)
    }
  }
  return img
}

func dataFromAsset(asset: PHAsset) -> Data? {
  
  var finalData: Data?
  let manager = PHImageManager.default()
  let options = PHImageRequestOptions()
  options.version = .original
  options.deliveryMode = .fastFormat
  options.isSynchronous = true
  options.resizeMode = .fast
  options.normalizedCropRect = CGRect(x: 0, y: 0, width: 1000, height: 1000)
  manager.requestImageData(for: asset, options: options) { data, _, _, _ in
    
    finalData = data
  }
  
  return finalData
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

func uploadAvatarForUserToFirebaseStorageUsingImage(_ image: UIImage, quality: CGFloat, completion: @escaping (_  imageUrl: String, _ path: String) -> ()) {
  let imageName = UUID().uuidString
  let ref = Storage.storage().reference().child("userProfilePictures").child(imageName)
  
  if let uploadData = UIImageJPEGRepresentation(image, quality) {
    ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
      
      if error != nil {
        print("Failed to upload image:", error as Any)
        completion("", "")
        return
      }
   
      
      if let imageUrl = metadata?.downloadURL()?.absoluteString {
        completion(imageUrl, metadata!.name!)
        
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

