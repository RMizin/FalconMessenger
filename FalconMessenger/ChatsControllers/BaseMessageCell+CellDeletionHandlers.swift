//
//  BaseMessageCell+CellDeletionHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 12/12/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FTPopOverMenu_Swift
import Firebase

struct ContextMenuItems {
  static let copyItem = "Copy"
  static let copyPreviewItem = "Copy image preview"
  static let deleteItem = "Delete for myself"
  static let reportItem = "Report"
  
  static func contextMenuItems(for messageType: MessageType, _ isIncludedReport: Bool) -> [String] {
    guard isIncludedReport else {
      return defaultMenuItems(for: messageType)
    }
    switch messageType {
    case .textMessage, .photoMessage:
      return [ContextMenuItems.copyItem, ContextMenuItems.deleteItem, ContextMenuItems.reportItem]
    case .videoMessage:
      return [ContextMenuItems.copyPreviewItem, ContextMenuItems.deleteItem, ContextMenuItems.reportItem]
    case .voiceMessage:
      return [ContextMenuItems.deleteItem, ContextMenuItems.reportItem]
    case .sendingMessage:
      return  [ContextMenuItems.copyItem]
    }
  }
  
  static func defaultMenuItems(for messageType: MessageType) -> [String] {
    switch messageType {
    case .textMessage, .photoMessage:
      return [ContextMenuItems.copyItem, ContextMenuItems.deleteItem]
    case .videoMessage:
      return [ContextMenuItems.copyPreviewItem, ContextMenuItems.deleteItem]
    case .voiceMessage:
      return [ContextMenuItems.deleteItem]
    case .sendingMessage:
      return  [ContextMenuItems.copyItem]
    }
  }
}

extension BaseMessageCell {
  
  func bubbleImage(currentColor: UIColor) -> UIColor {
    switch currentColor {
    case ThemeManager.currentTheme().outgoingBubbleTintColor:
      return ThemeManager.currentTheme().selectedOutgoingBubbleTintColor
    case ThemeManager.currentTheme().incomingBubbleTintColor:
      return ThemeManager.currentTheme().selectedIncomingBubbleTintColor
    default:
     return currentColor
  }
}
  
