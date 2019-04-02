//
//  UserProfileDataDatabaseUpdater.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 4/4/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

final class UserProfileDataDatabaseUpdater: NSObject {

  typealias UpdateUserProfileCompletionHandler = (_ success: Bool) -> Void
  func updateUserProfile(with image: UIImage, completion: @escaping UpdateUserProfileCompletionHandler) {
    
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    let userReference = Database.database().reference().child("users").child(currentUserID)

    let thumbnailImage = createImageThumbnail(image)
    var images = [(image: UIImage, quality: CGFloat, key: String)]()
    images.append((image: image, quality: 0.5, key: "photoURL"))
    images.append((image: thumbnailImage, quality: 1, key: "thumbnailPhotoURL"))

    let photoUpdatingGroup = DispatchGroup()
    for _ in images { photoUpdatingGroup.enter() }

    photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
      completion(true)
    })
    
    for imageElement in images {
      uploadAvatarForUserToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
        userReference.updateChildValues([imageElement.key: url], withCompletionBlock: { (_, _) in
          photoUpdatingGroup.leave()
        })
      }
    }
  }

  typealias DeleteCurrentPhotoCompletionHandler = (_ success: Bool) -> Void
  func deleteCurrentPhoto(completion: @escaping DeleteCurrentPhotoCompletionHandler) {

    guard currentReachabilityStatus != .notReachable, let currentUser = Auth.auth().currentUser?.uid else {
      completion(false)
      return
    }

    let userReference = Database.database().reference().child("users").child(currentUser)
    userReference.observeSingleEvent(of: .value, with: { (snapshot) in

      guard let userData = snapshot.value as? [String: AnyObject] else { completion(false); return }
      guard let photoURL = userData["photoURL"] as? String,
        let thumbnailPhotoURL = userData["thumbnailPhotoURL"] as? String,
        photoURL != "",
        thumbnailPhotoURL != "" else {
        completion(true)
        return
      }

      let storage = Storage.storage()
      let photoURLStorageReference = storage.reference(forURL: photoURL)
      let thumbnailPhotoURLStorageReference = storage.reference(forURL: thumbnailPhotoURL)

      let imageRemovingGroup = DispatchGroup()
      imageRemovingGroup.enter()
      imageRemovingGroup.enter()

      imageRemovingGroup.notify(queue: DispatchQueue.main, execute: {
        completion(true)
      })

      photoURLStorageReference.delete(completion: { (_) in
        userReference.updateChildValues(["photoURL": ""], withCompletionBlock: { (_, _) in
          imageRemovingGroup.leave()
        })
      })
      
      thumbnailPhotoURLStorageReference.delete(completion: { (_) in
        userReference.updateChildValues(["thumbnailPhotoURL": ""], withCompletionBlock: { (_, _) in
          imageRemovingGroup.leave()
        })
      })
      
    }, withCancel: { (_) in
      completion(false)
    })
  }
}
