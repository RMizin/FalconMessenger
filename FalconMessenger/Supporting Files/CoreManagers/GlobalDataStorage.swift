//
//  GlobalDataStorage.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/1/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

let globalDataStorage = GlobalDataStorage()

final class GlobalDataStorage: NSObject {

	static let reportDatabaseURL = "https://pigeon-project-79c81-d6fdd.firebaseio.com/"

  var localPhones: [String] = [] {
    didSet {
      NotificationCenter.default.post(name: .localPhonesUpdated, object: nil)
    }
  }

  let imageSourcePhotoLibrary = "imageSourcePhotoLibrary"
  let imageSourceCamera = "imageSourceCamera"
  
  var isInsertingCellsToTop: Bool = false
  var contentSizeWhenInsertingToTop: CGSize?
  
  override init() {
    super.init()
    getBlockedUsers()
    
    NotificationCenter.default.addObserver(self, selector: #selector(getBlockedUsers), name: .authenticationSucceeded, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(removeBanObservers), name: NSNotification.Name(rawValue: "clearUserData"), object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  fileprivate var blockedUsers = [String]()
  fileprivate(set) var blockedUsersByCurrentUser = [String]()
  
  @objc fileprivate func removeBanObservers() {
    blockedUsers.removeAll()
    blockedUsersByCurrentUser.removeAll()
    
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    Database.database(url: GlobalDataStorage.reportDatabaseURL).reference().child("blacklists").child(currentUserID).child("bannedBy").removeAllObservers()
    Database.database(url: GlobalDataStorage.reportDatabaseURL).reference().child("blacklists").child(currentUserID).child("banned").removeAllObservers()
  }
  
  @objc fileprivate func getBlockedUsers() {

    DispatchQueue.global(qos: .default).async {
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }

      let currentUserBanned = Database.database(url: GlobalDataStorage.reportDatabaseURL).reference().child("blacklists").child(currentUserID)
      let bannedByCurrentUserReference = currentUserBanned.child("banned")
      let currentUserBannedReference = currentUserBanned.child("bannedBy")
      
      self.observeBannedUsers(reference: bannedByCurrentUserReference)
      self.observeCurrentUserBans(reference: currentUserBannedReference)
    }
  }
  
  fileprivate func observeBannedUsers(reference: DatabaseReference) {
    reference.observe(.value, with: { (snapshot) in
      self.blockedUsersByCurrentUser.removeAll()
      snapshot.children.forEach({ (child) in
        let key = (child as! DataSnapshot).key
        self.blockedUsersByCurrentUser.append(key)
      })
    })
  }
  
  fileprivate func observeCurrentUserBans(reference: DatabaseReference) {
    reference.observe(.value, with: { (snapshot) in
      self.blockedUsers.removeAll()
      snapshot.children.forEach({ (child) in
        let key = (child as! DataSnapshot).key
        self.blockedUsers.append(key)
      })
    })
  }

	func removeBannedUsers(users: [User]) -> [User] {
		var users = users
		globalDataStorage.blockedUsersByCurrentUser.forEach { (blockedUID) in
			guard let index = users.index(where: { (user) -> Bool in
				return user.id == blockedUID
			}) else { return }

			users.remove(at: index)
		}
		return users
	}
}

extension NSNotification.Name {
  static let localPhonesUpdated = NSNotification.Name(Bundle.main.bundleIdentifier! + ".localPhones")
  static let authenticationSucceeded = NSNotification.Name(Bundle.main.bundleIdentifier! + ".authenticationSucceeded")
  static let inputViewResigned = NSNotification.Name(Bundle.main.bundleIdentifier! + ".inputViewResigned")
  static let inputViewResponded = NSNotification.Name(Bundle.main.bundleIdentifier! + ".inputViewResponded")
	static let messageSent = NSNotification.Name(Bundle.main.bundleIdentifier! + ".messageSent")
}
