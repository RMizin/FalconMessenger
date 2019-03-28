//
//  BlacklistManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 2/24/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import Firebase

let blacklistManager = BlacklistManager()

final class BlacklistManager: NSObject {

	let initialize = true

	fileprivate var blockedUsers = [String]()
	fileprivate(set) var blockedUsersByCurrentUser = [String]()

	override init() {
		super.init()
		getBlockedUsers()
		NotificationCenter.default.addObserver(self, selector: #selector(getBlockedUsers), name: .authenticationSucceeded, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(removeBanObservers), name: NSNotification.Name(rawValue: "clearUserData"), object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc fileprivate func getBlockedUsers() {
		DispatchQueue.global(qos: .userInitiated).async {
			guard let currentUserID = Auth.auth().currentUser?.uid else { return }
			let currentUserBanned = Database.database(url: globalVariables.reportDatabaseURL).reference().child("blacklists").child(currentUserID)
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

	@objc fileprivate func removeBanObservers() {
		blockedUsers.removeAll()
		blockedUsersByCurrentUser.removeAll()
		guard let currentUserID = Auth.auth().currentUser?.uid else { return }
		Database.database(url: globalVariables.reportDatabaseURL).reference().child("blacklists").child(currentUserID).child("bannedBy").removeAllObservers()
		Database.database(url: globalVariables.reportDatabaseURL).reference().child("blacklists").child(currentUserID).child("banned").removeAllObservers()
	}

	func removeBannedUsers(users: [User]) -> [User] {
		var users = users
		blockedUsersByCurrentUser.forEach { (blockedUID) in
			guard let index = users.firstIndex(where: { (user) -> Bool in
				return user.id == blockedUID
			}) else { return }
			users.remove(at: index)
		}
		return users
	}
}
