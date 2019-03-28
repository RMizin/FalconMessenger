//
//  Public.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SystemConfiguration
import Photos
import RealmSwift
import SDWebImage

struct ScreenSize {
  static let width = UIScreen.main.bounds.size.width
  static let height = UIScreen.main.bounds.size.height
  static let maxLength = max(ScreenSize.width, ScreenSize.height)
  static let minLength = min(ScreenSize.width, ScreenSize.height)
  static let frame = CGRect(x: 0, y: 0, width: ScreenSize.width, height: ScreenSize.height)
}

struct DeviceType {
  static let iPhone4orLess = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength < 568.0
  static let iPhone5orSE = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 568.0
  static let iPhone678 = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 667.0
  static let iPhone678p = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 736.0
  static let iPhoneX = UIDevice.current.userInterfaceIdiom == .phone && (ScreenSize.maxLength == 812.0 || ScreenSize.maxLength == 896.0)
  
 // static let IS_IPAD = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.maxLength == 1024.0
  static let IS_IPAD_PRO = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.maxLength == 1366.0
  static let isIPad = UIDevice.current.userInterfaceIdiom == .pad
}

struct AppUtility {
  
  static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
    
    if let delegate = UIApplication.shared.delegate as? AppDelegate {
      delegate.orientationLock = orientation
    }
  }

  static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
    self.lockOrientation(orientation)
    UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
  }
}

struct NameConstants {
  static let personalStorage = "Personal Storage"
}

public let messageStatusRead = "Read"
public let messageStatusSending = "Sending"
public let messageStatusNotSent = "Not sent"
public let messageStatusDelivered = "Delivered"

let cameraAccessDeniedMessage = "Falcon needs access to your camera to take photos and videos.\n\nPlease go to Settings –– Privacy –– Camera –– and set Falcon to ON."
let contactsAccessDeniedMessage = "Falcon needs access to your contacts to create new ones.\n\nPlease go to Settings –– Privacy –– Contacts –– and set Falcon to ON."
let microphoneAccessDeniedMessage = "Falcon needs access to your microphone to record audio messages.\n\nPlease go to Settings –– Privacy –– Microphone –– and set Falcon to ON."
let photoLibraryAccessDeniedMessage = "Falcon needs access to your photo library to send photos and videos.\n\nPlease go to Settings –– Privacy –– Photos –– and set Falcon to ON."

let cameraAccessDeniedMessageProfilePicture = "Falcon needs access to your camera to take photo for your profile.\n\nPlease go to Settings –– Privacy –– Camera –– and set Falcon to ON."
let photoLibraryAccessDeniedMessageProfilePicture = "Falcon needs access to your photo library to select photo for your profile.\n\nPlease go to Settings –– Privacy –– Photos –– and set Falcon to ON."

let videoRecordedButLibraryUnavailableError = "To send a recorded video, it has to be saved to your photo library first. Please go to Settings –– Privacy –– Photos –– and set Falcon to ON."

let basicErrorTitleForAlert = "Error"
let basicTitleForAccessError = "Please Allow Access"
let noInternetError = "Internet is not available. Please try again later"
let copyingImageError = "You cannot copy not downloaded image, please wait until downloading finished"

let deletionErrorMessage = "There was a problem when deleting. Try again later."
let cameraNotExistsMessage = "You don't have camera"
let thumbnailUploadError = "Failed to upload your image to database. Please, check your internet connection and try again."
let fullsizePictureUploadError = "Failed to upload fullsize image to database. Please, check your internet connection and try again. Despite this error, thumbnail version of this picture has been uploaded, but you still should re-upload your fullsize image."

extension List where Element == String {
	func assign(_ array: [String]?) {
		guard let array = array else { return }
		removeAll()
		insert(contentsOf: array, at: 0)
	}

	func assign(_ array: List<String>?) {
		guard let array = array else { return }
		removeAll()
		insert(contentsOf: array, at: 0)
	}
}
extension List where Element == Message {
	func assign(_ array: Results<Message>?) {
		guard let array = array else { return }
		removeAll()

		insert(contentsOf: array, at: 0)
	}
}

