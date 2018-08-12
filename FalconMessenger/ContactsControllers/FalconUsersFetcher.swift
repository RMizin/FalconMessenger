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
import Contacts

protocol FalconUsersUpdatesDelegate: class {
  func falconUsers(shouldBeUpdatedTo users: [User])
}


class FalconUsersFetcher: NSObject {
  
  weak var delegate: FalconUsersUpdatesDelegate?
  
  fileprivate let phoneNumberKit = PhoneNumberKit()
  
  lazy var functions = Functions.functions()
  
  
  func loadAndSyncFalconUsers() {
    userDefaults.updateObject(for: userDefaults.contactsSyncronizationStatus, with: false)
    removeAllUsersObservers()
    requestFalconUsers()
  }
  
  fileprivate func prepareNumbers(from numbers: [String]) -> [String] {
    
    var preparedNumbers = [String]()
    
    for number in numbers {
      do {
        let countryCode = try phoneNumberKit.parse(number).countryCode
        let nationalNumber = try phoneNumberKit.parse(number).nationalNumber
        preparedNumbers.append("+" + String(countryCode) + String(nationalNumber))
      } catch {}
    }

    return preparedNumbers
  }
  
  fileprivate func requestFalconUsers() {
   
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    let numbers = prepareNumbers(from: globalDataStorage.localPhones)
    print("https reqest called")
    functions.httpsCallable("fetchContacts").call(["preparedNumbers": numbers]) { (result, error) in
      if let error = error as NSError? {
        if error.domain == FunctionsErrorDomain {
          let code = FunctionsErrorCode(rawValue: error.code)
          let message = error.localizedDescription
          let details = error.userInfo[FunctionsErrorDetailsKey]
          print("https error\(code, message, details)")
        }
        print("https error")
      }
      
      guard let response = result?.data as? [[String:AnyObject]] else { print("faliure"); return }
      var fetchedUsers = [User]()
      
      for object in response {
        let user = User(dictionary: object)
        if let uid = user.id, uid != currentUserID {
          fetchedUsers.append(user)
        }
      }
  
      userDefaults.updateObject(for: userDefaults.contactsSyncronizationStatus, with: true)
      self.syncronizeFalconUsers(with: fetchedUsers)
     
      print("Contacts fetching completed", fetchedUsers.count)
    }
  }
  
  fileprivate func syncronizeFalconUsers(with fetchedUsers: [User]) {
    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
    let databaseReference = Database.database().reference().child("users").child(currentUserID)
    let falconUserIDs = fetchedUsers.map({$0.id ?? "" })
    
    var falconUserIDsDictionary = [AnyHashable: Any]()
    
    falconUserIDs.forEach { (item) in
      falconUserIDsDictionary[item] = item
    }
    
    /*databaseReference.updateChildValues(["falconUsers" : falconUserIDsDictionary]) { (_, _) in
      self.loadFalconUsers()
    }*/

    databaseReference.child("falconUsers").updateChildValues(falconUserIDsDictionary) { (_, _) in
      self.loadFalconUsers()
    }
  }

  fileprivate var falconUsers = [User]()
  fileprivate var falconUsersReference: DatabaseReference!
  fileprivate var falconUsersHandle = [(userID: String, handle: DatabaseHandle)]()
  fileprivate let falconUsersLoadingGroup = DispatchGroup()
  fileprivate var isFalconUsersLoadingGroupFinished = false
  
  func loadFalconUsers() {
    let status = CNContactStore.authorizationStatus(for: .contacts)
    if status == .denied || status == .restricted { print("returning from contacts status"); return }
    removeAllUsersObservers()
    guard let currentUserID = Auth.auth().currentUser?.uid else { print("returning frou current uid"); return }
    let databaseReference = Database.database().reference().child("users").child(currentUserID)
    databaseReference.keepSynced(true)
    databaseReference.observeSingleEvent(of: .value) { (snapshot) in
      guard snapshot.exists() else {
        self.isFalconUsersLoadingGroupFinished = true
        self.updateDataSource(newUsers: [User]())
        return
      }
      guard snapshot.childSnapshot(forPath: "falconUsers").exists() else {
        self.isFalconUsersLoadingGroupFinished = true
        self.updateDataSource(newUsers: [User]())
        return
      }
    
      guard var dictionary = snapshot.childSnapshot(forPath: "falconUsers").value as? [String: String] else { return }
      var falconUsersIDs: [String] = Array(dictionary.values)

      if let index = falconUsersIDs.index(of: currentUserID) {
        falconUsersIDs.remove(at: index)
      }
      
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
      let element = (userID: userID, handle: handle)
      falconUsersHandle.insert(element, at: 0)
      falconUsersReference = Database.database().reference().child("users").child(element.userID)
      falconUsersHandle[0].handle = falconUsersReference.observe( .value, with: { (snapshot) in
        
        guard var dictionary = snapshot.value as? [String: AnyObject] else {self.updateDataSource(newUsers: nil); return }
        dictionary.updateValue(userID as AnyObject, forKey: "id")
        let falconUser = User(dictionary: dictionary)
        
        if let thumbnail = falconUser.thumbnailPhotoURL, let url = URL(string: thumbnail) {
          SDWebImagePrefetcher.shared.prefetchURLs([url])
        }
    
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

  fileprivate func removeAllUsersObservers() {
    falconUsers.removeAll()
    isFalconUsersLoadingGroupFinished = false
    
    guard falconUsersReference != nil else { return }
    for element in falconUsersHandle {
      falconUsersReference = Database.database().reference().child("users").child(element.userID)
      falconUsersReference.removeObserver(withHandle: element.handle)
      guard let index = falconUsersHandle.index(where: { (element1) -> Bool in
        return element.userID == element1.userID
      }) else { return }
      guard falconUsersHandle.indices.contains(index) else { return }
      falconUsersHandle.remove(at: index)
    }
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
