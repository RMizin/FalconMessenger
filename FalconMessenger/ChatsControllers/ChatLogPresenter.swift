//
//  ChatLogPresenter.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

let chatLogPresenter = ChatLogPresenter()

class ChatLogPresenter: NSObject {

  fileprivate var chatLogController: ChatLogViewController?
  fileprivate var messagesFetcher: MessagesFetcher?
  
//  fileprivate func controller() -> UIViewController? {
//    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
//    guard let tabBarController = appDelegate.tabBarController else { return nil }
//
//    if DeviceType.isIPad {
//        return appDelegate.splitViewController
//    }
//
//    switch CurrentTab.shared.index {
//    case 0:
//      let controller = tabBarController.contactsController
//      return controller
//    case 1:
//      let controller = tabBarController.chatsController
//      return controller
//    case 2:
//      let controller = tabBarController.settingsController
//      return controller
//    default: return nil
//    }
//  }

    fileprivate func deselectItem(controller: UIViewController) {
		guard DeviceType.isIPad else { return }
		guard let controller = controller as? UITableViewController else { return }

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

    public func open(_ conversation: Conversation, controller: UIViewController) {
		isChatLogAlreadyOpened = false
		chatLogController = ChatLogViewController()
		messagesFetcher = MessagesFetcher()
		messagesFetcher?.delegate = self

		let newMessagesReceived = (conversation.badge.value ?? 0) > 0
		let isEnoughData = conversation.messages.count >= 3

        if !newMessagesReceived && isEnoughData {
            let needUpdate = RealmKeychain.defaultRealm.object(
                ofType: Conversation.self,
                forPrimaryKey: conversation.chatID ?? "")?.shouldUpdateRealmRemotelyBeforeDisplaying.value
            if let needUpdate = needUpdate, needUpdate {
                try! RealmKeychain.defaultRealm.safeWrite {
                    RealmKeychain.defaultRealm.object(
                        ofType: Conversation.self,
                        forPrimaryKey: conversation.chatID ?? "")?.shouldUpdateRealmRemotelyBeforeDisplaying.value = false
                }
                messagesFetcher?.loadMessagesData(for: conversation, controller: controller)
            } else {
                openChatLog(for: conversation, controller: controller)
            }
            print("loading from realm")
        }

        messagesFetcher?.loadMessagesData(for: conversation, controller: controller)
	}

    fileprivate func openChatLog(for conversation: Conversation, controller: UIViewController) {
		guard isChatLogAlreadyOpened == false else { return }
		isChatLogAlreadyOpened = true
		chatLogController?.hidesBottomBarWhenPushed = true
		chatLogController?.messagesFetcher = messagesFetcher
		chatLogController?.conversation = conversation
		chatLogController?.getMessages()
		chatLogController?.observeBlockChanges()
		chatLogController?.deleteAndExitDelegate = controller as? DeleteAndExitDelegate
		if let uid = Auth.auth().currentUser?.uid, conversation.chatParticipantsIDs.contains(uid) {
			chatLogController?.configureTitleViewWithOnlineStatus()
		}

		chatLogController?.messagesFetcher?.collectionDelegate = chatLogController

		guard let destination = chatLogController else { return }

		if DeviceType.isIPad {
			let navigationController = UINavigationController(rootViewController: destination)
            controller.showDetailViewController(navigationController, sender: self)
		} else {
			controller.navigationController?.pushViewController(destination, animated: true)
		}
		deselectItem(controller: controller)
	}
}

extension ChatLogPresenter: MessagesDelegate {
  
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference, controller: UIViewController) {
		print("shouldChangeMessageStatusToReadAt ")
    chatLogController?.updateMessageStatus(messageRef: reference)
  }

  func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation, controller: UIViewController) {
		print("shouldBeUpdatedTo in presenter")
    addMessagesToRealm(messages: messages, conversation: conversation, controller: controller)
	}

    fileprivate func addMessagesToRealm(messages: [Message], conversation: Conversation, controller: UIViewController) {
		guard messages.count > 0 else {
			openChatLog(for: conversation, controller: controller)
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

				RealmKeychain.defaultRealm.create(Message.self, value: message, update: .modified)
			}

			try! RealmKeychain.defaultRealm.commitWrite()
			openChatLog(for: conversation, controller: controller)
		}
	}
}
