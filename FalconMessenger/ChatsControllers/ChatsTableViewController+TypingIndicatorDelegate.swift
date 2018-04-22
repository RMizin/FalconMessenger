//
//  ChatsTableViewController+TypingIndicatorDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 4/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension ChatsTableViewController: TypingIndicatorDelegate {
  
  func typingIndicator(isActive: Bool, for chatID: String) {
    
    update(filtededConversations, at: chatID, with: isActive) { (isCompleted, conversations, row) in
      guard isCompleted, let row = row else { return }
      filtededConversations = conversations
      reloadCell(at: row, section: 1)
    }
    
    update(filteredPinnedConversations, at: chatID, with: isActive) { (isCompleted, conversations, row) in
      guard isCompleted, let row = row else { return }
      filteredPinnedConversations = conversations
      reloadCell(at: row, section: 0)
    }
    
    update(conversations, at: chatID, with: isActive) { (isCompleted, updatedConversations, row) in
      guard isCompleted else { return }
      conversations = updatedConversations
    }
    
    update(pinnedConversations, at: chatID, with: isActive) { (isCompleted, conversations, row) in
      guard isCompleted else { return }
      pinnedConversations = conversations
    }
    
    print("\ntyping indicator if active: \(isActive), for conversation: \(chatID)\n")
  }
  
  typealias typingUpdateCompletionHandler = (_ isCompleted: Bool, _ updatedConversations: [Conversation], _ row: Int?) -> Void
  
  func update(_ conversations: [Conversation], at chatID: String, with typingStatus: Bool , completion: typingUpdateCompletionHandler ) {
    guard let index = conversations.index(where: { (conversation) -> Bool in
      return conversation.chatID == chatID
    }) else {
      completion(false, conversations, nil)
      return
    }
    conversations[index].isTyping = typingStatus
    completion(true, conversations, index)
  }
  
  func reloadCell(at row: Int, section: Int) {
    let indexPath = IndexPath(row: row, section: section)
    self.tableView.beginUpdates()
    self.tableView.reloadRows(at: [indexPath], with: .none)
    self.tableView.endUpdates()
  }
}
