//
//  ChatLogController+ChatHistoryFetcherDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/29/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension ChatLogController: ChatLogHistoryDelegate {
  
  func chatLogHistory(isEmpty: Bool) {
    refreshControl.endRefreshing()
  }
  
  func chatLogHistory(updated messages: [Message], at indexPaths: [IndexPath]) {
    contentSizeWhenInsertingToTop = collectionView?.contentSize
    isInsertingCellsToTop = true
    refreshControl.endRefreshing()
    
    self.messages = messages
    
    UIView.performWithoutAnimation {
      collectionView?.performBatchUpdates ({
        collectionView?.insertItems(at: indexPaths)
      }, completion: nil)
    }
  }
}
