//
//  FalconContactsEncrypting.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 6/14/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class FalconContactsEncrypting: NSObject {
  
 let usersDataDefaultsKey = "ewtmp"
 fileprivate let password = "FdKU&^Twef2w78V8efwRVb bi78TB&t78vr6VB9hjjTgik"
  
  func updateDefaultsForUsers(for users: [User]) {
    let userDefaults = UserDefaults.standard
    let usersData = NSKeyedArchiver.archivedData(withRootObject: users)
    let encryptedUsersData = RNCryptor.encrypt(data: usersData, withPassword: password)
    
    userDefaults.set(encryptedUsersData, forKey: usersDataDefaultsKey)
    userDefaults.synchronize()
  }
  
  func setUsersDefaultsToDataSource() -> [User] {
    guard UserDefaults.standard.object(forKey: self.usersDataDefaultsKey) != nil else { return [User]() }
    do {
      guard let encryptedData = UserDefaults.standard.object(forKey: self.usersDataDefaultsKey) as? Data else { return [User]() }
      let originalData = try RNCryptor.decrypt(data: encryptedData, withPassword: password)
      return NSKeyedUnarchiver.unarchiveObject(with: originalData) as! [User]
    } catch { return [User]() }
  }
}
