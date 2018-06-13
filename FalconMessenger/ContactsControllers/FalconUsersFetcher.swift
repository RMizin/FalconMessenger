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
  fileprivate var isGroupFinished = false

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
      self.isGroupFinished = true
      self.configureUsersArray()
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
      DispatchQueue.global(qos: .background).async {

        self.userReference = Database.database().reference().child("users")
        self.userQuery = self.userReference.queryOrdered(byChild: "phoneNumber").queryEqual(toValue: preparedNumber)
        let databaseHandle = DatabaseHandle()
        self.userHandle.insert(databaseHandle, at: 0 )
     
        self.userHandle[0] = self.userQuery.observe(.value, with: { (snapshot) in
      
        guard snapshot.exists(), let userData = (snapshot.value as? [String: AnyObject])?.first,
              let currentUserID = Auth.auth().currentUser?.uid else { if !asynchronously { self.group.leave() }; return }
        
        let userID = userData.key
        guard var userDictionary = userData.value as? [String: AnyObject], userID != currentUserID else { if !asynchronously { self.group.leave() }; return }
        userDictionary.updateValue(userID as AnyObject, forKey: "id")
        let fetchedUser = User(dictionary: userDictionary)
        if UserDefaults.standard.object(forKey: "users") != nil {
          self.users = NSKeyedUnarchiver.unarchiveObject(with: UserDefaults.standard.object(forKey: "users") as! Data) as! [User]
        }
        
        if let index = self.users.index(where: { (user) -> Bool in
          return user.id == fetchedUser.id
        }) {
          self.users[index] = fetchedUser
        } else {
          self.users.append(fetchedUser)
        }
        
        if asynchronously {
          self.configureUsersArray()
          self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
        }
        
        if !asynchronously && !self.isGroupFinished == false {
          self.group.leave()
          print("leaving group")
        } else if !asynchronously && !self.isGroupFinished == true {
          self.configureUsersArray()
          self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
        }
        
      })  { (error) in
        print("query error", error.localizedDescription)
      }
    }
  }
  
  func configureUsersArray() {
    self.users = self.sortUsers(users: self.users)
    self.users = self.rearrangeUsers(users: self.users)
    
    let userDefaults = UserDefaults.standard
    userDefaults.set(NSKeyedArchiver.archivedData(withRootObject: self.users), forKey: "users")
    userDefaults.synchronize()
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
