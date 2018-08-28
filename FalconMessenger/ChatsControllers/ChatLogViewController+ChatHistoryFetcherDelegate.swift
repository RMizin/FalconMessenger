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

  func chatLogHistory(updated messages: [Message], at indexPaths: [IndexPath]) {
    globalDataStorage.contentSizeWhenInsertingToTop = collectionView.contentSize
    globalDataStorage.isInsertingCellsToTop = true
    refreshControl.endRefreshing()
    
    self.messages = messages
    
    UIView.performWithoutAnimation {
      collectionView.performBatchUpdates ({
        collectionView.insertItems(at: indexPaths)
      }, completion: { (_) in
        DispatchQueue.main.async {
          self.bottomScrollConainer.isHidden = false
        }
      })
    }
  }
}
