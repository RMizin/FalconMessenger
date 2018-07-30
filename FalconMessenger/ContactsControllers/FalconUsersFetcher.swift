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

func setContactsSyncronizationStatus(status: Bool) {
  UserDefaults.standard.set(status, forKey: "SyncronizationStatus")
  UserDefaults.standard.synchronize()
}


class FalconUsersFetcher: NSObject {
  
  weak var delegate: FalconUsersUpdatesDelegate?
  
  fileprivate let phoneNumberKit = PhoneNumberKit()
  
  fileprivate var users = [User]()
  fileprivate var userReference: DatabaseReference!
  fileprivate var userQuery: DatabaseQuery!
  fileprivate var userHandle = [DatabaseHandle]()
  fileprivate var loadAndSyncFalconUsersGroup = DispatchGroup()
  fileprivate var isLoadAndSyncGroupFinished = false

  fileprivate func clearObserversAndUsersIfNeeded() {
    users.removeAll()
    guard userReference != nil else { return }
    for handle in userHandle {
      userReference.removeObserver(withHandle: handle)
    }
  }
  
  func loadAndSyncFalconUsers() {
    clearObserversAndUsersIfNeeded()
    clearFalconUsersRefObservers()
    fetchSynchronously()
  }
  
  fileprivate func fetchSynchronously() {
    
    var preparedNumbers = [String]()
    
    for number in localPhones {
      do {
        let countryCode = try phoneNumberKit.parse(number).countryCode
        let nationalNumber = try phoneNumberKit.parse(number).nationalNumber
        preparedNumbers.append("+" + String(countryCode) + String(nationalNumber))
        loadAndSyncFalconUsersGroup.enter()
      } catch {}
    }
    
    loadAndSyncFalconUsersGroup.notify(queue: .main, execute: {
      self.isLoadAndSyncGroupFinished = true
      self.updateDataSourceAfterSync(newUsers: self.users)
    })
    
    for preparedNumber in preparedNumbers {
      fetchAndObserveFalconUser(for: preparedNumber)
    }
  }
  
  fileprivate func fetchAndObserveFalconUser(for preparedNumber: String) {
    userReference = Database.database().reference().child("users")
    userQuery = userReference.queryOrdered(byChild: "phoneNumber").queryEqual(toValue: preparedNumber)
    let databaseHandle = DatabaseHandle()
    userHandle.insert(databaseHandle, at: 0)
    
    userHandle[0] = userQuery.observe( .value, with: { (snapshot) in
    
      guard snapshot.exists(), let userData = (snapshot.value as? [String: AnyObject])?.first, let currentUserID = Auth.auth().currentUser?.uid else {
        self.updateDataSourceAfterSync(newUsers: nil)
        return
      }
      
      let userID = userData.key
      
      guard var userDictionary = userData.value as? [String: AnyObject], userID != currentUserID else {
        self.updateDataSourceAfterSync(newUsers: nil)
        return
      }
      
      userDictionary.updateValue(userID as AnyObject, forKey: "id")
      let fetchedUser = User(dictionary: userDictionary)

      if let index = self.users.index(where: { (user) -> Bool in
        return user.id == fetchedUser.id
      }) {
        self.users[index] = fetchedUser
      } else {
        self.users.append(fetchedUser)
      }

      self.updateDataSourceAfterSync(newUsers: self.users)
    })
  }
  
  fileprivate func updateDataSourceAfterSync(newUsers: [User]?) {
    guard isLoadAndSyncGroupFinished else { loadAndSyncFalconUsersGroup.leave(); return }
    guard var newUsers = newUsers else { return }
    syncronizeFalconUsers(with: newUsers)
    newUsers = sortUsers(users: newUsers)
    newUsers = rearrangeUsers(users: newUsers)
    delegate?.falconUsers(shouldBeUpdatedTo: newUsers)
    setContactsSyncronizationStatus(status: true)
  }
  