extension Realm {
	public func safeWrite(_ block: (() throws -> Void)) throws {
		if isInWriteTransaction {
			try block()
		} else {
			try write(block)
		}
	}
}

extension Date {
	static func dateFromCustomString(customString: String) -> Date {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd/MM/yyyy"
		return dateFormatter.date(from: customString) ?? Date()
	}
}

extension UICollectionView {
  func deselectAllItems(animated: Bool = false) {
    for indexPath in self.indexPathsForSelectedItems ?? [] {
      self.deselectItem(at: indexPath, animated: animated)
    }
  }
}

extension Array {
  public func stablePartition(by condition: (Element) throws -> Bool) rethrows -> ([Element], [Element]) {
    var indexes = Set<Int>()
    for (index, element) in self.enumerated() {
      if try condition(element) {
        indexes.insert(index)
      }
    }
    var matching = [Element]()
    matching.reserveCapacity(indexes.count)
    var nonMatching = [Element]()
    nonMatching.reserveCapacity(self.count - indexes.count)
    for (index, element) in self.enumerated() {
      if indexes.contains(index) {
        matching.append(element)
      } else {
        nonMatching.append(element)
      }
    }
    return (matching, nonMatching)
  }
}

extension UIApplication {
  
  class func topViewController(_ baseViewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    
    if let navigationController = baseViewController as? UINavigationController {
      return topViewController(navigationController.visibleViewController)
    }
    
    if let tabBarViewController = baseViewController as? UITabBarController {
      
      let moreNavigationController = tabBarViewController.moreNavigationController
      
      if let topViewController1 = moreNavigationController.topViewController, topViewController1.view.window != nil {
        return topViewController(topViewController1)
      } else if let selectedViewController = tabBarViewController.selectedViewController {
        return topViewController(selectedViewController)
      }
    }
    
    if let splitViewController = baseViewController as? UISplitViewController, splitViewController.viewControllers.count == 1 {
      return topViewController(splitViewController.viewControllers[0])
    } else if let splitViewController = baseViewController as? UISplitViewController, splitViewController.viewControllers.count == 2 {
      return topViewController(splitViewController.viewControllers[1])
    }
    
    if let presentedViewController = baseViewController?.presentedViewController {
      return topViewController(presentedViewController)
    }
    
    return baseViewController
  }
}

extension String {
  
  var digits: String {
    return components(separatedBy: CharacterSet.decimalDigits.inverted)
      .joined()
  }
  
  var doubleValue: Double {
    return Double(self) ?? 0
  }
}

extension UINavigationController {
  
  func backToViewController(viewController: Swift.AnyClass) {
    
    for element in viewControllers {
      if element.isKind(of: viewController) {
        self.popToViewController(element, animated: true)
        break
      }
    }
  }
}

//extension Array {
//  
//  func shift(withDistance distance: Int = 1) -> Array<Element> {
//    let offsetIndex = distance >= 0 ?
//      self.index(startIndex, offsetBy: distance, limitedBy: endIndex) :
//      self.index(endIndex, offsetBy: distance, limitedBy: startIndex)
//    
//    guard let index = offsetIndex else { return self }
//    return Array(self[index ..< endIndex] + self[startIndex ..< index])
//  }
//  
//  mutating func shiftInPlace(withDistance distance: Int = 1) {
//    self = shift(withDistance: distance)
//  }
//}

extension Array {
  func insertionIndexOf(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
    var lo = 0
    var hi = self.count - 1
    while lo <= hi {
      let mid = (lo + hi)/2
      if isOrderedBefore(self[mid], elem) {
        lo = mid + 1
      } else if isOrderedBefore(elem, self[mid]) {
        hi = mid - 1
      } else {
        return mid // found at position mid
      }
    }
    return lo // not found, would be inserted at position lo
  }
}

