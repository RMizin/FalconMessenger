//
//  UserExistenceChecker.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 12/27/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

protocol UserExistenceDelegate: class {
	func user(isAlreadyExists: Bool, name: String?, bio: String?, image: UIImage?)
}

final class UserExistenceChecker: NSObject {

	fileprivate var isNameExists: Bool?
	fileprivate var isBioExists: Bool?
	fileprivate var isPhotoExists: Bool?

	fileprivate var name: String?
	fileprivate var bio: String?
	fileprivate var photo: UIImage?
	
	weak var delegate: UserExistenceDelegate?

	fileprivate func checkUserData() {

		guard let isNameExistsVal = isNameExists, isBioExists != nil, isPhotoExists != nil else { return }
		delegate?.user(isAlreadyExists: isNameExistsVal, name: name , bio: bio, image: photo)
	}

	func checkIfUserDataExists() {
		guard let currentUserID = Auth.auth().currentUser?.uid else { return }
		let nameReference = Database.database().reference().child("users").child(currentUserID).child("name")
		nameReference.observeSingleEvent(of: .value, with: { (snapshot) in
			if snapshot.exists() {
				self.name = snapshot.value as? String
				self.isNameExists = true
			} else {
				self.isNameExists = false
			}

			self.checkUserData()
		})

		let bioReference = Database.database().reference().child("users").child(currentUserID).child("bio")
		bioReference.observeSingleEvent(of: .value, with: { (snapshot) in
			if snapshot.exists() {
				self.bio = snapshot.value as? String
				self.isBioExists = true
			} else {
				self.isBioExists = false
			}
			self.checkUserData()
		})

		let photoReference = Database.database().reference().child("users").child(currentUserID).child("photoURL")
		photoReference.observeSingleEvent(of: .value, with: { (snapshot) in

			if snapshot.exists() {
				guard let urlString = snapshot.value as? String else {
					return
				}

				SDWebImageDownloader.shared.downloadImage(with: URL(string: urlString), options: [.scaleDownLargeImages, .continueInBackground], progress: nil, completed: { (image, _, _, _) in
					self.isPhotoExists = true
					self.photo = image
					self.checkUserData()
				})
			} else {
				let photosReference = Database.database().reference().child("users").child(currentUserID)
				photosReference.updateChildValues(["photoURL": "", "thumbnailPhotoURL": ""], withCompletionBlock: { (_, _) in
					self.isPhotoExists = false
					self.checkUserData()
				})
			}
		})
	}
}