  fileprivate func syncronizeFalconUsers(with fetchedUsers: [User]) {
    guard let currentUserID = Auth.auth().currentUser?.uid, fetchedUsers.count > 0 else { return }
    let databaseReference = Database.database().reference().child("users").child(currentUserID)//.child("falconUsers")
    let falconUserIDs = fetchedUsers.map({$0.id ?? ""})
    databaseReference.updateChildValues(["falconUsers" : falconUserIDs])
  }

  fileprivate var falconUsers = [User]()
  fileprivate var falconUsersReference: DatabaseReference!
  fileprivate var falconUsersHandle = [DatabaseHandle]()
  fileprivate let falconUsersLoadingGroup = DispatchGroup()
  fileprivate var isFalconUsersLoadingGroupFinished = false
  
  fileprivate func clearFalconUsersRefObservers() {
    falconUsers.removeAll()
    guard falconUsersReference != nil else { return }
    for handle in falconUsersHandle {
      falconUsersReference.removeObserver(withHandle: handle)
    }
  }
  
  func loadFalconUsers() {
    clearFalconUsersRefObservers()
    clearObserversAndUsersIfNeeded()
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    let databaseReference = Database.database().reference().child("users").child(currentUserID)//.child("falconUsers")
    databaseReference.observeSingleEvent(of: .value) { (snapshot) in
      guard snapshot.exists() else { return }
      guard snapshot.childSnapshot(forPath: "falconUsers").exists() else { return }
      let falconUsersIDs = snapshot.childSnapshot(forPath: "falconUsers").value as! [String]
      self.loadData(for: falconUsersIDs)
    }
  }
  
  fileprivate func loadData(for userIDs: [String]) {
    
    userIDs.forEach { (_) in falconUsersLoadingGroup.enter() }
    
    falconUsersLoadingGroup.notify(queue: .main, execute: {
      self.isFalconUsersLoadingGroupFinished = true
   
      self.updateDataSource(newUsers: self.falconUsers)
    })
    
    userIDs.forEach { (userID) in
      let handle = DatabaseHandle()
      falconUsersHandle.insert(handle, at: 0)
      falconUsersReference = Database.database().reference().child("users").child(userID)
      falconUsersHandle[0] = falconUsersReference.observe( .value, with: { (snapshot) in
        
        guard var dictionary = snapshot.value as? [String: AnyObject] else {self.updateDataSource(newUsers: nil); return }
        dictionary.updateValue(userID as AnyObject, forKey: "id")
        let falconUser = User(dictionary: dictionary)
        
        if let index = self.falconUsers.index(where: { (user) -> Bool in
          return user.id == falconUser.id
        }) {
          self.falconUsers[index] = falconUser
        } else {
          self.falconUsers.append(falconUser)
        }
        self.updateDataSource(newUsers: self.falconUsers)
      })
    }
  }

  fileprivate func updateDataSource(newUsers: [User]?) {
    guard isFalconUsersLoadingGroupFinished == true else { falconUsersLoadingGroup.leave(); return }
    guard var newUsers = newUsers else { return }
 
    newUsers = self.sortUsers(users: newUsers)
    newUsers = self.rearrangeUsers(users: newUsers)
    self.delegate?.falconUsers(shouldBeUpdatedTo: newUsers)
  }

  fileprivate func rearrangeUsers(users: [User]) -> [User] { /* Moves Online users to the top  */
    var users = users
    guard users.count - 1 > 0 else { return users }
    
    for index in 0...users.count - 1 {
      if users[index].onlineStatus as? String == statusOnline {
        users = rearrange(array: users, fromIndex: index, toIndex: 0)
      }
    }
    return users
  }
  
  fileprivate func sortUsers(users: [User]) -> [User] { /* Sort users by last online date  */
    let sortedUsers = users.sorted(by: { (user1, user2) -> Bool in
      let timestamp1 = user1.onlineStatus as? TimeInterval
      let timestamp2 = user2.onlineStatus as? TimeInterval

      return timestamp1 ?? 0.0  > timestamp2 ?? 0.0
    })
    return sortedUsers
  }
}
