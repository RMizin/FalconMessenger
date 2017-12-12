//
//  BaseMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import FTPopOverMenu_Swift
import Firebase

struct ContextMenuItems {
  static let copyItem = "Copy"
  static let copyPreviewItem = "Copy image preview"
  static let deleteItem = "Delete for myself"
}

class BaseMessageCell: RevealableCollectionViewCell {
  weak var message: Message?
  weak var chatLogController: ChatLogController?
  let grayBubbleImage = ThemeManager.currentTheme().incomingBubble
  let blueBubbleImage = ThemeManager.currentTheme().outgoingBubble
  
  let bubbleView: UIImageView = {
    let bubbleView = UIImageView()
    bubbleView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    bubbleView.isUserInteractionEnabled = true
    
    return bubbleView
  }()
  
  var deliveryStatus: UILabel = {
    var deliveryStatus = UILabel()
    deliveryStatus.text = "status"
    deliveryStatus.font = UIFont.boldSystemFont(ofSize: 10)
    deliveryStatus.textColor =  ThemeManager.currentTheme().generalSubtitleColor
    deliveryStatus.isHidden = true
    deliveryStatus.textAlignment = .right
    
    return deliveryStatus
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame.integral)
    
    setupViews()
  }
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
 @objc func handleLongTap(_ longPressGesture: UILongPressGestureRecognizer) {
    var contextMenuItems = [ContextMenuItems.copyItem, ContextMenuItems.deleteItem]
    let config = FTConfiguration.shared
    config.menuWidth = 150
  
  
  
    guard let indexPath = self.chatLogController?.collectionView?.indexPath(for: self) else { return }
  
    if let _ = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? OutgoingVoiceMessageCell {
      if self.message?.status == messageStatusSending { return }
      contextMenuItems = [ContextMenuItems.deleteItem]
    }
    if let _ = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? IncomingVoiceMessageCell {
      if self.message?.status == messageStatusSending { return }
      contextMenuItems = [ContextMenuItems.deleteItem]
    }
    if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? PhotoMessageCell {
      if !cell.playButton.isHidden {
        contextMenuItems = [ContextMenuItems.copyPreviewItem, ContextMenuItems.deleteItem]
        config.menuWidth = 150
      }
    }
    if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? IncomingPhotoMessageCell {
      if !cell.playButton.isHidden {
        contextMenuItems = [ContextMenuItems.copyPreviewItem, ContextMenuItems.deleteItem]
        config.menuWidth = 150
      }
    }
  
    if self.message?.messageUID == nil || self.message?.status == messageStatusSending {
      config.menuWidth = 100
      contextMenuItems = [ContextMenuItems.copyItem]
    }
  
    FTPopOverMenu.showForSender(sender: bubbleView, with: contextMenuItems, done: { (selectedIndex) in
      // TODO: CHANGE BUBBLE VIEW IMAGE TO IMAGE WITH DARKER BACKGROUND
      print(selectedIndex)
      if contextMenuItems[selectedIndex] == ContextMenuItems.copyItem ||
        contextMenuItems[selectedIndex] == ContextMenuItems.copyPreviewItem {
        if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? PhotoMessageCell {
          UIPasteboard.general.image = cell.messageImageView.image
        } else if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? IncomingPhotoMessageCell {
          UIPasteboard.general.image = cell.messageImageView.image
        } else if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? OutgoingTextMessageCell {
          UIPasteboard.general.string = cell.textView.text
        } else if let cell = self.chatLogController?.collectionView?.cellForItem(at: indexPath) as? IncomingTextMessageCell {
          UIPasteboard.general.string = cell.textView.text
        } else {
          return
        }
      } else {
        self.chatLogController?.deletedMessagesNumber += 1
        guard let uid = Auth.auth().currentUser?.uid,let partnerID = self.message?.chatPartnerId(),let messageID = self.message?.messageUID else { return }
        
        let deletionReference = Database.database().reference().child("user-messages").child(uid).child(partnerID).child("userMessages").child(messageID)
        deletionReference.removeValue(completionBlock: { (error, reference) in
          if error != nil {
             self.chatLogController?.deletedMessagesNumber -= 1
            print(error?.localizedDescription ?? "", "\nERROR DELETION\n")
            return
          }
          
          self.chatLogController?.collectionView?.performBatchUpdates ({
           
            if let index = self.chatLogController?.mediaMessages.index(where: { (message) -> Bool in  //if removing message is photo message
              return message.messageUID == self.chatLogController?.messages[indexPath.item].messageUID
            })  {
              self.chatLogController?.mediaMessages.remove(at: index)
            }
            
            self.chatLogController?.messages.remove(at: indexPath.item)
            self.chatLogController?.collectionView?.deleteItems(at: [indexPath])
           
          }, completion: { (isCompleted) in
            
              print("\ncell deletion completed\n")
          })
          
        
          print("\nsuccessgully deleted\n")
        })
      }
    }) { //completeion
        // TODO: CHANGE BUBBLE VIEW IMAGE TO DEFAULT IMAGE
    }
  }
  
  func setupViews() {
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  func prepareViewsForReuse() {}
  
  override func prepareForReuse() {
    super.prepareForReuse()
    prepareViewsForReuse()
  }
}
