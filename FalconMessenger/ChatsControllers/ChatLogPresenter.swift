//
//  ChatLogPresenter.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

let chatLogPresenter = ChatLogPresenter()

class ChatLogPresenter: NSObject {

  fileprivate var chatLogController: ChatLogViewController?
  fileprivate var messagesFetcher: MessagesFetcher?
  
  fileprivate func controller() -> UIViewController? {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
    guard let tabBarController = appDelegate.tabBarController else { return nil }
   
    switch tabBarController.selectedIndex {
    case 0:
      let controller = tabBarController.contactsController
      return controller
    case 1:
      let controller = tabBarController.chatsController
      return controller
    case 2:
      let controller = tabBarController.settingsController
      return controller
    default: return nil
    }
  }
  
  fileprivate func deselectItem() {
    guard DeviceType.isIPad else { return }
    guard let controller = controller() as? UITableViewController else { return }
    
    if let indexPath = controller.tableView.indexPathForSelectedRow {
      controller.tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  public func open(_ conversation: Conversation) {
    chatLogController = ChatLogViewController()
    messagesFetcher = MessagesFetcher()
    messagesFetcher?.delegate = self
    messagesFetcher?.loadMessagesData(for: conversation)
  }
  
  public func deallocate() {
    chatLogController = nil
    messagesFetcher?.delegate = nil
    messagesFetcher = nil
  }
}

extension ChatLogPresenter: MessagesDelegate {
  
  func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
    chatLogController?.updateMessageStatus(messageRef: reference)
  }
  
  func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
    chatLogController?.hidesBottomBarWhenPushed = true
    chatLogController?.messagesFetcher = messagesFetcher
    chatLogController?.messages = messages
    chatLogController?.conversation = conversation
    chatLogController?.groupedMessages = Message.groupedMessages(messages)
    chatLogController?.deleteAndExitDelegate = controller() as? DeleteAndExitDelegate
  
    if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
      chatLogController?.observeTypingIndicator()
      chatLogController?.configureTitleViewWithOnlineStatus()
    }
    chatLogController?.observeBlockChanges()
    
    chatLogController?.messagesFetcher?.collectionDelegate = chatLogController
    guard let destination = chatLogController else { return }
    
    if DeviceType.isIPad {
      let navigationController = UINavigationController(rootViewController: destination)
      controller()?.splitViewController?.showDetailViewController(navigationController, sender: self)
    } else {
     controller()?.navigationController?.pushViewController(destination, animated: true)
     deallocate()
    }
    deselectItem()
  }
}
