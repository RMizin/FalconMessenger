//
//  ChatLogViewController+ChatHistoryFetcherDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/28/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension ChatLogViewController: ChatLogHistoryDelegate {
  
  func chatLogHistory(isEmpty: Bool) {
    refreshControl.endRefreshing()
  }

  func chatLogHistory(updated messages: [Message]) {
    globalDataStorage.contentSizeWhenInsertingToTop = collectionView.contentSize
    globalDataStorage.isInsertingCellsToTop = true
    refreshControl.endRefreshing()
    self.messages = messages
    let oldSections = self.groupedMessages.count
    self.groupedMessages = Message.groupedMessages(messages)
    
    UIView.performWithoutAnimation {
      collectionView.performBatchUpdates({
        guard oldSections < self.groupedMessages.count else { collectionView.reloadSections([0]); return }
        let amount: Int = self.groupedMessages.count - oldSections
        var indexSet = IndexSet()
        Array(0..<amount).forEach({ (index) in
          indexSet.insert(index)
        })
        collectionView.reloadSections([0])
        collectionView.insertSections(indexSet)
      }, completion: { (_) in
        DispatchQueue.main.async {
          self.bottomScrollConainer.isHidden = false
        }
      })
    }
  }
}
