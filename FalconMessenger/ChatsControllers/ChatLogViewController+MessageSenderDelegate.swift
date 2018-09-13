//
//  ChatLogViewController+MessageSenderDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension ChatLogViewController: MessageSenderDelegate {
  
  func update(mediaSending progress: Double, animated: Bool) {
    uploadProgressBar.setProgress(Float(progress), animated: animated)
  }
  
  func update(with values: [String: AnyObject]) {
    updateDataSource(with: values)
  }
  
  //TO REFACTOR
  fileprivate func updateDataSource(with values: [String: AnyObject]) {
    
    var values = values
    guard let messagesFetcher = messagesFetcher else { return }
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
    } else {
      values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
    }
    
    let message = Message(dictionary: values)
    messages.append(message)
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      messages = messagesFetcher.configureTails(for: messages, isGroupChat: true)
    } else {
      messages = messagesFetcher.configureTails(for: messages, isGroupChat: false)
    }
    
    messages.last?.status = messageStatusSending
    
    let oldNumberOfSections = groupedMessages.count
    groupedMessages = Message.groupedMessages(messages)
    guard let indexPath = Message.get(indexPathOf: message, in: groupedMessages) else { return }
    
    collectionView.performBatchUpdates({
      if oldNumberOfSections < groupedMessages.count {
        
        collectionView.insertSections([indexPath.section])
        
        guard indexPath.section-1 >= 0, groupedMessages[indexPath.section-1].count-1 >= 0 else { return }
        let previousItem = groupedMessages[indexPath.section-1].count-1
        collectionView.reloadItems(at: [IndexPath(row: previousItem, section: indexPath.section-1)])
      } else {
        collectionView.insertItems(at: [indexPath])
        let previousRow = groupedMessages[indexPath.section].count-2
        self.collectionView.reloadItems(at: [IndexPath(row: previousRow, section: indexPath.section)])
      }
    }) { (_) in
      self.collectionView.scrollToBottom(animated: true)
    }
  }
}