extension Collection {
  func insertionIndex(of element: Self.Iterator.Element,
                      using areInIncreasingOrder: (Self.Iterator.Element, Self.Iterator.Element) -> Bool) -> Index {
		return firstIndex(where: { !areInIncreasingOrder($0, element) }) ?? endIndex
  }
}

extension Bool {
  init<T: BinaryInteger>(_ num: T) {
    self.init(num != 0)
  }
}

extension Int {
  func toString() -> String {
    let myString = String(self)
    return myString
  }
}

extension String {
  func sizeOfString(usingFont font: UIFont) -> CGSize {
		let fontAttributes = [NSAttributedString.Key.font: font]
    return self.capitalized.size(withAttributes: fontAttributes)
  }
}

extension Date {
  
  func getShortDateStringFromUTC() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.dateFormat = "dd/MM/yy"
    return dateFormatter.string(from: self)
  }
  
  func getTimeStringFromUTC() -> String {
    let dateFormatter = DateFormatter()
    let locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.locale = locale
    dateFormatter.dateStyle = .medium
    dateFormatter.dateFormat = "hh:mm a"
    dateFormatter.amSymbol = "AM"
    dateFormatter.pmSymbol = "PM"
    return dateFormatter.string(from: self)
  }

  func dayOfWeek() -> String {
    let dateFormatter = DateFormatter()
    let locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.locale = locale
    dateFormatter.dateFormat = "E"
    return dateFormatter.string(from: self).capitalized
  }
  
  func dayNumberOfWeek() -> Int {
    return Calendar.current.dateComponents([.weekday], from: self).weekday!
  }
  func monthNumber() -> Int {
    return Calendar.current.dateComponents([.month], from: self).month!
  }
  func yearNumber() -> Int {
    return Calendar.current.dateComponents([.year], from: self).year!
  }
}

var context = CIContext(options: nil)

func blurEffect(image: UIImage) -> UIImage {

	let currentFilter = CIFilter(name: "CIGaussianBlur")
	let beginImage = CIImage(image: image)
	currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
	currentFilter!.setValue(5, forKey: kCIInputRadiusKey)
	guard let unwrappedBeginImage = beginImage else { return UIImage() }

	let cropFilter = CIFilter(name: "CICrop")
	cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
	let cgrect = CGRect(x: unwrappedBeginImage.extent.origin.x + 10,
											y: unwrappedBeginImage.extent.origin.y + 10,
											width: unwrappedBeginImage.extent.size.width - 20,
											height: unwrappedBeginImage.extent.size.height - 20)
	cropFilter!.setValue(CIVector(cgRect: cgrect), forKey: "inputRectangle")

	let output = cropFilter!.outputImage
	let cgimg = context.createCGImage(output!, from: output!.extent)
	let processedImage = UIImage(cgImage: cgimg!)
	return processedImage
}

func timestampOfLastMessage(_ date: Date) -> String {
  let calendar = NSCalendar.current
  let unitFlags: Set<Calendar.Component> = [ .day, .weekOfYear, .weekday]
  let now = Date()
  let earliest = now < date ? now : date
  let latest = (earliest == now) ? date : now
  let components =  calendar.dateComponents(unitFlags, from: earliest,  to: latest)
  
//  if components.weekOfYear! >= 1 {
//    return date.getShortDateStringFromUTC()
//  } else if components.weekOfYear! < 1 && date.dayNumberOfWeek() != now.dayNumberOfWeek() {
//    return date.dayOfWeek()
//  } else {
//    return date.getTimeStringFromUTC()
//  }
  
  if now.getShortDateStringFromUTC() != date.getShortDateStringFromUTC() {  // not today
    if components.weekOfYear! >= 1 { // last week
      return date.getShortDateStringFromUTC()
    } else { // this week
      return date.dayOfWeek()
    }
  } else { // this day
    return date.getTimeStringFromUTC()
  }
}

func timestampOfChatLogMessage(_ date: Date) -> String {
  return date.getTimeStringFromUTC()
}

