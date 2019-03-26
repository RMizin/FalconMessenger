//
//  FalconUsersFetcher.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/10/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import PhoneNumberKit
import SDWebImage

protocol FalconUsersUpdatesDelegate: class {
  func falconUsers(shouldBeUpdatedTo users: [User])
}

public var shouldReFetchFalconUsers: Bool = false

class FalconUsersFetcher: NSObject {
  
  let phoneNumberKit = PhoneNumberKit()
  var users = [User]()
  
  weak var delegate: FalconUsersUpdatesDelegate?
  
  var userReference: DatabaseReference!
  var userQuery: DatabaseQuery!
  var userHandle = [DatabaseHandle]()
  var group = DispatchGroup()

  
  fileprivate func clearObserversAndUsersIfNeeded() {
    self.users.removeAll()
    if userReference != nil {
      for handle in userHandle {
        userReference.removeObserver(withHandle: handle)
      }
    }
  }
  
  func fetchFalconUsers(asynchronously: Bool) {
    clearObserversAndUsersIfNeeded()
    
    if asynchronously {
      print("fetching async")
      fetchAsynchronously()
    } else {
      print("fetching sync")
      fetchSynchronously()
    }
  }
  
  fileprivate func fetchSynchronously() {
    
    var preparedNumbers = [String]()
    
    for number in localPhones {
      do {
        let countryCode = try phoneNumberKit.parse(number).countryCode
        let nationalNumber = try phoneNumberKit.parse(number).nationalNumber
        preparedNumbers.append("+" + String(countryCode) + String(nationalNumber))
        group.enter()
        print("entering group")
      } catch {}
    }
    
    group.notify(queue: DispatchQueue.main, execute: {
      print("COntacts load finished Falcon")
      self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
    })
    
    for preparedNumber in preparedNumbers {
      fetchAndObserveFalconUser(for: preparedNumber, asynchronously: false)
    }
  }
  
  fileprivate func fetchAsynchronously() {
    var preparedNumber = String()
    
    
    for number in localPhones {
      do {
        let countryCode = try phoneNumberKit.parse(number).countryCode
        let nationalNumber = try phoneNumberKit.parse(number).nationalNumber
        preparedNumber = "+" + String(countryCode) + String(nationalNumber)
      } catch {}
      
      fetchAndObserveFalconUser(for: preparedNumber, asynchronously: true)
    }
  }
  
  fileprivate func fetchAndObserveFalconUser(for preparedNumber: String, asynchronously: Bool) {
    
    userReference = Database.database().reference().child("users")
    userQuery = userReference.queryOrdered(byChild: "phoneNumber")
    let databaseHandle = DatabaseHandle()
    userHandle.insert(databaseHandle, at: 0 )
    userHandle[0] = userQuery.queryEqual(toValue: preparedNumber).observe(.value, with: { (snapshot) in
      
      if snapshot.exists() {
        guard let children = snapshot.children.allObjects as? [DataSnapshot] else { return }
        for child in children {
          guard var dictionary = child.value as? [String: AnyObject] else { return }
          dictionary.updateValue(child.key as AnyObject, forKey: "id")
          if let thumbnailURLString = User(dictionary: dictionary).thumbnailPhotoURL, let thumbnailURL = URL(string: thumbnailURLString) {
            SDWebImagePrefetcher.shared.prefetchURLs([thumbnailURL])
          }
					if let index = self.users.firstIndex(where: { (user) -> Bool in
            return user.id == User(dictionary: dictionary).id
          }) {
            self.users[index] = User(dictionary: dictionary)
          } else {
            self.users.append(User(dictionary: dictionary))
          }
          
          self.users = self.sortUsers(users: self.users)
          self.users = self.rearrangeUsers(users: self.users)
          
					if let index = self.users.firstIndex(where: { (user) -> Bool in
            return user.id == Auth.auth().currentUser?.uid
          }) {
            self.users.remove(at: index)
          }
        }
        
        if asynchronously {
          self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
        }
      }
      
      if !asynchronously {
        self.group.leave()
        print("leaving group")
      }
    
    }, withCancel: { (error) in
      print("error")
      //search error
    })
  }
  
  func rearrangeUsers(users: [User]) -> [User] { /* Moves Online users to the top  */
    var users = users
    guard users.count - 1 > 0 else { return users }
    for index in 0...users.count - 1 {
      if users[index].onlineStatus as? String == statusOnline {
        users = rearrange(array: users, fromIndex: index, toIndex: 0)
      }
    }
    
    return users
  }
  
  func sortUsers(users: [User]) -> [User] { /* Sort users by last online date  */
    return users.sorted(by: { (user1, user2) -> Bool in
      if let firstUserOnlineStatus = user1.onlineStatus as? TimeInterval , let secondUserOnlineStatus = user2.onlineStatus as? TimeInterval {
        return (firstUserOnlineStatus, user1.phoneNumber ?? "") > ( secondUserOnlineStatus, user2.phoneNumber ?? "")
      } else {
        return ( user1.phoneNumber ?? "") > (user2.phoneNumber ?? "") // sort
      }
    })
  }
}
