//
//  ChatLogController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos
import AudioToolbox
import FLAnimatedImage
import FTPopOverMenu_Swift
import CropViewController

private let incomingTextMessageCellID = "incomingTextMessageCellID"

private let outgoingTextMessageCellID = "outgoingTextMessageCellID"

private let typingIndicatorCellID = "typingIndicatorCellID"

private let photoMessageCellID = "photoMessageCellID"

private let outgoingVoiceMessageCellID = "outgoingVoiceMessageCellID"

private let incomingVoiceMessageCellID = "incomingVoiceMessageCellID"

private let typingIndicatorDatabaseID = "typingIndicator"

private let typingIndicatorStateDatabaseKeyID = "Is typing"

private let incomingPhotoMessageCellID = "incomingPhotoMessageCellID"

private let informationMessageCellID = "informationMessageCellID"

protocol DeleteAndExitDelegate: class {
  func deleteAndExit(from conversationID: String)
}


class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

  var conversation: Conversation?
  
  var messagesFetcher: MessagesFetcher!
  
  var membersReference: DatabaseReference!
  
  var membersAddingHandle: DatabaseHandle!
  
  var membersRemovingHandle: DatabaseHandle!
  
  var typingIndicatorReference: DatabaseReference!
  
  var typingIndicatorHandle: DatabaseHandle!
  
  var userStatusReference: DatabaseReference!
  
  var chatNameReference: DatabaseReference!
  
  var chatNameHandle: DatabaseHandle!
  
  var chatAdminReference: DatabaseReference!
  
  var chatAdminHandle: DatabaseHandle!
  
  var messageChangesHandles = [(uid:String, handle:DatabaseHandle)]()
  
  var messages = [Message]()
  
  var sections = ["Messages"]
  
  let messagesToLoad = 50
  
  var mediaPickerController: MediaPickerControllerNew! = nil
  
  var voiceRecordingViewController: VoiceRecordingViewController! = nil
  
  weak var deleteAndExitDelegate: DeleteAndExitDelegate?
  
  var chatLogAudioPlayer: AVAudioPlayer!
  
  var inputTextViewTapGestureRecognizer = UITapGestureRecognizer()
  
  var uploadProgressBar = UIProgressView(progressViewStyle: .bar)

  
  func scrollToBottom(at position: UICollectionViewScrollPosition) {
    if self.messages.count - 1 <= 0 {
      return
    }
    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
    DispatchQueue.main.async {
      self.collectionView?.scrollToItem(at: indexPath, at: position, animated: true)
    }
  }
  
  func scrollToBottomOfTypingIndicator() {
    if collectionView?.numberOfSections != 2 {
      return
    }
    let indexPath = IndexPath(item: 0, section: 1)
    DispatchQueue.main.async {
      self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
  }

  func observeMembersChanges() {
    
    guard let chatID = conversation?.chatID else { return }
    
    chatNameReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatName")
    chatNameHandle = chatNameReference.observe(.value, with: { (snapshot) in
      guard let newName = snapshot.value as? String else { return }
      self.conversation?.chatName = newName
      if self.isCurrentUserMemberOfCurrentGroup() {
        self.configureTitleViewWithOnlineStatus()
      }
    })
    
    chatAdminReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("admin")
    chatAdminHandle = chatAdminReference.observe(.value, with: { (snapshot) in
      guard let newAdmin = snapshot.value as? String else { return }
      self.conversation?.admin = newAdmin
    })
    
    membersReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs")
    membersAddingHandle = membersReference.observe(.childAdded) { (snapshot) in
      guard let id = snapshot.value as? String, let members = self.conversation?.chatParticipantsIDs else { return }
      
      if let _ = members.index(where: { (memberID) -> Bool in
        return memberID == id }) {
      } else {
        self.conversation?.chatParticipantsIDs?.append(id)
        self.changeUIAfterChildAddedIfNeeded()
      }
    }
    
    membersRemovingHandle = membersReference.observe(.childRemoved) { (snapshot) in
      guard let id = snapshot.value as? String, let members = self.conversation?.chatParticipantsIDs else { return }
      
      guard let memberIndex = members.index(where: { (memberID) -> Bool in
        return memberID == id
      }) else { return }
      self.conversation?.chatParticipantsIDs?.remove(at: memberIndex)
      self.changeUIAfterChildRemovedIfNeeded()
    }
  }
  
  func isCurrentUserMemberOfCurrentGroup() -> Bool {
    guard let membersIDs = conversation?.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) else { return false }
    return true
  }
  
  func changeUIAfterChildAddedIfNeeded() {
    if isCurrentUserMemberOfCurrentGroup() {
      configureTitleViewWithOnlineStatus()
      if typingIndicatorReference == nil {
        reloadInputViews()
        observeTypingIndicator()
        navigationItem.rightBarButtonItem?.isEnabled = true
      }
    }
  }
  
  func changeUIAfterChildRemovedIfNeeded() {
    if isCurrentUserMemberOfCurrentGroup() {
      configureTitleViewWithOnlineStatus()
    } else {
      inputContainerView.inputTextView.resignFirstResponder()
      handleTypingIndicatorAppearance(isEnabled: false)
      removeSubtitleInGroupChat()
      reloadInputViews()
      navigationItem.rightBarButtonItem?.isEnabled = false
      if typingIndicatorReference != nil { typingIndicatorReference.removeObserver(withHandle: typingIndicatorHandle); typingIndicatorReference = nil }
    }
  }

  func removeSubtitleInGroupChat() {
    if let isGroupChat = conversation?.isGroupChat, isGroupChat, let title = conversation?.chatName {
      let subtitle = ""
      navigationItem.setTitle(title: title, subtitle: subtitle)
      return
    }
  }
  
  var startingIDReference: DatabaseReference!
  var endingIDReference: DatabaseReference!
  var startingIDQuery: DatabaseQuery!
  var endingIDQuery: DatabaseQuery!
  var userMessagesReference: DatabaseReference!
  var userMessagesQuery: DatabaseQuery!
  var userMessageHande: DatabaseHandle!
  
  func loadPreviousMessages(isGroupChat: Bool) {
    
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID else { return }
    let numberOfMessagesToLoad = messages.count + messagesToLoad
    let nextMessageIndex = messages.count + 1
    let oldestMessagesLoadingGroup = DispatchGroup()
    if messages.count <= 0 { self.refreshControl.endRefreshing() }

    startingIDReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder)
    startingIDQuery = startingIDReference.queryLimited(toLast: UInt(numberOfMessagesToLoad))

    startingIDQuery.keepSynced(true)
    startingIDQuery.observeSingleEvent(of: .childAdded, with: { (snapshot) in
      let queryStartingID = snapshot.key
      self.endingIDReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder)
      self.endingIDQuery = self.endingIDReference.queryLimited(toLast: UInt(nextMessageIndex))
      
      self.endingIDQuery.keepSynced(true)
      self.endingIDQuery.observeSingleEvent(of: .childAdded, with: { (snapshot) in
        let queryEndingID = snapshot.key
        if (queryStartingID == queryEndingID) && self.messages.contains(where: { (message) -> Bool in
          return message.messageUID == queryEndingID
        }) {
          self.refreshControl.endRefreshing()
          return
        }
        
        self.userMessagesReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(userMessagesFirebaseFolder)
        self.userMessagesQuery = self.userMessagesReference.queryOrderedByKey().queryStarting(atValue: queryStartingID).queryEnding(atValue: queryEndingID)
    
        self.userMessagesQuery.keepSynced(true)
        self.userMessagesQuery.observeSingleEvent(of: .value, with: { (snapshot) in
          for _ in 0 ..< snapshot.childrenCount { oldestMessagesLoadingGroup.enter() }

          oldestMessagesLoadingGroup.notify(queue: DispatchQueue.main, execute: {
            var arrayWithShiftedMessages = self.messages
            let shiftingIndex = self.messagesToLoad - (numberOfMessagesToLoad - self.messages.count )
            arrayWithShiftedMessages.shiftInPlace(withDistance: -shiftingIndex)
            guard self.messagesFetcher != nil else { return }
            self.messages = self.messagesFetcher.configureMessageTails(messages: arrayWithShiftedMessages, isGroupChat: isGroupChat)
            self.userMessagesReference.removeObserver(withHandle: self.userMessageHande)
            self.userMessagesQuery.removeObserver(withHandle: self.userMessageHande)

            contentSizeWhenInsertingToTop = self.collectionView?.contentSize
            isInsertingCellsToTop = true
            self.refreshControl.endRefreshing()
       
            var indexPaths = [IndexPath]()
            Array(0..<shiftingIndex).forEach({ (index) in
              indexPaths.append(IndexPath(item: index, section: 0))
            })
            UIView.performWithoutAnimation {
              self.collectionView?.performBatchUpdates ({
                self.collectionView?.insertItems(at: indexPaths)
              }, completion: nil)
            }
          })

          self.userMessageHande = self.userMessagesQuery.observe(.childAdded, with: { (snapshot) in
            let messagesRef = Database.database().reference().child("messages").child(snapshot.key)
            let messageUID = snapshot.key
            messagesRef.keepSynced(true)
           
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
              guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
              dictionary.updateValue(messageUID as AnyObject, forKey: "messageUID")
          
              guard self.messagesFetcher != nil else { return }
             
              dictionary = self.messagesFetcher.preloadCellData(to: dictionary, isGroupChat: isGroupChat)
              let message = Message(dictionary: dictionary)
              self.messagesFetcher.loadUserNameForOneMessage(message: message, completion: { [unowned self] (isCompleted, newMessage)  in
                self.messages.append(newMessage)
                oldestMessagesLoadingGroup.leave()
              })
            }, withCancel: nil)
          })
        })
      }) // endingIDRef
    }) // startingIDRef
  }
  
  private var localTyping = false
  
  var isTyping: Bool {
    get {
      return localTyping
    }
    set {
      localTyping = newValue
      let typingData: NSDictionary = [Auth.auth().currentUser!.uid : newValue] //??
      if localTyping {
        sendTypingStatus(data: typingData)
      } else {
        if let isGroupChat = conversation?.isGroupChat, isGroupChat {
          guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID else { return }
          let userIsTypingRef = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID).child(currentUserID)
          userIsTypingRef.removeValue()
        } else {
          guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID else { return }
          let userIsTypingRef = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(typingIndicatorDatabaseID)
          userIsTypingRef.removeValue()
        }
      }
    }
  }
  
  func sendTypingStatus(data: NSDictionary) {
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID, currentUserID != conversationID else { return }

    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      let userIsTypingRef = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID)
      userIsTypingRef.updateChildValues(data as! [AnyHashable : Any])
    } else {
      let userIsTypingRef = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(typingIndicatorDatabaseID)
      userIsTypingRef.setValue(data)
    }
  }
  
  func observeTypingIndicator () {
    guard let currentUserID = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID, currentUserID != conversationID else { return }
    
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      let indicatorRemovingReference = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID).child(currentUserID)
      indicatorRemovingReference.onDisconnectRemoveValue()
      typingIndicatorReference = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID)
      typingIndicatorHandle = typingIndicatorReference.observe(.value, with: { (snapshot) in
        
        guard let dictionary = snapshot.value as? [String:AnyObject], let firstKey = dictionary.first?.key else {
          self.handleTypingIndicatorAppearance(isEnabled: false)
          return
        }
        
        if firstKey == currentUserID && dictionary.count == 1 {
          self.handleTypingIndicatorAppearance(isEnabled: false)
          return
        }
        
        self.handleTypingIndicatorAppearance(isEnabled: true)
      })

    } else {
      let indicatorRemovingReference = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(typingIndicatorDatabaseID)
      indicatorRemovingReference.onDisconnectRemoveValue()
      typingIndicatorReference = Database.database().reference().child("user-messages").child(conversationID).child(currentUserID).child(typingIndicatorDatabaseID).child(conversationID)
      typingIndicatorReference.onDisconnectRemoveValue()
      typingIndicatorHandle = typingIndicatorReference.observe(.value, with: { (isTyping) in
        guard let isParticipantTyping = isTyping.value! as? Bool, isParticipantTyping else {
          self.handleTypingIndicatorAppearance(isEnabled: false)
          return
        }
        self.handleTypingIndicatorAppearance(isEnabled: true)
      })
    }
  }

  fileprivate func handleTypingIndicatorAppearance(isEnabled: Bool) {
    
    let sectionsIndexSet: IndexSet = [1]
    
    if isEnabled {
      guard sections.count < 2 else { return }
      self.collectionView?.performBatchUpdates ({
        
        self.sections = ["Messages", "TypingIndicator"]
        
        self.collectionView?.insertSections(sectionsIndexSet)
        
      }, completion: { (true) in
        if self.collectionView!.contentOffset.y >= (self.collectionView!.contentSize.height - self.collectionView!.frame.size.height - 200) {
          if self.collectionView!.contentSize.height < self.collectionView!.bounds.height  {
            return
          }
          
          if #available(iOS 11.0, *) {
            let currentContentOffset = self.collectionView?.contentOffset
            let newContentOffset = CGPoint(x: 0, y: currentContentOffset!.y + 40)
            self.collectionView?.setContentOffset(newContentOffset, animated: true)
          } else {
            self.scrollToBottomOfTypingIndicator()
          }
        }
      })
      
    } else {
      
      guard sections.count == 2 else { return }
      self.collectionView?.performBatchUpdates ({
        
        self.sections = ["Messages"]
        
        if self.collectionView!.numberOfSections > 1 {
          self.collectionView?.deleteSections(sectionsIndexSet)
          
          guard let cell = self.collectionView?.cellForItem(at: IndexPath(item: 0, section: 1 ) ) as? TypingIndicatorCell else {
            return
          }
          
          cell.typingIndicator.animatedImage = nil
          if self.collectionView!.contentOffset.y >= (self.collectionView!.contentSize.height - self.collectionView!.frame.size.height + 200) {
            self.scrollToBottom(at: .bottom)
          }
        }
      }, completion: nil)
    }
  }

  func updateMessageStatus(messageRef: DatabaseReference) {
    
    guard let uid = Auth.auth().currentUser?.uid, currentReachabilityStatus != .notReachable else { return }

    var senderID: String?
    
    messageRef.child("fromId").observeSingleEvent(of: .value, with: { (snapshot) in
      
      if !snapshot.exists() { return }
    
      senderID = snapshot.value as? String
      guard uid != senderID,
         (self.navigationController?.visibleViewController is UserInfoTableViewController ||
          self.navigationController?.visibleViewController is ChatLogController ||
          self.navigationController?.visibleViewController is GroupAdminControlsTableViewController ||
          topViewController(rootViewController: self) is CropViewController ||
          topViewController(rootViewController: self) is INSPhotosViewController ) else { senderID = nil; return }
      messageRef.updateChildValues(["seen" : true, "status": messageStatusRead], withCompletionBlock: { (error, reference) in
        self.resetBadgeForSelf()
      })
    })
  }
  
  func updateMessageStatusUI(sentMessage: Message) {
    
    guard let index = self.messages.index(where: { (message) -> Bool in
      return message.messageUID == sentMessage.messageUID
    }) else { return }
    
    guard index >= 0 else { return }
    messages[index].status = sentMessage.status
    collectionView?.reloadItems(at: [IndexPath(row: index ,section: 0)])
    guard sentMessage.status == messageStatusDelivered, messages[index].messageUID == messages.last?.messageUID,
    UserDefaults.standard.bool(forKey: "In-AppSounds") else { return }
    SystemSoundID.playFileNamed(fileName: "sent", withExtenstion: "caf")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCollectionView()
    setRightBarButtonItem()
    setupTitleName()
    configurePlaceholderTitleView()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if self.navigationController?.visibleViewController is UserInfoTableViewController ||
      self.navigationController?.visibleViewController is GroupAdminControlsTableViewController ||
      topViewController(rootViewController: self) is CropViewController {
      return
    }

    if typingIndicatorReference != nil {
      typingIndicatorReference.removeObserver(withHandle: typingIndicatorHandle)
    }

    if userStatusReference != nil {
      userStatusReference.removeObserver(withHandle: userHandler)
    }
    
    if membersReference != nil && membersAddingHandle != nil {
      membersReference.removeObserver(withHandle: membersAddingHandle)
    }
    
    if membersReference != nil && membersRemovingHandle != nil {
      membersReference.removeObserver(withHandle: membersRemovingHandle)
    }
    
    if chatNameReference != nil && chatNameHandle != nil {
      chatNameReference.removeObserver(withHandle: chatNameHandle)
    }
    
    if chatAdminReference != nil && chatAdminHandle != nil {
      chatAdminReference.removeObserver(withHandle: chatAdminHandle)
    }
    
    for element in messageChangesHandles {
      let messageID = element.uid
      let messagesReference = Database.database().reference().child("messages").child(messageID)
      messagesReference.removeObserver(withHandle: element.handle)
    }
  
    if messagesFetcher != nil {
      if messagesFetcher.userMessagesReference != nil {
        messagesFetcher.userMessagesReference.removeAllObservers()
      }
      
      if messagesFetcher.messagesReference != nil {
        messagesFetcher.messagesReference.removeAllObservers()
      }
      messagesFetcher.cleanAllObservers()
      messagesFetcher.collectionDelegate = nil
      messagesFetcher.delegate = nil
      messagesFetcher = nil
    }
    isTyping = false
    
    guard voiceRecordingViewController != nil, voiceRecordingViewController.recorder != nil else { return }
    
    voiceRecordingViewController.stop()
    voiceRecordingViewController.deleteAllRecordings()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
    print("\n CHATLOG CONTROLLER DE INIT \n")
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    configureProgressBar()
    
    if inputContainerView.inputTextView.isFirstResponder {
      UIView.performWithoutAnimation {
        self.inputContainerView.inputTextView.resignFirstResponder()
      }
    }
  }

  func startCollectionViewAtBottom () { // start chat log at bottom for iOS 10
    let collectionViewInsets: CGFloat = (collectionView!.contentInset.bottom + collectionView!.contentInset.top )
    let contentSize = self.collectionView?.collectionViewLayout.collectionViewContentSize
    if Double(contentSize!.height) > Double(self.collectionView!.bounds.size.height) {
      let targetContentOffset = CGPoint(x: 0.0, y: contentSize!.height - (self.collectionView!.bounds.size.height - collectionViewInsets - inputContainerView.frame.height))
      self.collectionView?.contentOffset = targetContentOffset
    }
  }
  
  private var didLayoutFlag: Bool = false
  override func viewDidLayoutSubviews() { // start chat log at bottom for iOS 11
    super.viewDidLayoutSubviews()

    if #available(iOS 11.0, *) {
      guard let collectionView = collectionView, !didLayoutFlag else {
        return
    }

    if messages.count - 1 >= 0 {
      UIView.performWithoutAnimation {
        if collectionView.contentSize.height < collectionView.bounds.height  {
          collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        } else {
          let targetContentOffset = CGPoint(x: 0.0, y: collectionView.contentSize.height - (collectionView.bounds.size.height - 40 - inputContainerView.frame.height + 70))
          self.collectionView?.setContentOffset(targetContentOffset, animated: false)
        }
      }
    }
    didLayoutFlag = true
    }
  }
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    collectionView?.collectionViewLayout.invalidateLayout()
    DispatchQueue.main.async {
      self.inputContainerView.inputTextView.invalidateIntrinsicContentSize()
    }
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    collectionView?.collectionViewLayout.invalidateLayout()
    DispatchQueue.main.async {
      self.inputContainerView.attachedImages.frame.size.width = self.inputContainerView.inputTextView.frame.width
      self.collectionView?.reloadData()
      self.inputContainerView.invalidateIntrinsicContentSize()
    }
  }
  
  fileprivate func configureProgressBar() {
    
    guard navigationController?.navigationBar != nil else { return }
    guard !uploadProgressBar.isDescendant(of: navigationController!.navigationBar) else { return }

    navigationController?.navigationBar.addSubview(uploadProgressBar)
    uploadProgressBar.translatesAutoresizingMaskIntoConstraints = false
    uploadProgressBar.bottomAnchor.constraint(equalTo: navigationController!.navigationBar.bottomAnchor).isActive = true
    uploadProgressBar.leftAnchor.constraint(equalTo: navigationController!.navigationBar.leftAnchor).isActive = true
    uploadProgressBar.rightAnchor.constraint(equalTo: navigationController!.navigationBar.rightAnchor).isActive = true
  }
  
  fileprivate func setupCollectionView () {
    inputTextViewTapGestureRecognizer = UITapGestureRecognizer(target: inputContainerView.chatLogController, action: #selector(ChatLogController.toggleTextView))
    inputTextViewTapGestureRecognizer.delegate = inputContainerView
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    collectionView?.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    collectionView?.backgroundColor = view.backgroundColor
    collectionView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
    collectionView?.keyboardDismissMode = .interactive
    collectionView?.delaysContentTouches = false
    collectionView?.alwaysBounceVertical = true
    collectionView?.isPrefetchingEnabled = true
  
    if #available(iOS 11.0, *) {
      collectionView?.translatesAutoresizingMaskIntoConstraints = false
      extendedLayoutIncludesOpaqueBars = true
      automaticallyAdjustsScrollViewInsets = false
      navigationItem.largeTitleDisplayMode = .never
      
      collectionView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
      collectionView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
      collectionView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
      collectionView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant:  -inputContainerView.frame.height).isActive = true
    } else {
      collectionView?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - inputContainerView.frame.height  )
      automaticallyAdjustsScrollViewInsets = true
      extendedLayoutIncludesOpaqueBars = true
    }
    collectionView?.addSubview(refreshControl)
    collectionView?.register(IncomingTextMessageCell.self, forCellWithReuseIdentifier: incomingTextMessageCellID)
    collectionView?.register(OutgoingTextMessageCell.self, forCellWithReuseIdentifier: outgoingTextMessageCellID)
    collectionView?.register(TypingIndicatorCell.self, forCellWithReuseIdentifier: typingIndicatorCellID)
    collectionView?.register(PhotoMessageCell.self, forCellWithReuseIdentifier: photoMessageCellID)
    collectionView?.register(IncomingPhotoMessageCell.self, forCellWithReuseIdentifier: incomingPhotoMessageCellID)
    collectionView?.register(OutgoingVoiceMessageCell.self, forCellWithReuseIdentifier: outgoingVoiceMessageCellID)
    collectionView?.register(IncomingVoiceMessageCell.self, forCellWithReuseIdentifier: incomingVoiceMessageCellID)
    collectionView?.register(InformationMessageCell.self, forCellWithReuseIdentifier: informationMessageCellID)
    collectionView?.registerClass(revealableViewClass: TimestampView.self, forRevealableViewReuseIdentifier: "timestamp")
    
    configureRefreshControlInitialTintColor()
    configureCellContextMenuView()
  }
  
  @objc func keyboardDidHide(notification: NSNotification) {
    inputContainerView.inputTextView.inputView = nil
  }
  
  fileprivate func configureCellContextMenuView() {
    let config = FTConfiguration.shared
    config.textColor = .white
    config.backgoundTintColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
    config.borderColor = UIColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 0.0)
    config.menuWidth = 100
    config.menuSeparatorColor = ThemeManager.currentTheme().generalSubtitleColor
    config.textAlignment = .center
    config.textFont = UIFont.systemFont(ofSize: 14)
    config.menuRowHeight = 40
    config.cornerRadius = 25
  }
  
  fileprivate func configureRefreshControlInitialTintColor() { /* fixes bug of not setting refresh control tint color on initial refresh */
    collectionView?.contentOffset = CGPoint(x: 0, y: -refreshControl.frame.size.height)
    refreshControl.beginRefreshing()
    refreshControl.endRefreshing()
  }
  
  fileprivate var userHandler: UInt = 01
  fileprivate var onlineStatusInString:String?
  
  func setupTitleName() {
    guard let currentUserID = Auth.auth().currentUser?.uid, let toId = conversation?.chatID else { return }
    if currentUserID == toId {
      self.navigationItem.setTitle(title: NameConstants.personalStorage, subtitle: "")
    } else {
      self.navigationItem.setTitle(title: conversation?.chatName ?? "", subtitle: "")
    }
  }
  
  func configurePlaceholderTitleView() {
    
    if let isGroupChat = conversation?.isGroupChat, isGroupChat, let title = conversation?.chatName, let membersCount = conversation?.chatParticipantsIDs?.count {
      let subtitle = "\(membersCount) members"
      self.navigationItem.setTitle(title: title, subtitle: subtitle)
      return
    }
    
    guard let currentUserID = Auth.auth().currentUser?.uid, let toId = conversation?.chatID else { return }
    
    if currentUserID == toId {
      self.navigationItem.title = NameConstants.personalStorage
      return
    }
  
    guard let index = globalUsers.index(where: { (user) -> Bool in
      return user.id == conversation?.chatID
    }) else { return }
    let status = globalUsers[index].onlineStatus as AnyObject// else { return }
    onlineStatusInString = manageNavigationItemTitle(onlineStatusObject:  status)
  }
  
  func configureTitleViewWithOnlineStatus() {
    
    if let isGroupChat = conversation?.isGroupChat, isGroupChat, let title = conversation?.chatName, let membersCount = conversation?.chatParticipantsIDs?.count {
      let subtitle = "\(membersCount) members"
      navigationItem.setTitle(title: title, subtitle: subtitle)
      return
    }
  
    guard let currentUserID = Auth.auth().currentUser?.uid, let toId = conversation?.chatID else { return }
    
    if currentUserID == toId {
      navigationItem.title = NameConstants.personalStorage
      return
    }
  
    if userStatusReference != nil {
      userStatusReference.removeObserver(withHandle: userHandler)
    }
  
    userStatusReference = Database.database().reference().child("users").child(toId)
    userHandler = userStatusReference.observe(.value, with: { (snapshot) in
      guard snapshot.exists() else { return }
      
      let value = snapshot.value as? NSDictionary
      let status = value?["OnlineStatus"] as AnyObject
      self.onlineStatusInString = self.manageNavigationItemTitle(onlineStatusObject:  status)
    })
  }

  fileprivate func manageNavigationItemTitle(onlineStatusObject: AnyObject) -> String {
    
    guard let title = conversation?.chatName else { return "" }
    if let onlineStatusStringStamp = onlineStatusObject as? String {
      if onlineStatusStringStamp == statusOnline { // user online
        self.navigationItem.setTitle(title: title, subtitle: statusOnline)
        return statusOnline
      } else { // user got a timstamp converted to string (was in earlier versions of app)
        let date = Date(timeIntervalSince1970: TimeInterval(onlineStatusStringStamp)!)
        let subtitle = "Last seen " + timeAgoSinceDate(date)
        self.navigationItem.setTitle(title: title, subtitle: subtitle)
        return subtitle
      }
      
    } else if let onlineStatusTimeIntervalStamp = onlineStatusObject as? TimeInterval { //user got server timestamp in miliseconds
      let date = Date(timeIntervalSince1970: onlineStatusTimeIntervalStamp/1000)
      let subtitle = "Last seen " + timeAgoSinceDate(date)
      self.navigationItem.setTitle(title: title, subtitle: subtitle)
      return subtitle
    }
    return ""
  }
  
  
  func setRightBarButtonItem () {
    
    let infoButton = UIButton(type: .infoLight)
    infoButton.addTarget(self, action: #selector(getInfoAction), for: .touchUpInside)
    let infoBarButtonItem = UIBarButtonItem(customView: infoButton)

    guard let uid = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID, uid != conversationID  else { return }
      navigationItem.rightBarButtonItem = infoBarButtonItem
    if isCurrentUserMemberOfCurrentGroup() {
      navigationItem.rightBarButtonItem?.isEnabled = true
    } else {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
  }
 
  @objc func getInfoAction() {

    if let isGroupChat = conversation?.isGroupChat, isGroupChat {

      let destination = GroupAdminControlsTableViewController()
      destination.chatID = conversation?.chatID ?? ""
      if conversation?.admin != Auth.auth().currentUser?.uid {
        destination.adminControls = destination.defaultAdminControlls
      }
      self.navigationController?.pushViewController(destination, animated: true)
      // admin group info controller
    } else {
      // regular default chat info controller
      let destination = UserInfoTableViewController()
      destination.conversationID = conversation?.chatID ?? ""
      self.navigationController?.pushViewController(destination, animated: true)
    }
  }
  
  lazy var inputContainerView: ChatInputContainerView = {
    var chatInputContainerView = ChatInputContainerView()
    chatInputContainerView.chatLogController = self
    chatInputContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
    
    return chatInputContainerView
  }()
  
  lazy var inputBlockerContainerView: InputBlockerContainerView = {
    var inputBlockerContainerView = InputBlockerContainerView()
    let subviewsHeight = inputBlockerContainerView.subviewsHeight
    inputBlockerContainerView.configureHeight(superview: view)
    inputBlockerContainerView.backButton.addTarget(self, action: #selector(inputBlockerAction), for: .touchUpInside)
    
    return inputBlockerContainerView
  }()
  
  var refreshControl: UIRefreshControl = {
    var refreshControl = UIRefreshControl()
    refreshControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    refreshControl.tintColor = ThemeManager.currentTheme().generalTitleColor
    refreshControl.addTarget(self, action: #selector(performRefresh), for: .valueChanged)
    
    return refreshControl
  }()
  
  @objc func inputBlockerAction() {
    guard let chatID = conversation?.chatID else { return }
    navigationController?.popViewController(animated: true)
    deleteAndExitDelegate?.deleteAndExit(from: chatID)
  }
  
  var canRefresh = true
  var isScrollViewAtTheBottom = true
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    if collectionView!.contentOffset.y >= (collectionView!.contentSize.height - collectionView!.frame.size.height - 200) {
      isScrollViewAtTheBottom = true
    } else {
      isScrollViewAtTheBottom = false
    }
    
    if scrollView.contentOffset.y < 0 { //change 100 to whatever you want
      if collectionView!.contentSize.height < UIScreen.main.bounds.height - 50 {
        canRefresh = false
      }
      
      if canRefresh && !refreshControl.isRefreshing {
        canRefresh = false
        refreshControl.beginRefreshing()
        performRefresh()
      }
    } else if scrollView.contentOffset.y >= 0 {
      canRefresh = true
    }
  }
  
  @objc func performRefresh () {
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      loadPreviousMessages(isGroupChat: true)
    } else {
      loadPreviousMessages(isGroupChat: false)
    }
  }
  
  override var inputAccessoryView: UIView? {
    get {
      if let membersIDs = conversation?.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid)  {
         return inputContainerView
      }
      return inputBlockerContainerView
    }
  }
  
  override var canBecomeFirstResponder : Bool {
    return true
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if section == 0 {
      return messages.count
    } else {
      return 1
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard indexPath.section == 0 else { return showTypingIndicator(indexPath: indexPath)! as! TypingIndicatorCell }
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      return selectCell(for: indexPath, isGroupChat: true)!
    } else {
      return selectCell(for: indexPath, isGroupChat: false)!
    }
  }

  fileprivate func showTypingIndicator(indexPath: IndexPath) -> UICollectionViewCell? {
    let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: typingIndicatorCellID, for: indexPath) as! TypingIndicatorCell
    guard let gifURL = ThemeManager.currentTheme().typingIndicatorURL else { return nil }
    guard let gifData = NSData(contentsOf: gifURL) else { return nil }
    cell.typingIndicator.animatedImage = FLAnimatedImage(animatedGIFData: gifData as Data)
    return cell
  }

  fileprivate func selectCell(for indexPath: IndexPath, isGroupChat: Bool) -> RevealableCollectionViewCell? {
    
    let message = messages[indexPath.item]
    let isTextMessage = message.text != nil
    let isPhotoVideoMessage = message.imageUrl != nil || message.localImage != nil
    let isVoiceMessage = message.voiceEncodedString != nil
    let isOutgoingMessage = message.fromId == Auth.auth().currentUser?.uid
    let isInformationMessage = message.isInformationMessage ?? false

    if isInformationMessage {
      let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: informationMessageCellID, for: indexPath) as! InformationMessageCell
      cell.setupData(message: message)
      return cell
    } else
    
    if isTextMessage {
      switch isOutgoingMessage {
      case true:
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: outgoingTextMessageCellID, for: indexPath) as! OutgoingTextMessageCell
        cell.chatLogController = self
        cell.setupData(message: message)
        DispatchQueue.global(qos: .background).async {
          cell.configureDeliveryStatus(at: indexPath, lastMessageIndex: self.messages.count-1, message: message)
        }
      
        return cell
      case false:
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingTextMessageCellID, for: indexPath) as! IncomingTextMessageCell
        cell.chatLogController = self
        cell.setupData(message: message, isGroupChat: isGroupChat)
        return cell
      }
    } else
    
    if isPhotoVideoMessage {
      switch isOutgoingMessage {
      case true:
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: photoMessageCellID, for: indexPath) as! PhotoMessageCell
        cell.chatLogController = self
        cell.setupData(message: message)
        if let image = message.localImage {
          cell.setupImageFromLocalData(message: message, image: image)
          DispatchQueue.global(qos: .background).async {
            cell.configureDeliveryStatus(at: indexPath, lastMessageIndex: self.messages.count-1, message: message)
          }
          return cell
        }
        if let messageImageUrl = message.imageUrl {
          cell.setupImageFromURL(message: message, messageImageUrl: URL(string: messageImageUrl)!)
          DispatchQueue.global(qos: .background).async {
            cell.configureDeliveryStatus(at: indexPath, lastMessageIndex: self.messages.count-1, message: message)
          }
          return cell
        }
        break
      case false:
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingPhotoMessageCellID, for: indexPath) as! IncomingPhotoMessageCell
        cell.chatLogController = self
        cell.setupData(message: message, isGroupChat: isGroupChat)
        if let image = message.localImage {
          cell.setupImageFromLocalData(message: message, image: image)
          return cell
        }
        if let messageImageUrl = message.imageUrl {
          cell.setupImageFromURL(message: message, messageImageUrl: URL(string: messageImageUrl)!)
          return cell
        }
        break
      }
    } else 
    
    if isVoiceMessage {
      switch isOutgoingMessage {
      case true:
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: outgoingVoiceMessageCellID, for: indexPath) as! OutgoingVoiceMessageCell
        cell.chatLogController = self
        cell.setupData(message: message)
        DispatchQueue.global(qos: .background).async {
          cell.configureDeliveryStatus(at: indexPath, lastMessageIndex: self.messages.count-1, message: message)
        }
        return cell
      case false:
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingVoiceMessageCellID, for: indexPath) as! IncomingVoiceMessageCell
        cell.chatLogController = self
        cell.setupData(message: message, isGroupChat: isGroupChat)
        return cell
      }
    }
    return nil
  }

  override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

    if let cell = cell as? OutgoingVoiceMessageCell {
      guard cell.isSelected, chatLogAudioPlayer != nil else { return }
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
      do {
        try AVAudioSession.sharedInstance().setActive(false)
      } catch {}
    } else if let cell = cell as? IncomingVoiceMessageCell {
      guard cell.isSelected, chatLogAudioPlayer != nil else { return }
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
      do {
        try AVAudioSession.sharedInstance().setActive(false)
      } catch {}
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseVoiceMessageCell, chatLogAudioPlayer != nil else { return }
    chatLogAudioPlayer.stop()
    cell.playerView.resetTimer()
    cell.playerView.play.isSelected = false
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {}
  }
    
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    let message = messages[indexPath.item]
    guard let voiceEncodedString = message.voiceEncodedString else { return }
    guard let data = Data(base64Encoded: voiceEncodedString) else { return }
    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseVoiceMessageCell else { return }
    let isAlreadyPlaying = chatLogAudioPlayer != nil && chatLogAudioPlayer.isPlaying
    
    guard !isAlreadyPlaying else {
      chatLogAudioPlayer.stop()
      cell.playerView.resetTimer()
      cell.playerView.play.isSelected = false
      do {
        try AVAudioSession.sharedInstance().setActive(false)
      } catch {}
      return
    }
    
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {}
    do {
      chatLogAudioPlayer = try AVAudioPlayer(data:  data)
      chatLogAudioPlayer.prepareToPlay()
      chatLogAudioPlayer.volume = 1.0
      chatLogAudioPlayer.play()
      cell.playerView.runTimer()
      cell.playerView.play.isSelected = true
    } catch {
      chatLogAudioPlayer = nil
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return selectSize(indexPath: indexPath)
  }

  func selectSize(indexPath: IndexPath) -> CGSize  {
   
    guard indexPath.section == 0 else {  return CGSize(width: self.collectionView!.frame.width, height: 40) }
    var cellHeight: CGFloat = 80
    let message = messages[indexPath.row]
    let isTextMessage = message.text != nil
    let isPhotoVideoMessage = message.imageUrl != nil || message.localImage != nil
    let isVoiceMessage = message.voiceEncodedString != nil
    let isOutgoingMessage = message.fromId == Auth.auth().currentUser?.uid
    let isInformationMessage = message.isInformationMessage ?? false
    let isGroupChat = conversation!.isGroupChat ?? false
   
    guard !isInformationMessage else {
      guard let infoMessageWidth = self.collectionView?.frame.width, let messageText = message.text else { return CGSize(width: 0, height: 0 ) }
      let infoMessageHeight = messagesFetcher.estimateFrameForText(width: infoMessageWidth, text: messageText, font: MessageFontsAppearance.defaultInformationMessageTextFont).height + 10
      return CGSize(width: infoMessageWidth, height: infoMessageHeight)
    }
   
    if isTextMessage {
      if let isInfoMessage = message.isInformationMessage, isInfoMessage {
        return CGSize(width: self.collectionView!.frame.width, height: 25)
      }
      
      if isGroupChat, !isOutgoingMessage {
        cellHeight = message.estimatedFrameForText!.height + BaseMessageCell.groupTextMessageInsets
      } else {
        cellHeight = message.estimatedFrameForText!.height + BaseMessageCell.defaultTextMessageInsets
      }
    } else
    
    if isPhotoVideoMessage {
      if CGFloat(truncating: message.imageCellHeight!) < BaseMessageCell.minimumMediaCellHeight {
        if isGroupChat, !isOutgoingMessage {
          cellHeight = BaseMessageCell.incomingGroupMinimumMediaCellHeight
        } else {
          cellHeight = BaseMessageCell.minimumMediaCellHeight
        }
      } else {
        if isGroupChat, !isOutgoingMessage {
          cellHeight = CGFloat(truncating: message.imageCellHeight!) + BaseMessageCell.incomingGroupMessageAuthorNameLabelHeightWithInsets
        } else {
          cellHeight = CGFloat(truncating: message.imageCellHeight!)
        }
      }
    } else
    
    if isVoiceMessage {
      if isGroupChat, !isOutgoingMessage {
        cellHeight = BaseMessageCell.groupIncomingVoiceMessageHeight
      } else {
        cellHeight = BaseMessageCell.defaultVoiceMessageHeight
      }
    }
    
    return CGSize(width: self.collectionView!.frame.width, height: cellHeight)
  }
  
  @objc func handleSend() {
    
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: "No internet", message: noInternetError, controller: self)
      return
    }
    inputContainerView.inputTextView.isScrollEnabled = false
    inputContainerView.invalidateIntrinsicContentSize()
    inputContainerView.sendButton.isEnabled = false
    isTyping = false
    inputContainerView.placeholderLabel.isHidden = false
    
    let text = inputContainerView.inputTextView.text ?? ""
    
    inputContainerView.inputTextView.text = nil
    
    if text != "" {
      let properties = ["text": text]
      handleMediaMessageSending(textMessageProperties: properties as [String : AnyObject])
    } else {
      handleMediaMessageSending(textMessageProperties: nil)
    }
  }
  
  func handleMediaMessageSending(textMessageProperties: [String : AnyObject]?) {
    
    let textMessageIDReference = Database.database().reference().child("messages")
    let childtextMessageIDReference = textMessageIDReference.childByAutoId()
    
    guard !inputContainerView.selectedMedia.isEmpty else {
      if let unwrappedTextMessageProperties = textMessageProperties {
        sendMessageWithProperties(unwrappedTextMessageProperties, updateLocaly: true, updateRemotely: true, childRef: childtextMessageIDReference)
      }
      return
    }
    
    if let unwrappedTextMessageProperties = textMessageProperties {
      sendMessageWithProperties(unwrappedTextMessageProperties, updateLocaly: true, updateRemotely: false, childRef: childtextMessageIDReference)
    }

    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    
    let selectedMedia = inputContainerView.selectedMedia
    
    if mediaPickerController != nil, let selected = mediaPickerController.collectionView.indexPathsForSelectedItems {
      for indexPath in selected  { mediaPickerController.collectionView.deselectItem(at: indexPath, animated: false) }
    }

    inputContainerView.selectedMedia.removeAll()
    inputContainerView.attachedImages.reloadData()
    inputContainerView.resetChatInputConntainerViewSettings()

    var mediaToUpload = CGFloat()
    var progressArray = [(objectID: String, progress: Double)]()
    var mediaMessageObjectsToSend = [(properties: [String:AnyObject], childRef: DatabaseReference)]()
    let uploadMediaGroup = DispatchGroup()

    for mediaObject in selectedMedia {
      uploadMediaGroup.enter()
      let isVideoMessage = mediaObject.phAsset?.mediaType == PHAssetMediaType.video
      guard isVideoMessage else { mediaToUpload += 1; continue }
      mediaToUpload += 2
    }
    
    uploadMediaGroup.notify(queue: DispatchQueue.main, execute: {
      if let unwrappedTextMessageProperties = textMessageProperties {
        self.sendMessageWithProperties(unwrappedTextMessageProperties, updateLocaly: false, updateRemotely: true, childRef: childtextMessageIDReference)
      }

      mediaMessageObjectsToSend.forEach({ (element) in
        self.sendMediaMessageWithProperties(element.properties, childRef: element.childRef)
      })
    })
    
    let defaultMessageStatus = messageStatusDelivered
    
    for selectedMedia in selectedMedia {
      
      let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
      let ref = Database.database().reference().child("messages")
      let childRef = ref.childByAutoId()
      
      let isVoiceMessage = selectedMedia.audioObject != nil
      let isPhotoMessage = (selectedMedia.phAsset?.mediaType == PHAssetMediaType.image || selectedMedia.phAsset == nil) && selectedMedia.audioObject == nil
      let isVideoMessage = selectedMedia.phAsset?.mediaType == PHAssetMediaType.video
 
      
      if isVoiceMessage {
        let bae64string = selectedMedia.audioObject?.base64EncodedString()
        let properties: [String: AnyObject] = ["voiceEncodedString": bae64string as AnyObject]
        let values: [String: AnyObject] = ["messageUID": childRef.key as AnyObject, "toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "voiceEncodedString": bae64string as AnyObject]
        
        reloadCollectionViewAfterSending(values: values)
        mediaMessageObjectsToSend.append((properties: properties, childRef: childRef))
        uploadMediaGroup.leave()

        let id = childRef.key
        progressArray = setProgressForElement(progress: 1.0, id: id, array: progressArray)
        updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)

      } else
      
      if isPhotoMessage {
        let id = childRef.key
        let values: [String: AnyObject] = ["messageUID": childRef.key as AnyObject, "toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "localImage": selectedMedia.object!.asUIImage!, "imageWidth":selectedMedia.object!.asUIImage!.size.width as AnyObject, "imageHeight": selectedMedia.object!.asUIImage!.size.height as AnyObject]
        
        reloadCollectionViewAfterSending(values: values)
        uploadToFirebaseStorageUsingImage(selectedMedia.object!.asUIImage!, progress: { (snapshot) in
          if let progressCount = snapshot?.progress?.fractionCompleted {
            progressArray = self.setProgressForElement(progress: progressCount*0.98, id: id, array: progressArray)
            self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
          }
        }) { (imageURL) in
          progressArray = self.setProgressForElement(progress: 1.0, id: id, array: progressArray)
          self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
          let image = selectedMedia.object!.asUIImage!
          let properties: [String: AnyObject] = ["imageUrl": imageURL as AnyObject, "imageWidth": image.size.width as AnyObject, "imageHeight": image.size.height as AnyObject]
          mediaMessageObjectsToSend.append((properties: properties, childRef: childRef))
          uploadMediaGroup.leave()
        }
      } else
      
      if isVideoMessage {

        guard let path = selectedMedia.fileURL else { return }
        let videoId = childRef.key
        let imageId = childRef.key + "image"
        let valuesForVideo: [String: AnyObject] = ["messageUID": childRef.key as AnyObject, "toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "localImage": selectedMedia.object!.asUIImage!, "imageWidth":selectedMedia.object!.asUIImage!.size.width as AnyObject, "imageHeight": selectedMedia.object!.asUIImage!.size.height as AnyObject, "localVideoUrl" : path as AnyObject]
        
        reloadCollectionViewAfterSending(values: valuesForVideo)
        uploadToFirebaseStorageUsingVideo(selectedMedia.videoObject!, progress: {[unowned self] (snapshot) in
          if let progressCount = snapshot?.progress?.fractionCompleted {
            progressArray = self.setProgressForElement(progress: progressCount*0.98, id: videoId, array: progressArray)
            self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
          }
        }) { (videoURL) in
          progressArray = self.setProgressForElement(progress: 1.0, id: videoId, array: progressArray)
          self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
          
          self.uploadToFirebaseStorageUsingImage(selectedMedia.object!.asUIImage!, progress: { [unowned self] (snapshot) in
        
            if let progressCount = snapshot?.progress?.fractionCompleted {
              progressArray = self.setProgressForElement(progress: progressCount*0.98, id: imageId, array: progressArray)
              self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
            }
            
          }, completion: { (imageUrl) in
            progressArray = self.setProgressForElement(progress: 1.0, id: imageId, array: progressArray)
            self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
            let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": selectedMedia.object!.asUIImage?.size.width as AnyObject, "imageHeight": selectedMedia.object!.asUIImage?.size.height as AnyObject, "videoUrl": videoURL as AnyObject]
             mediaMessageObjectsToSend.append((properties: properties, childRef: childRef))
             uploadMediaGroup.leave()
          })
        }
      }
    }
  }
  
  func setProgressForElement(progress: Double, id: String, array: [(objectID: String, progress: Double)]) -> [(objectID: String, progress: Double)] {
    var array = array
    guard let index = array.index(where: { (element) -> Bool in
      return element.objectID == id
    }) else {
       array.insert((objectID: id, progress: progress), at: 0)
      return array
    }
    array[index].progress = progress
    return array
  }

  fileprivate func updateProgressBar(array: [(objectID: String, progress: Double)] , totalUploadsCount: CGFloat) {
    guard uploadProgressBar.progress < 1.0 else { return }
    
    let totalProgressArray = array.map({$0.progress})
    let completedUploadsCount = totalProgressArray.reduce(0, +)

    print(completedUploadsCount/Double(totalUploadsCount))
    let progress = completedUploadsCount/Double(totalUploadsCount)
  
    
    uploadProgressBar.setProgress(Float(progress), animated: true)
    if progress >= 0.99999 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
        self.uploadProgressBar.setProgress(0.0, animated: false)
      })
    }
  }

  func sendMediaMessageWithProperties(_ properties: [String: AnyObject], childRef: DatabaseReference) {
    
    let defaultMessageStatus = messageStatusDelivered
    
    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    
    var values: [String: AnyObject] = ["messageUID": childRef.key as AnyObject, "toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp]
    
    properties.forEach({values[$0] = $1})
    updateConversationsData(childRef: childRef, values: values, toId: toId, fromId: fromId)
  }

  fileprivate func uploadToFirebaseStorageUsingImage(_ image: UIImage, progress: ((_ progress: StorageTaskSnapshot?) -> Void)? = nil, completion: @escaping (_ imageUrl: String) -> ()) {
    let imageName = UUID().uuidString
    let ref = Storage.storage().reference().child("messageImages").child(imageName)
    
    guard let uploadData = UIImageJPEGRepresentation(image, 1) else { return }
    let uploadTask = ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
      guard error == nil else { return }

      ref.downloadURL(completion: { (url, error) in
        guard error == nil, let imageURL = url else { completion(""); return }
        completion(imageURL.absoluteString)
      })
    })
    uploadTask.observe(.progress) { (progressSnap) in
      progress!(progressSnap)
    }
  }
  
  fileprivate func uploadToFirebaseStorageUsingVideo(_ uploadData: Data, progress: ((_ progress: StorageTaskSnapshot?) -> Void)? = nil, completion: @escaping (_ videoUrl: String) -> ()) {
    
    let videoName = UUID().uuidString + ".mov"
    let ref = Storage.storage().reference().child("messageMovies").child(videoName)
    
    let uploadTask = ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
      guard error == nil else { return }
      ref.downloadURL(completion: { (url, error) in
        guard error == nil, let videoURL = url else { completion(""); return }
        completion(videoURL.absoluteString)
      })
    })
    uploadTask.observe(.progress) { (progressSnap) in
      progress!(progressSnap)
    }
  }
  
  fileprivate func reloadCollectionViewAfterSending(values: [String: AnyObject]) {
    
     var values = values
    
     if let isGroupChat = conversation?.isGroupChat, isGroupChat {
       values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
     } else {
       values = messagesFetcher.preloadCellData(to: values, isGroupChat: true)
     }
    
    let message = Message(dictionary: values)
    messages.append(message)
    let latMessageIndexPath = IndexPath(item: messages.count - 1, section: 0)
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      messages = messagesFetcher.configureMessageTails(messages: messages, isGroupChat: true)
    } else {
      messages = messagesFetcher.configureMessageTails(messages: messages, isGroupChat: false)
    }
    
    messages[latMessageIndexPath.item].status = messageStatusSending
    UIView.performWithoutAnimation {
      collectionView?.insertItems(at: [latMessageIndexPath])
      let indexPath1 = IndexPath(item: messages.count - 1, section: 0)
      DispatchQueue.main.async {
        self.collectionView?.scrollToItem(at: indexPath1, at: .bottom, animated: true)
      }
    
      var indexPaths = [IndexPath]()
      for index in 2..<10 {
        if messages.indices.contains(messages.count-index) {
          let indexPath = IndexPath(item: messages.count-index, section: 0)
          indexPaths.append(indexPath)
        }
      }
      collectionView?.reloadItems(at: indexPaths)
    }
  }
  
  fileprivate func sendMessageWithProperties(_ properties: [String: AnyObject], updateLocaly:Bool, updateRemotely:Bool, childRef: DatabaseReference ) {

    let defaultMessageStatus = messageStatusDelivered
    
    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    var values: [String: AnyObject] = ["messageUID": childRef.key as AnyObject, "toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp]
    
    properties.forEach({values[$0] = $1})
    
    if updateLocaly && updateRemotely {
      reloadCollectionViewAfterSending(values: values)
      updateConversationsData(childRef: childRef, values: values, toId: toId, fromId: fromId)
    } else if updateLocaly && !updateRemotely {
      reloadCollectionViewAfterSending(values: values)
    } else if !updateLocaly && updateRemotely {
      updateConversationsData(childRef: childRef, values: values, toId: toId, fromId: fromId)
    }
  }
  
  fileprivate func updateConversationsData(childRef: DatabaseReference, values: [String: AnyObject], toId: String, fromId: String ) {
    
    childRef.updateChildValues(values) { (error, ref) in
      guard error == nil else { return }
      let messageId = childRef.key
      
      if let isGroupChat = self.conversation?.isGroupChat, isGroupChat {
        
        let groupMessagesRef = Database.database().reference().child("groupChats").child(toId).child(userMessagesFirebaseFolder)
        groupMessagesRef.updateChildValues([messageId: fromId])
      
        // needed to update ui for current user as fast as possible
        //for other members this update handled by backend
        let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(userMessagesFirebaseFolder)
        userMessagesRef.updateChildValues([messageId: fromId])
      
       // incrementing badge for group chats handled by backend, to reduce number of write operations from device

      } else {
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(userMessagesFirebaseFolder)
        userMessagesRef.updateChildValues([messageId: fromId])
        
        let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId).child(userMessagesFirebaseFolder)
        recipientUserMessagesRef.updateChildValues([messageId: fromId])
  
        self.incrementBadgeForDefaultChat()
      }
      self.updateLastMessageForMembers()
    }
  }
  
  func incrementBadgeForDefaultChat() {
    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid, toId != fromId else { return }
    runTransaction(firstChild: toId, secondChild: fromId)
  }
  
  func resetBadgeForSelf() {
    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    let badgeRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(messageMetaDataFirebaseFolder).child("badge")
    badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
      var value = mutableData.value as? Int
      value = 0
      mutableData.value = value!
      return TransactionResult.success(withValue: mutableData)
    })
  }
  
  func updateLastMessageForMembers() {
    
    guard let fromID = Auth.auth().currentUser?.uid,let conversationID = conversation?.chatID else { return }
    let isGroupChat = conversation?.isGroupChat ?? false
    
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
    
      // updates only for current user
      // for other users this update handled by Backend to reduce write operations on device
      
      let lastMessageQRef = Database.database().reference().child("user-messages").child(fromID).child(conversationID).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(1))
      lastMessageQRef.observeSingleEvent(of: .childAdded) { (snapshot) in
        let ref = Database.database().reference().child("user-messages").child(fromID).child(conversationID).child(messageMetaDataFirebaseFolder)
        let childValues: [String: Any] = ["lastMessageID": snapshot.key]
        ref.updateChildValues(childValues)
      }
    } else {
      guard let toID = conversation?.chatID, let uID = Auth.auth().currentUser?.uid else { return }
      let lastMessageQORef = Database.database().reference().child("user-messages").child(uID).child(toID).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(1))
      lastMessageQORef.observeSingleEvent(of: .childAdded) { (snapshot) in
        let ref = Database.database().reference().child("user-messages").child(uID).child(toID).child(messageMetaDataFirebaseFolder)
        let childValues: [String: Any] = ["chatID": toID, "lastMessageID": snapshot.key, "isGroupChat": isGroupChat/*, "chatParticipantsIDs": participantsIDs*/]
        ref.updateChildValues(childValues)
      }
      
      let lastMessageQIRef = Database.database().reference().child("user-messages").child(toID).child(uID).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(1))
      lastMessageQIRef.observeSingleEvent(of: .childAdded) { (snapshot) in
        let ref = Database.database().reference().child("user-messages").child(toID).child(uID).child(messageMetaDataFirebaseFolder)
        let childValues: [String: Any] = ["chatID": uID, "lastMessageID": snapshot.key, "isGroupChat": isGroupChat/*, "chatParticipantsIDs": participantsIDs*/]
        ref.updateChildValues(childValues)
      }
    }
  }
}