func timeAgoSinceDate(_ date:Date, numericDates:Bool = false) -> String {
  let calendar = NSCalendar.current
  let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
  let now = Date()
  let earliest = now < date ? now : date
  let latest = (earliest == now) ? date : now
  let components = calendar.dateComponents(unitFlags, from: earliest,  to: latest)
  
  if (components.year! >= 2) {
    return "\(components.year!) years ago"
  } else if (components.year! >= 1){
    if (numericDates){
      return "1 year ago"
    } else {
      return "last year"
    }
  } else if (components.month! >= 2) {
    return "\(components.month!) months ago"
  } else if (components.month! >= 1){
    if (numericDates){
      return "1 month ago"
    } else {
      return "last month"
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
      return "yesterday at \(date.getTimeStringFromUTC())"
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
  } else if (components.second! >= 3) {
    return "just now"//"\(components.second!) seconds ago"
  } else {
    return "just now"
  }
}

extension UITextField {
  
  var doneAccessory: Bool {
    get {
      return true
    }
    set (hasDone) {
      if hasDone {
        addDoneButtonOnKeyboard()
      }
    }
  }
  
  func addDoneButtonOnKeyboard() {
    let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 25))
    doneToolbar.barStyle = ThemeManager.currentTheme().barStyle
    let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
		let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
																											NSAttributedString.Key.baselineOffset: -1]
    done.setTitleTextAttributes(attributes, for: .normal)
    done.setTitleTextAttributes(attributes, for: .selected)
    doneToolbar.clipsToBounds = true
    
    let items = [flexSpace, done]
    doneToolbar.items = items
    inputAccessoryView = doneToolbar
  }
  
  @objc func doneButtonAction() {
    self.resignFirstResponder()
  }
}

extension UITableViewCell {
  var selectionColor: UIColor {
    set {
      let view = UIView()
      view.backgroundColor = newValue

      self.selectedBackgroundView = view
    }
    get {
      return self.selectedBackgroundView?.backgroundColor ?? UIColor.clear
    }
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

func basicErrorAlertWith (title: String, message: String, controller: UIViewController?) {
	guard let controller = controller else { return }
	let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
	alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil))
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
	@unknown default:
		fatalError()
	}
}

public let statusOnline = "Online"
public let userMessagesFirebaseFolder = "userMessages"
public let messageMetaDataFirebaseFolder = "metaData"

func setOnlineStatus()  {
  
  guard Auth.auth().currentUser != nil, let currentUID = Auth.auth().currentUser?.uid else { return }

  let onlineStatusReference = Database.database().reference().child("users").child(currentUID).child("OnlineStatus")
  let connectedRef = Database.database().reference(withPath: ".info/connected")
  
  connectedRef.observe(.value, with: { (snapshot) in
    guard let connected = snapshot.value as? Bool, connected else { return }
    onlineStatusReference.setValue(statusOnline)
   
    onlineStatusReference.onDisconnectSetValue(ServerValue.timestamp())
  })
}


