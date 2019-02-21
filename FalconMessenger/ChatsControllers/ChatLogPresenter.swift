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

	public func tryDeallocate(force: Bool = false) {
		chatLogController = nil
		messagesFetcher?.delegate = nil
		messagesFetcher = nil
		print("deallocate")
	}

	fileprivate var isChatLogAlreadyOpened = false

	public func open(_ conversation: Conversation) {
		isChatLogAlreadyOpened = false
		chatLogController = ChatLogViewController()
		messagesFetcher = MessagesFetcher()
		messagesFetcher?.delegate = self

		let newMessagesReceived = (conversation.badge.value ?? 0) > 0
		let isEnoughData = conversation.messages.count >= 3

		if !newMessagesReceived && isEnoughData {
			openChatLog(for: conversation)
			print("loading from realm")
		}

		messagesFetcher?.loadMessagesData(for: conversation)
	}

	fileprivate func openChatLog(for conversation: Conversation) {
		guard isChatLogAlreadyOpened == false else { return }
		isChatLogAlreadyOpened = true
		chatLogController?.hidesBottomBarWhenPushed = true
		chatLogController?.messagesFetcher = messagesFetcher
		chatLogController?.conversation = conversation
		chatLogController?.getMessages()
		chatLogController?.deleteAndExitDelegate = controller() as? DeleteAndExitDelegate
		if let uid = Auth.auth().currentUser?.uid, conversation.chatParticipantsIDs.contains(uid) {
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
		}
		deselectItem()
	}
}

extension ChatLogPresenter: MessagesDelegate {
  
  func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
		print("shouldChangeMessageStatusToReadAt ")
    chatLogController?.updateMessageStatus(messageRef: reference)
  }

  func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
		print("shouldBeUpdatedTo in presenter")
		addMessagesToRealm(messages: messages, conversation: conversation)
	}

	fileprivate func addMessagesToRealm(messages: [Message], conversation: Conversation) {
		guard messages.count > 0 else {
			openChatLog(for: conversation)
			return
		}

		autoreleasepool {
			guard !RealmKeychain.defaultRealm.isInWriteTransaction else { return }
			RealmKeychain.defaultRealm.beginWrite()
			for message in messages {

				if message.senderName == nil {
					message.senderName = RealmKeychain.defaultRealm.object(ofType: Message.self, forPrimaryKey: message.messageUID ?? "")?.senderName
				}

				if message.isCrooked.value == nil {
					message.isCrooked.value = RealmKeychain.defaultRealm.object(ofType: Message.self, forPrimaryKey: message.messageUID ?? "")?.isCrooked.value
				}
				
				if message.thumbnailImage == nil {
					message.thumbnailImage = RealmKeychain.defaultRealm.object(ofType: RealmImage.self, forPrimaryKey: (message.messageUID ?? "") + "thumbnail")
				}

				if message.localImage == nil {
					message.localImage = RealmKeychain.defaultRealm.object(ofType: RealmImage.self, forPrimaryKey: message.messageUID ?? "")
				}

				RealmKeychain.defaultRealm.create(Message.self, value: message, update: true)
			}

			try! RealmKeychain.defaultRealm.commitWrite()
			openChatLog(for: conversation)
		}
	}
}
