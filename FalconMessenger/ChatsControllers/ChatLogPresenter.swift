//
//  ChatLogPresenter.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

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

	fileprivate var isLoadedFromRealm = false
	fileprivate var isLoadedFromFirebase = false

	public func open(_ conversation: Conversation) {
	 	isLoadedFromFirebase = false
		isLoadedFromRealm = false
		chatLogController = ChatLogViewController()
		messagesFetcher = MessagesFetcher()
		messagesFetcher?.delegate = self
		
		chatLogController?.hidesBottomBarWhenPushed = true
		chatLogController?.messagesFetcher = messagesFetcher

		chatLogController?.conversation = conversation


		loadFromRealm(conversation: conversation)
		messagesFetcher?.loadMessagesData(for: conversation)
	}

	fileprivate func loadFromRealm(conversation: Conversation) {
		let isNotEnoughData = conversation.messages.count <= 3
		if !isNotEnoughData {
			print("opening from realm")
			isLoadedFromRealm = true
			openChatLog(for: conversation)
		}
	}

	fileprivate func openChatLog(for conversation: Conversation) {
		chatLogController?.getMessages()
		chatLogController?.deleteAndExitDelegate = controller() as? DeleteAndExitDelegate

		if let uid = Auth.auth().currentUser?.uid, conversation.chatParticipantsIDs.contains(uid) {
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

			if isLoadedFromRealm == true {
				deallocate()
			}

			if isLoadedFromFirebase == true {
				deallocate()
			}
		}
		deselectItem()
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

	fileprivate func addMessagesToRealm(messages: [Message]) {
		guard messages.count > 0 else { return }
		let realm = try! Realm()

		autoreleasepool {
			realm.beginWrite()
			for message in messages {
				realm.create(Message.self, value: message, update: true)
			}
			try! realm.commitWrite()
		}
	}

  func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
		// проверить не было ли удалено сообений
		addMessagesToRealm(messages: messages)
		guard isLoadedFromRealm == false else { return }
		print("firebase update")
		isLoadedFromFirebase = true
		openChatLog(for: conversation)
	}
}