extension UIImage {
  var asJPEGData: Data? {
    return self.jpegData(compressionQuality: 1)   // QUALITY min = 0 / max = 1
  }
  var asPNGData: Data? {
		return self.pngData()
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

	func getTempSize(completion: (_ size: Double) -> Void) {
	 var size = 0.0
		do {
			let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
			try tmpDirectory.forEach { file in
				let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
				let attributes = try FileManager.default.attributesOfItem(atPath: path)
				if let fileSize = attributes[FileAttributeKey.size] as? Double {
					size += fileSize
				} else {
					size += 0
				}
			}
			completion(size)
		} catch {
			size += 0
			completion(size)
		}
	}

	func clearTemp() {
		do {
			let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
			try tmpDirectory.forEach { file in
				let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
				try FileManager.default.removeItem(atPath: path)
			}
		} catch {}
	}
}

extension Double {
	func round(to places: Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return Darwin.round(self * divisor) / divisor
	}
}
//public func rearrange<T>(array: Array<T>, fromIndex: Int, toIndex: Int) -> Array<T>{
//  var arr = array
//  let element = arr.remove(at: fromIndex)
//  arr.insert(element, at: toIndex)
//
//  return arr
//}

extension Double {
	private static let arc4randomMax = Double(UInt32.max)
	static func random0to1() -> Double {
		return Double(arc4random()) / arc4randomMax
	}
}

extension Array where Element: Equatable {
  mutating func move(_ element: Element, to newIndex: Index) {
		if let oldIndex: Int = self.firstIndex(of: element) { self.move(from: oldIndex, to: newIndex) }
  }
}

extension Array {
  mutating func move(from oldIndex: Index, to newIndex: Index) {
    // Don't work for free and use swap when indices are next to each other - this
    // won't rebuild array and will be super efficient.
    if oldIndex == newIndex { return }
    if abs(newIndex - oldIndex) == 1 { return self.swapAt(oldIndex, newIndex) }
    self.insert(self.remove(at: oldIndex), at: newIndex)
  }
}

extension UISearchBar {
  func changeBackgroundColor(to color: UIColor) {
    if let textfield = self.value(forKey: "searchField") as? UITextField {
      textfield.textColor = UIColor.blue
      if let backgroundview = textfield.subviews.first {
        backgroundview.backgroundColor = color
        backgroundview.layer.cornerRadius = 10
        backgroundview.clipsToBounds = true
      }
    }
  }
}

func delay(_ delay: Double, closure:@escaping ()->()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
//	DispatchQueue.main.asyncAfter(
//		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

extension UITableView {
  
  func indexPathForView(_ view: UIView) -> IndexPath? {
    let center = view.center
    let viewCenter = self.convert(center, from: view.superview)
    let indexPath = self.indexPathForRow(at: viewCenter)
    return indexPath
  }
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

func prefetchThumbnail(from urlString: String?) {
	if let thumbnail = urlString, let url = URL(string: thumbnail) {
		SDWebImagePrefetcher.shared.prefetchURLs([url], progress: nil) { (finished, skipped) in
//			print("finished", finished, "skipped", skipped)
		}
	}
}

func prefetchThumbnail(from urls: [URL]?) {
	SDWebImagePrefetcher.shared.prefetchURLs(urls, progress: nil) { (finished, skipped) in
//		print("finished", finished, "skipped", skipped)
	}
}

func prefetchThumbnail(from urlStrings: [String]) {
	let urls = urlStrings.compactMap({ URL(string: $0) })
	SDWebImagePrefetcher.shared.prefetchURLs(urls, progress: nil) { (finished, skipped) in
//		print("finished", finished, "skipped", skipped)
	}
}

extension UITableView {
	func hasRow(at indexPath: IndexPath) -> Bool {
		return indexPath.section < self.numberOfSections && indexPath.row < self.numberOfRows(inSection: indexPath.section)
	}
}


func createImageThumbnail (_ image: UIImage) -> UIImage {
  
  let actualHeight: CGFloat = image.size.height
  let actualWidth: CGFloat = image.size.width
  let imgRatio: CGFloat = actualWidth/actualHeight
  let maxWidth: CGFloat = 150.0
  let resizedHeight: CGFloat = maxWidth/imgRatio
  let compressionQuality: CGFloat = 0.3
  
  let rect: CGRect = CGRect(x: 0, y: 0, width: maxWidth, height: resizedHeight)
  UIGraphicsBeginImageContext(rect.size)
  image.draw(in: rect)
  let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
	let imageData: Data = img.jpegData(compressionQuality: compressionQuality)!
  UIGraphicsEndImageContext()
  
  return UIImage(data: imageData)!
}

func compressImage(image: UIImage) -> Data {
  // Reducing file size to a 10th
  
  var actualHeight : CGFloat = image.size.height
  var actualWidth : CGFloat = image.size.width
  let maxHeight : CGFloat = 1920.0
  let maxWidth : CGFloat = 1080.0
  var imgRatio : CGFloat = actualWidth/actualHeight
  let maxRatio : CGFloat = maxWidth/maxHeight
  var compressionQuality : CGFloat = 0.8
  
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
      
      actualHeight = maxHeight
      actualWidth = maxWidth
      compressionQuality = 1
    }
  }
  
  let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight);
  UIGraphicsBeginImageContext(rect.size)
  image.draw(in: rect)
  let img = UIGraphicsGetImageFromCurrentImageContext()
	let imageData = img!.jpegData(compressionQuality: compressionQuality)
  UIGraphicsEndImageContext();
  
