//
//  ChatLogViewController+ChatHistoryFetcherDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/28/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import RealmSwift

extension ChatLogViewController: ChatLogHistoryDelegate {
  
  func chatLogHistory(isEmpty: Bool) {
    refreshControl.endRefreshing()
  }

  func chatLogHistory(updated messages: [Message]) {
    globalDataStorage.contentSizeWhenInsertingToTop = collectionView.contentSize
    globalDataStorage.isInsertingCellsToTop = true
    refreshControl.endRefreshing()

		let realm = try! Realm()

		autoreleasepool {
			realm.beginWrite()
			for message in messages {
				if realm.object(ofType: Message.self, forPrimaryKey: message.messageUID) == nil {
					realm.create(Message.self, value: message, update: true)
				}
			}
			try! realm.commitWrite()
		}

//		realm.beginWrite()
//		messagesFetcher?.configureTails(for: conversation!.messages, isGroupChat: nil)
//		try! realm.commitWrite()
//let mmm = conversation!.messages.sorted(byKeyPath: "timestamp", ascending: true)
		//conversation.MESS
//		let allMessages = groupedMessages.flatMap { (sectionedMessage) -> [Message] in
//			return Array(sectionedMessage.messages)
//		}

	//	print(allMessages.count)

	//	getMessages(fromIndex: mmm.count-allMessages.count-50, toIndex: mmm.count-allMessages.count)
		DispatchQueue.main.async {
			self.bottomScrollConainer.isHidden = false
		}

//		try! realm.write {
//			au
//			realm.create(Message.self, value: , update: )
//			self.messages = messages
//		}

//    let oldSections = self.groupedMessages.count
//   // self.groupedMessages = Message.groupedMessages(messages)
//
//    UIView.performWithoutAnimation {
//      collectionView.performBatchUpdates({
//        guard oldSections < self.groupedMessages.count else { collectionView.reloadSections([0]); return }
//        let amount: Int = self.groupedMessages.count - oldSections
//        var indexSet = IndexSet()
//        Array(0..<amount).forEach({ (index) in
//          indexSet.insert(index)
//        })
//        collectionView.reloadSections([0])
//        collectionView.insertSections(indexSet)
//      }, completion: { (_) in
//        DispatchQueue.main.async {
//          self.bottomScrollConainer.isHidden = false
//        }
//      })
//    }
  }
}
