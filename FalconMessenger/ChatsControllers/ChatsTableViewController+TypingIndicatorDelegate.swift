//
//  ChatsTableViewController+TypingIndicatorDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 4/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

extension ChatsTableViewController: TypingIndicatorDelegate {
  
  func typingIndicator(isActive: Bool, for chatID: String) {

		print("xxx typing indicator CHANGED TO \(isActive)")

		realmManager.realm.beginWrite()
		realmManager.realm.objects(Conversation.self).filter("chatID = %@", chatID).first?.isTyping.value = isActive
		try! realmManager.realm.commitWrite()


//    update(realmUnpinnedConversations, at: chatID, with: isActive) { (isCompleted, conversations, row) in
//      guard isCompleted, let row = row else { return }
//			 realmManager.realm.beginWrite()
//			realmUnpinnedConversations[row].isTyping.value = isActive
//				try! realmManager.realm.commitWrite()
//    //  filtededConversations = conversations
//	 // reloadCell(at: row, section: 1)
//    }
//
//    update(realmPinnedConversations, at: chatID, with: isActive) { (isCompleted, conversations, row) in
//      guard isCompleted, let row = row else { return }
//		//	realmPinnedConversations = conversations
//			 realmManager.realm.beginWrite()
//				realmPinnedConversations[row].isTyping.value = isActive
//				try! realmManager.realm.commitWrite()
//     // filteredPinnedConversations = conversations
//    //  reloadCell(at: row, section: 0)
//    }

//    update(conversations, at: chatID, with: isActive) { (isCompleted, updatedConversations, row) in
//      guard isCompleted else { return }
//      conversations = updatedConversations
//    }
//
//    update(pinnedConversations, at: chatID, with: isActive) { (isCompleted, conversations, row) in
//      guard isCompleted else { return }
//      pinnedConversations = conversations
//    }
  }
  
  typealias typingUpdateCompletionHandler = (_ isCompleted: Bool, _ updatedConversations: Results<Conversation>, _ row: Int?) -> Void
  
  func update(_ conversations: Results<Conversation>, at chatID: String, with typingStatus: Bool , completion: typingUpdateCompletionHandler ) {
    guard let index = conversations.index(where: { (conversation) -> Bool in
      return conversation.chatID == chatID
    }) else {
      completion(false, conversations, nil)
      return
    }

//r		realmManager.update(conversation: <#T##Conversation#>)
//		realmManager.realm.beginWrite()
//    conversations[index].isTyping = typingStatus
//	//	chatsTableViewRealmObserver.update(type: .reloadRow, conversation: conversations[index])
//		try! realmManager.realm.commitWrite()

    completion(true, conversations, index)
  }
  
  func reloadCell(at row: Int, section: Int) {
    let indexPath = IndexPath(row: row, section: section)
    UIView.performWithoutAnimation {
      tableView.beginUpdates()
      tableView.reloadRows(at: [indexPath], with: .none)
      tableView.endUpdates()
    }
  }
}