  return imageData!
}

func uiImageFromAsset(phAsset: PHAsset) -> UIImage? {
  
  var img: UIImage?
  let manager = PHImageManager.default()
  let options = PHImageRequestOptions()
  options.version = .current
  options.deliveryMode = .fastFormat
  options.resizeMode = .exact
  options.isSynchronous = true
	options.isNetworkAccessAllowed = true
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
  options.version = .current
  options.deliveryMode = .fastFormat
  options.isSynchronous = true
  options.resizeMode = .exact
	options.isNetworkAccessAllowed = true
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
		animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
    
    animation.repeatCount = count ?? Float(defaultRepeatCount)
    animation.duration = (duration ?? defaultTotalDuration)/TimeInterval(animation.repeatCount)
    animation.autoreverses = true
    animation.byValue = translation ?? defaultTranslation
    layer.add(animation, forKey: "shake")
  }
}

func uploadAvatarForUserToFirebaseStorageUsingImage(_ image: UIImage, quality: CGFloat, completion: @escaping (_  imageUrl: String) -> ()) {
  let imageName = UUID().uuidString
  let ref = Storage.storage().reference().child("userProfilePictures").child(imageName)
  
  if let uploadData = image.jpegData(compressionQuality: quality) {
    ref.putData(uploadData, metadata: nil) { (metadata, error) in
      guard error == nil else { completion(""); return }
      
      ref.downloadURL(completion: { (url, error) in
        guard error == nil, let imageURL = url else { completion(""); return }
         completion(imageURL.absoluteString)
      })
    }
  }
}

private var backgroundView: UIView = {
  let backgroundView = UIView()
  backgroundView.backgroundColor = UIColor.black
  backgroundView.alpha = 0.8
  backgroundView.layer.cornerRadius = 0
  backgroundView.layer.masksToBounds = true
  
  return backgroundView
}()

private var activityIndicator: UIActivityIndicatorView = {
	var activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
  activityIndicator.hidesWhenStopped = true
  activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);
	activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
  activityIndicator.autoresizingMask = [.flexibleLeftMargin , .flexibleRightMargin , .flexibleTopMargin , .flexibleBottomMargin]
  activityIndicator.isUserInteractionEnabled = false
  
  return activityIndicator
}()


extension UIImageView {
  
  func showActivityIndicator() {
    
    self.addSubview(backgroundView)
    self.addSubview(activityIndicator)
		activityIndicator.style = .white
    activityIndicator.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    backgroundView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
    backgroundView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
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

extension UILocalizedIndexedCollation {
  
  func partitionObjects(array:[AnyObject], collationStringSelector:Selector) -> ([AnyObject], [String]) {
    var unsortedSections = [[AnyObject]]()
    
    //1. Create a array to hold the data for each section
    for _ in self.sectionTitles {
      unsortedSections.append([]) //appending an empty array
    }
    //2. Put each objects into a section
    for item in array {
      let index:Int = self.section(for: item, collationStringSelector:collationStringSelector)
      unsortedSections[index].append(item)
    }
    //3. sorting the array of each sections
    var sectionTitles = [String]()
    var sections = [AnyObject]()
    for index in 0 ..< unsortedSections.count { if unsortedSections[index].count > 0 {
      sectionTitles.append(self.sectionTitles[index])
      sections.append(self.sortedArray(from: unsortedSections[index], collationStringSelector: collationStringSelector) as AnyObject)
      }
    }
    
    return (sections, sectionTitles)
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
