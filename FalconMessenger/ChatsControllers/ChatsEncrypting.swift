//
//  ChatsEncrypting.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 6/15/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ChatsEncrypting: NSObject {

  fileprivate let password = "%$^%&FTIK G#&^Fgxwuxgiit3c8lO!*(T@EGXkdjfbwdi23"
  fileprivate let pinnedDefaultConversation = "pndtmp"
  fileprivate let unpinnedDefaultConversation = "untmp"
  
  func updateDefaultsForConversations(pinnedConversations: [Conversation], conversations: [Conversation]) {
    let userDefaults = UserDefaults.standard
    
    let pinnedData = NSKeyedArchiver.archivedData(withRootObject: pinnedConversations)
    let unpinnedData = NSKeyedArchiver.archivedData(withRootObject: conversations)
    let encryptedPinnedData = RNCryptor.encrypt(data: pinnedData, withPassword: password)
    let encryptedUnpinnedData = RNCryptor.encrypt(data: unpinnedData, withPassword: password)
    
    userDefaults.set(encryptedPinnedData, forKey: pinnedDefaultConversation)
    userDefaults.set(encryptedUnpinnedData, forKey: unpinnedDefaultConversation)
    userDefaults.synchronize()
  }
  
  func setPinnedConversationsDefaultsToDataSource() -> [Conversation] {
    
    guard UserDefaults.standard.object(forKey: pinnedDefaultConversation) != nil else {
      return [Conversation]()
    }
      
    do {
      let encryptedData = UserDefaults.standard.object(forKey: pinnedDefaultConversation) as! Data
      let originalData = try RNCryptor.decrypt(data: encryptedData, withPassword: password)
      return NSKeyedUnarchiver.unarchiveObject(with: originalData) as! [Conversation]
    } catch {
      return [Conversation]()
    }
  }
  
  func setUnpinnedConversationsDefaultsToDataSource() -> [Conversation] {
  
    guard UserDefaults.standard.object(forKey: unpinnedDefaultConversation) != nil else {
      return [Conversation]()
    }
    do {
      let encryptedData = UserDefaults.standard.object(forKey: unpinnedDefaultConversation) as! Data
      let originalData = try RNCryptor.decrypt(data: encryptedData, withPassword: password)
      return NSKeyedUnarchiver.unarchiveObject(with: originalData) as! [Conversation]
    } catch {
      return [Conversation]()
    }
  }
}
