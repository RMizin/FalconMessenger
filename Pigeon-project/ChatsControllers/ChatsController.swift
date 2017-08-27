//
//  ChatsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage


fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

private let userCellID = "userCellID"

protocol ManageAppearance: class {
  func manageAppearance(_ chatsController: ChatsController, didFinishLoadingWith state: Bool )
}


class ChatsController: UITableViewController {
  
  weak var delegate: ManageAppearance?
  
  var messagesDictionary = [String: (Message, User)]()
  
  var userIDs = [String]()
  
  var finalUserCellData = Array<(Message, User)>()

  
  override func viewDidLoad() {
      super.viewDidLoad()
    
    configureTableView()
    fetchConversations()
  }
  
  
  fileprivate func configureTableView() {
    
    tableView.register(UserCell.self, forCellReuseIdentifier: userCellID)
    tableView.allowsMultipleSelectionDuringEditing = false
    tableView.backgroundColor = UIColor.white
    navigationItem.leftBarButtonItem = editButtonItem
  }
 
  
  fileprivate var userConversations = 0
  
  func fetchConversations() {
    
    userConversations = 0
    
    guard let uid = Auth.auth().currentUser?.uid else {
      return
    }
    
    let currentUserConversationsReference = Database.database().reference().child("user-messages").child(uid)
    currentUserConversationsReference.keepSynced(true)
    
    currentUserConversationsReference.observe(.childAdded, with: { (snapshot) in
      
      let otherUserID = snapshot.key
      
      for snap in snapshot.children.allObjects as! [DataSnapshot] {
        if snap.key == userMessagesFirebaseFolder {
         
           self.userConversations += 1
        }
      }

      let lastMessageForConverstaionRef = Database.database().reference().child("user-messages").child(uid).child(otherUserID).child(userMessagesFirebaseFolder)
      lastMessageForConverstaionRef.keepSynced(true)
      lastMessageForConverstaionRef.queryLimited(toLast: 1).observe(.childAdded, with: { (snapshot) in
        
        let lastMessageID = snapshot.key
        self.fetchMessageWithMessageId(lastMessageID)
      })
    })
    
    currentUserConversationsReference.observe(.childRemoved, with: { (snapshot) in
      print(snapshot.key)
      print(self.messagesDictionary)
      
      self.messagesDictionary.removeValue(forKey: snapshot.key)
      self.handleReloadTable()
      
    }, withCancel: nil)
  }
  

  func fetchMessageWithMessageId(_ messageId: String) {
    
    let messagesReference = Database.database().reference().child("messages").child(messageId)
    messagesReference.keepSynced(true)
    messagesReference.observe( .value, with: { (snapshot) in
      
      if let dictionary = snapshot.value as? [String: AnyObject] {
        
        let message = Message(dictionary: dictionary)
        
        if let chatPartnerId = message.chatPartnerId() {
          self.fetchUserDataWithUserID(chatPartnerId, for: message)
        }
      }
    }, withCancel: nil)
  }
  
  
  func fetchUserDataWithUserID(_ userID: String, for message: Message) {
    
    
    let ref = Database.database().reference().child("users").child(userID)
    ref.keepSynced(true)
    ref.observe(.value, with: { (snapshot) in
      
      guard var dictionary = snapshot.value as? [String: AnyObject] else {
        return
      }
          
      dictionary.updateValue(userID as AnyObject, forKey: "id")
        
      let user = User(dictionary: dictionary)
      if user.id == Auth.auth().currentUser?.uid {
        print("\n\n  TRUE  \n\n")
      }
      self.messagesDictionary[userID] = (message, user)
      self.userIDs = self.messagesDictionary.keys.sorted()
          
      if self.userIDs.count == self.userConversations {
        self.handleReloadTable()
      }
      
    }, withCancel: { (error) in
      print("\n", error.localizedDescription, "error\n")
    })

   
  }

  
    // MARK: - Table view data source
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
    guard let uid = Auth.auth().currentUser?.uid  else {
      return
    }
      