  @objc func handleLongTap(_ longPressGesture: UILongPressGestureRecognizer) {
    guard longPressGesture.state == .began else { return }
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
    
    let isOutgoing = self.message?.fromId == Auth.auth().currentUser?.uid
    var contextMenuItems = ContextMenuItems.contextMenuItems(for: .textMessage, !isOutgoing)
    let config = FTConfiguration.shared
    let expandedMenuWidth: CGFloat = 150
    let defaultMenuWidth: CGFloat = 100
    config.menuWidth = expandedMenuWidth
  
    guard let indexPath = self.chatLogController?.collectionView.indexPath(for: self) else { return }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? OutgoingVoiceMessageCell {
      if self.message?.status == messageStatusSending { return }
      cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
      contextMenuItems = ContextMenuItems.contextMenuItems(for: .voiceMessage, !isOutgoing)
    //  contextMenuItems = [ContextMenuItems.deleteItem, ContextMenuItems.reportItem]
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingVoiceMessageCell {
      if self.message?.status == messageStatusSending { return }
        contextMenuItems = ContextMenuItems.contextMenuItems(for: .voiceMessage, !isOutgoing)
     // contextMenuItems = [ContextMenuItems.deleteItem, ContextMenuItems.reportItem]
      cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? PhotoMessageCell {
       cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
      if !cell.playButton.isHidden {
        contextMenuItems = ContextMenuItems.contextMenuItems(for: .videoMessage, !isOutgoing)
      //  contextMenuItems = [ContextMenuItems.copyPreviewItem, ContextMenuItems.deleteItem, ContextMenuItems.reportItem]
        config.menuWidth = expandedMenuWidth
      }
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingPhotoMessageCell {
       cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
      if !cell.playButton.isHidden {
        contextMenuItems = ContextMenuItems.contextMenuItems(for: .videoMessage, !isOutgoing)
       // contextMenuItems = [ContextMenuItems.copyPreviewItem, ContextMenuItems.deleteItem, ContextMenuItems.reportItem]
        config.menuWidth = expandedMenuWidth
      }
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? OutgoingTextMessageCell {
     cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
    }
    
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingTextMessageCell {
      cell.bubbleView.tintColor = bubbleImage(currentColor: cell.bubbleView.tintColor)
    }
    
    if self.message?.messageUID == nil || self.message?.status == messageStatusSending {
      config.menuWidth = defaultMenuWidth
      contextMenuItems = ContextMenuItems.contextMenuItems(for: .sendingMessage, !isOutgoing)
    }
    
    FTPopOverMenu.showForSender(sender: bubbleView, with: contextMenuItems, done: { (selectedIndex) in
      
      guard contextMenuItems[selectedIndex] != ContextMenuItems.reportItem else {
        self.handleReport(indexPath: indexPath)
        print("handlong report")
        return
      }
      
      guard contextMenuItems[selectedIndex] != ContextMenuItems.deleteItem else {
        self.handleDeletion(indexPath: indexPath)
        print("handling deletion")
        return
      }
      print("handling coly")
      self.handleCopy(indexPath: indexPath)
    }) { //completeion
     self.chatLogController?.collectionView.reloadItems(at: [indexPath])
    }
  }
  
  fileprivate func handleReport(indexPath: IndexPath) {
    chatLogController?.collectionView.reloadItems(at: [indexPath])
    chatLogController?.inputContainerView.resignAllResponders()
    
    let reportAlert = ReportAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    reportAlert.controller = chatLogController
    reportAlert.indexPath = indexPath
    reportAlert.reportedMessage = message
    reportAlert.popoverPresentationController?.sourceView = bubbleView
    reportAlert.popoverPresentationController?.sourceRect = CGRect(x: bubbleView.bounds.midX, y: bubbleView.bounds.maxY, width: 0, height: 0)
    chatLogController?.present(reportAlert, animated: true, completion: nil)
  }

  fileprivate func handleCopy(indexPath: IndexPath) {
    self.chatLogController?.collectionView.reloadItems(at: [indexPath])
    if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? PhotoMessageCell {
      if cell.messageImageView.image == nil {
        guard let controllerToDisplayOn = self.chatLogController else { return }
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: copyingImageError, controller: controllerToDisplayOn)
        return
      }
      UIPasteboard.general.image = cell.messageImageView.image
    } else if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingPhotoMessageCell {
      if cell.messageImageView.image == nil {
        guard let controllerToDisplayOn = self.chatLogController else { return }
        basicErrorAlertWith(title: basicErrorTitleForAlert, message: copyingImageError, controller: controllerToDisplayOn)
        return
      }
      UIPasteboard.general.image = cell.messageImageView.image
    } else if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? OutgoingTextMessageCell {
      UIPasteboard.general.string = cell.textView.text
    } else if let cell = self.chatLogController?.collectionView.cellForItem(at: indexPath) as? IncomingTextMessageCell {
      UIPasteboard.general.string = cell.textView.text
    } else {
      return
    }
  }
  
  func handleDeletion(indexPath: IndexPath) {
    guard let uid = Auth.auth().currentUser?.uid, let partnerID = self.message?.chatPartnerId(), let messageID = self.message?.messageUID, self.currentReachabilityStatus != .notReachable else {
      self.chatLogController?.collectionView.reloadItems(at: [indexPath])
      guard let controllerToDisplayOn = self.chatLogController else { return }
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: controllerToDisplayOn)
      return
    }
    
    var deletionReference: DatabaseReference!
    
    if let isGroupChat = self.chatLogController?.conversation?.isGroupChat, isGroupChat {
      guard let conversationID = self.chatLogController?.conversation?.chatID else { return }
      deletionReference = Database.database().reference().child("user-messages").child(uid).child(conversationID).child(userMessagesFirebaseFolder).child(messageID)
    } else {
      deletionReference = Database.database().reference().child("user-messages").child(uid).child(partnerID).child(userMessagesFirebaseFolder).child(messageID)
    }
    
    deletionReference.removeValue(completionBlock: { (error, reference) in
      if error != nil { return }
      
      if let isGroupChat = self.chatLogController?.conversation?.isGroupChat , isGroupChat {
        
        guard let conversationID = self.chatLogController?.conversation?.chatID else { return }
        
        var lastMessageReference = Database.database().reference().child("user-messages").child(uid).child(conversationID).child(messageMetaDataFirebaseFolder)
        if let lastMessageID = self.chatLogController?.messages.last?.messageUID {
          lastMessageReference.updateChildValues(["lastMessageID": lastMessageID])
        } else {
          lastMessageReference = lastMessageReference.child("lastMessageID")
          lastMessageReference.removeValue()
        }
        
      } else {
        var lastMessageReference = Database.database().reference().child("user-messages").child(uid).child(partnerID).child(messageMetaDataFirebaseFolder)
        if let lastMessageID = self.chatLogController?.messages.last?.messageUID {
          lastMessageReference.updateChildValues(["lastMessageID": lastMessageID])
        } else {
          lastMessageReference = lastMessageReference.child("lastMessageID")
          lastMessageReference.removeValue()
        }
      }
    })
  }
}
