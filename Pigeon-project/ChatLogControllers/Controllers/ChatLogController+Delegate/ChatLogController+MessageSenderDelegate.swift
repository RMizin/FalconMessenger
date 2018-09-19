//
//  ChatLogController+MessageSenderDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/19/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension ChatLogController: MessageSenderDelegate {
  
  func update(mediaSending progress: Double, animated: Bool) {
    uploadProgressBar.setProgress(Float(progress), animated: animated)
  }
  
  func update(with values: [String: AnyObject]) {
    updateDataSource(with: values)
  }
  
  //TO REFACTOR
  fileprivate func updateDataSource(with values: [String: AnyObject]) {
    
    var values = values
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
    } else {
      values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
    }
    
    self.collectionView?.performBatchUpdates ({
      
      let message = Message(dictionary: values)
      self.messages.append(message)
      let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
      self.messages[indexPath.item].status = messageStatusSending
      self.collectionView?.insertItems(at: [indexPath])
      if self.messages.count - 2 >= 0 {
        self.collectionView?.reloadItems(at: [IndexPath(row: self.messages.count-2, section: 0)])
      }
      
      let indexPath1 = IndexPath(item: self.messages.count - 1, section: 0)
      
      DispatchQueue.main.async {
        self.collectionView?.scrollToItem(at: indexPath1, at: .bottom, animated: true)
      }
    }, completion: nil)
  }
}