      let message = self.finalUserCellData[indexPath.row]
      
      if let chatPartnerId = message.0.chatPartnerId() {
        Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).child(userMessagesFirebaseFolder).removeValue(completionBlock: { (error, ref) in
          
          if error != nil {
            print("Failed to delete message:", error as Any)
            return
          }
          
          self.messagesDictionary.removeValue(forKey: chatPartnerId)
          self.handleReloadTable()
          
        })
      }
  }
  
 
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 80
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userIDs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: userCellID, for: indexPath) as! UserCell

      
      cell.nameLabel.text = finalUserCellData[indexPath.row].1.name
      if finalUserCellData[indexPath.row].0.imageUrl != nil || finalUserCellData[indexPath.row].0.localImage != nil {
        cell.messageLabel.text = "Attachment: Image"
      } else if finalUserCellData[indexPath.row].0.videoUrl != nil {
        cell.messageLabel.text = "Attachment: Video"
      } else {
         cell.messageLabel.text = finalUserCellData[indexPath.row].0.text
      }
    
      cell.timeLabel.text = finalUserCellData[indexPath.row].0.timestamp?.doubleValue.getShortDateStringFromUTC()
      
        if let url = self.finalUserCellData[indexPath.row].1.thumbnailPhotoURL {
          cell.profileImageView.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named: "UserpicIcon"), options: [.continueInBackground, .progressiveDownload], completed: { (image, error, cacheType, url) in
            if image != nil {
              if (cacheType != SDImageCacheType.memory && cacheType != SDImageCacheType.disk) {
                cell.profileImageView.alpha = 0
                UIView.animate(withDuration: 0.25, animations: {
                  cell.profileImageView.alpha = 1
                })
              } else {
                cell.profileImageView.alpha = 1
              }
            }
          })
        }
      
      if finalUserCellData[indexPath.row].0.seen != nil {
        
        let seen = finalUserCellData[indexPath.row].0.seen!
        
        if !seen && finalUserCellData[indexPath.row].0.fromId != Auth.auth().currentUser?.uid {
          
          cell.newMessageIndicator.isHidden = false
          
        } else {
          
          cell.newMessageIndicator.isHidden = true
        }
        
      } else {
        
         cell.newMessageIndicator.isHidden = true
      }
    
        return cell
    }
  
  
  var chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
      let user = finalUserCellData[indexPath.row].1
      showChatControllerForUser(user)
  }
  
  
  func showChatControllerForUser(_ user: User) {
    
    let newDestination = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
    chatLogController = newDestination
    chatLogController.delegate = self
    chatLogController.user = user
    chatLogController.hidesBottomBarWhenPushed = true
  }
  
  
  func handleReloadTable() {
    
    finalUserCellData = Array(self.messagesDictionary.values)
    
    finalUserCellData.sort { (dic1: (Message, User), dic2: (Message, User)) -> Bool in
      return dic1.0.timestamp?.int32Value > dic2.0.timestamp?.int32Value
    }
    
    DispatchQueue.main.async(execute: {
          self.tableView.reloadData()
    })
    
    self.delegate?.manageAppearance(self, didFinishLoadingWith: true)
  }
}


extension ChatsController: MessagesLoaderDelegate {
  
  func messagesLoader(_ chatLogController: ChatLogController, didFinishLoadingWith messages: [Message]) {
    
    chatLogController.messages = messages
    
    var indexPaths = [IndexPath]()
    
    if messages.count - 1 >= 0 {
      for index in 0...messages.count - 1 {
        
        indexPaths.append(IndexPath(item: index, section: 0))
      }
      
      UIView.performWithoutAnimation {
        chatLogController.collectionView?.reloadItems(at:indexPaths)
      }
    }
    
    chatLogController.startCollectionViewAtBottom()
    let autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
    chatLogController.collectionView?.collectionViewLayout = autoSizingCollectionViewFlowLayout
    autoSizingCollectionViewFlowLayout.minimumLineSpacing = 5
    navigationController?.pushViewController( chatLogController, animated: true)
  }
}



