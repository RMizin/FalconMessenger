////
////  PresenseManager.swift
////  FalconMessenger
////
////  Created by Roman Mizin on 12/15/18.
////  Copyright © 2018 Roman Mizin. All rights reserved.
////
//
//import UIKit
//import Firebase
//
//protocol PresenseManagerDelegate: class {
//	func appOfflineAtLaunch()
////	func appOnlineAtLaunch()
//
//	func appOfflineAtRuntime()
//	func appOnlineAtRuntime()
//}
//
//
//
////
////
////class FalconNavigationController: UINavigationController, PresenseManagerDelegate {
////
////	let presenseManager = PresenseManager()
////
////	override init(rootViewController: UIViewController) {
////		super.init(rootViewController: rootViewController)
////		presenseManager.delegate = self
////		presenseManager.startManagingPresense()
////	}
////
////	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
////		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
////		presenseManager.delegate = self
////		presenseManager.startManagingPresense()
////	}
////
////	required init?(coder aDecoder: NSCoder) {
////		fatalError("init(coder:) has not been implemented")
////	}
////
////	func appOfflineAtLaunch() {
////	//	navigationController?.navigationItem
////	presenseManager.navigationItemActivityIndicator.showActivityIndicator(for: navigationItem,
////																													with: .noInternet,
////																													activityPriority: .crazy,
////																													color: ThemeManager.currentTheme().generalTitleColor)
////	}
////
////	func appOfflineAtRuntime() {
////		presenseManager.navigationItemActivityIndicator.showActivityIndicator(for: navigationItem,
////																													with: .noInternet,
////																													activityPriority: .crazy,
////																													color: ThemeManager.currentTheme().generalTitleColor)
////	}
////
////	func appOnlineAtRuntime() {
////		presenseManager.navigationItemActivityIndicator.hideActivityIndicator(for: navigationItem, activityPriority: .crazy)
////	}
////
////
////
////
////
////}
//
//final class PresenseManager: NSObject {
//
//
//	weak var delegate: PresenseManagerDelegate?
//	//fileprivate let presenseUIUpdater = PresenseUIUpdater()
//	let navigationItemActivityIndicator = NavigationItemActivityIndicator()
//
////
////	override init() {
////		super.init()
////		managePresense()
//////		addObservers()
////	}
//
////	fileprivate func addObservers() {
////		NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
////	}
////
////	@objc fileprivate func changeTheme() {
////	//	presenseUIUpdater.navigationItemActivityIndicator.activityIndicatorView.color = ThemeManager.currentTheme().generalTitleColor
//////		presenseUIUpdater.navigationItemActivityIndicator.titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
////	}
//
//	public func startManagingPresense() {
//		if currentReachabilityStatus == .notReachable {
//			delegate?.appOfflineAtLaunch()
//		//	presenseUIUpdater.update(isOnline: false)
//		}
//
//		let connectedReference = Database.database().reference(withPath: ".info/connected")
//		connectedReference.observe(.value, with: {  (snapshot) in
//
//			if self.currentReachabilityStatus != .notReachable {
//				self.delegate?.appOnlineAtRuntime()
//			//	self.presenseUIUpdater.update(isOnline: true)
//
//			} else {
//				self.delegate?.appOfflineAtRuntime()
//			//	self.presenseUIUpdater.update(isOnline: false)
//		//		self.delegate?.appOfflineAtRuntime()
//			}
//		})
//	}
//}
//
////final class PresenseUIUpdater: NSObject {
////
////	let navigationItemActivityIndicator = NavigationItemActivityIndicator()
////
////	func update(isOnline: Bool) {
//////		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//////		guard let controller = appDelegate.tabBarController?.chatsController.navigationItem else { return }
////
////	//	for controller in controllers where controller is UINavigationController {
////		//	guard controller != nil else { return }
////
////			if isOnline {
////		//		NotificationCenter.default.post(name: .appOnline, object: nil)
////			//	navigationItemActivityIndicator.hideActivityIndicator(for: controller, activityPriority: .crazy)
////			} else {
////				//NotificationCenter.default.post(name: .appOffline, object: nil)
//////			//	navigationItemActivityIndicator.showActivityIndicator(for: controller,
//////																															with: .noInternet,
//////																															activityPriority: .crazy,
//////																															color: ThemeManager.currentTheme().generalTitleColor)
//////			}
////	//	}
////	}
////}
//
//
////extension NSNotification.Name {
////	static let appOffline = NSNotification.Name(Bundle.main.bundleIdentifier! + ".appOffline")
////	static let appOnline = NSNotification.Name(Bundle.main.bundleIdentifier! + ".appOnline")
////}
