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
  
  func fetchFalconUsers() {
    clearObserversAndUsersIfNeeded()
    fetchAsynchronously()
  }
  
  fileprivate func fetchAsynchronously() {
    var preparedNumber = String()
    
    for number in localPhones {
      do {
        let countryCode = try phoneNumberKit.parse(number).countryCode
        let nationalNumber = try phoneNumberKit.parse(number).nationalNumber
        preparedNumber = "+" + String(countryCode) + String(nationalNumber)
      } catch {}
      
      fetchAndObserveFalconUser(for: preparedNumber)
    }
  }
  
  fileprivate func fetchAndObserveFalconUser(for preparedNumber: String) {
    
    userReference = Database.database().reference().child("users")
    userQuery = userReference.queryOrdered(byChild: "phoneNumber").queryEqual(toValue: preparedNumber)
    let databaseHandle = DatabaseHandle()
    userHandle.insert(databaseHandle, at: 0 )
   
    userHandle[0] = userQuery.observe(.value, with: { (snapshot) in
    
      guard snapshot.exists(), let userData = (snapshot.value as? [String: AnyObject])?.first,
            let currentUserID = Auth.auth().currentUser?.uid else { return }
      
      let userID = userData.key
      guard var userDictionary = userData.value as? [String: AnyObject], userID != currentUserID else { return }
      userDictionary.updateValue(userID as AnyObject, forKey: "id")
      let fetchedUser = User(dictionary: userDictionary)
      
      if let index = self.users.index(where: { (user) -> Bool in
        return user.id == fetchedUser.id
      }) {
        self.users[index] = fetchedUser
      } else {
        self.users.append(fetchedUser)
      }
      self.users = self.sortUsers(users: self.users)
      self.users = self.rearrangeUsers(users: self.users)
      self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
    })  { (error) in
      print("query error", error.localizedDescription)
    }
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
