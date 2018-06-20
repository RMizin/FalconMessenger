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

protocol FalconUsersUpdatesDelegate: class {
  func falconUsers(shouldBeUpdatedTo users: [User])
}

public var shouldReFetchFalconUsers: Bool = false


class FalconUsersFetcher: NSObject {
  
  let phoneNumberKit = PhoneNumberKit()
  let falconContactsEncryptor = FalconContactsEncrypting()
  var users = [User]()
  weak var delegate: FalconUsersUpdatesDelegate?
  var userReference: DatabaseReference!
  var userQuery: DatabaseQuery!
  var userHandle = [DatabaseHandle]()
  var group = DispatchGroup()

  fileprivate var isGroupFinished = false

  fileprivate func clearObserversAndUsersIfNeeded() {
    users.removeAll()
    guard userReference != nil else { return }
    for handle in userHandle {
      userReference.removeObserver(withHandle: handle)
    }
  }
  
  func fetchFalconUsers(asynchronously: Bool) {
    clearObserversAndUsersIfNeeded()
    if asynchronously {
      fetchAsynchronously()
    } else {
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
      } catch {}
    }
    
    group.notify(queue: .main, execute: {
      self.isGroupFinished = true
      self.sortAndRearrangeUsers()
      self.falconContactsEncryptor.updateDefaultsForUsers(for: self.users)
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
      userQuery = userReference.queryOrdered(byChild: "phoneNumber").queryEqual(toValue: preparedNumber)
      let databaseHandle = DatabaseHandle()
      userHandle.insert(databaseHandle, at: 0)
   
      userHandle[0] = userQuery.observe(.value, with: { (snapshot) in
    
      guard snapshot.exists(), let userData = (snapshot.value as? [String: AnyObject])?.first,
        let currentUserID = Auth.auth().currentUser?.uid else { self.leaveGroupIfNeeded(asynchronously); return }
      
      let userID = userData.key
      guard var userDictionary = userData.value as? [String: AnyObject], userID != currentUserID else { self.leaveGroupIfNeeded(asynchronously); return }
      userDictionary.updateValue(userID as AnyObject, forKey: "id")
      let fetchedUser = User(dictionary: userDictionary)

      if let index = self.users.index(where: { (user) -> Bool in
        return user.id == fetchedUser.id
      }) {
        self.users[index] = fetchedUser
      } else {
        self.users.append(fetchedUser)
      }
      
      if asynchronously {
        self.sortAndRearrangeUsers()
        self.falconContactsEncryptor.updateDefaultsForUsers(for: self.users)
        self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
      }
      
      if !asynchronously && self.isGroupFinished == false {
        self.group.leave()
      } else if !asynchronously && self.isGroupFinished == true {
        self.sortAndRearrangeUsers()
        self.falconContactsEncryptor.updateDefaultsForUsers(for: self.users)
        self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
      }
    })  { (error) in
      print("query error", error.localizedDescription)
    }
  }
  
  fileprivate func leaveGroupIfNeeded(_ asynchronously: Bool) {
    if !asynchronously && isGroupFinished == false {
      group.leave()
    }
  }
  
  fileprivate func sortAndRearrangeUsers () {
    users = sortUsers(users: users)
    users = rearrangeUsers(users: users)
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
    let sortedUsers = users.sorted(by: { (user1, user2) -> Bool in
      guard let timestamp1 = user1.onlineStatus as? TimeInterval , let timestamp2 = user2.onlineStatus as? TimeInterval else {
        guard let timestamp3 = user1.onlineStatus as? String , let timestamp4 = user2.onlineStatus as? String else {
          return (user1.name ?? "", user1.phoneNumber ?? "") > (user2.name ?? "", user2.phoneNumber ?? "")
        }
        return (timestamp3, user1.name ?? "") > (timestamp4, user2.name ?? "")
      }
      return (timestamp1, user1.name ?? "" ) > (timestamp2, user2.name ?? "")
    })
    return sortedUsers
  }
}
