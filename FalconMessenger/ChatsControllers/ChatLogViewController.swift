//
//  ChatLogViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos
import AudioToolbox
import CropViewController
import SafariServices

protocol DeleteAndExitDelegate: class {
  func deleteAndExit(from conversationID: String)
}

class ChatLogViewController: UIViewController {
  
  let incomingTextMessageCellID = "incomingTextMessageCellID"
  let outgoingTextMessageCellID = "outgoingTextMessageCellID"
  let typingIndicatorCellID = "typingIndicatorCellID"
  let photoMessageCellID = "photoMessageCellID"
  let outgoingVoiceMessageCellID = "outgoingVoiceMessageCellID"
  let incomingVoiceMessageCellID = "incomingVoiceMessageCellID"
  let typingIndicatorDatabaseID = "typingIndicator"
  let incomingPhotoMessageCellID = "incomingPhotoMessageCellID"
  let informationMessageCellID = "informationMessageCellID"
  let typingIndicatorStateDatabaseKeyID = "Is typing"
  
  weak var deleteAndExitDelegate: DeleteAndExitDelegate?
  
  var messagesFetcher: MessagesFetcher?
  let chatLogHistoryFetcher = ChatLogHistoryFetcher()
  let userBlockingManager = UserBlockingManager()
  let groupMembersManager = GroupMembersManager()

  var typingIndicatorReference: DatabaseReference!
  var typingIndicatorHandle: DatabaseHandle!
  var userStatusReference: DatabaseReference!
  var messageChangesHandles = [(uid: String, handle: DatabaseHandle)]()
  
  var currentUserBanReference: DatabaseReference!
  var currentUserBanAddedHandle: DatabaseHandle!
  var currentUserBanChangedHandle: DatabaseHandle!
  
  var companionBanReference: DatabaseReference!
  var companionBanAddedHandle: DatabaseHandle!
  var companionBanChangedHandle: DatabaseHandle!
  
  var conversation: Conversation?
  var messages = [Message]()
  var groupedMessages = [[Message]]()
  var typingIndicatorSection: [String] = []

  var chatLogAudioPlayer: AVAudioPlayer!
  var uploadProgressBar = UIProgressView(progressViewStyle: .bar)

  private var shouldScrollToBottom: Bool = true
  private let keyboardLayoutGuide = KeyboardLayoutGuide()
  private let messagesToLoad = 50
  
  lazy var collectionView: ChatCollectionView = {
    let collectionView = ChatCollectionView()
    return collectionView
  }()
  
  lazy var inputContainerView: InputContainerView = {
    var chatInputContainerView = InputContainerView()
    chatInputContainerView.chatLogController = self
    
    return chatInputContainerView
  }()

  lazy var inputBlockerContainerView: InputBlockerContainerView = {
    var inputBlockerContainerView = InputBlockerContainerView()
    inputBlockerContainerView.backButton.addTarget(self, action: #selector(inputBlockerAction), for: .touchUpInside)

    return inputBlockerContainerView
  }()
  
  lazy var unblockContainerView: UnblockContainerView = {
    var unblockContainerView = UnblockContainerView()
    unblockContainerView.backButton.addTarget(self, action: #selector(unblock), for: .touchUpInside)
    
    return unblockContainerView
  }()
  
  lazy var userBlockedContainerView: UserBlockedContainerView = {
    var userBlockedContainerView = UserBlockedContainerView()

    return userBlockedContainerView
  }()
  
  lazy var bottomScrollConainer: BottomScrollConainer = {
    var bottomScrollConainer = BottomScrollConainer()
    bottomScrollConainer.scrollButton.addTarget(self, action: #selector(instantMoveToBottom), for: .touchUpInside)
    bottomScrollConainer.isHidden = true
    return bottomScrollConainer
  }()
  
  @objc private func instantMoveToBottom() {
    collectionView.scrollToBottom(animated: true)
  }
  
  lazy var refreshControl: UIRefreshControl = {
    var refreshControl = UIRefreshControl()
    refreshControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    refreshControl.tintColor = ThemeManager.currentTheme().generalTitleColor
    refreshControl.addTarget(self, action: #selector(performRefresh), for: .valueChanged)
    
    return refreshControl
  }()

  /* fixes bug of not setting refresh control tint color on initial refresh */
  fileprivate func configureRefreshControlInitialTintColor() {
    collectionView.contentOffset = CGPoint(x: 0, y: -refreshControl.frame.size.height)
    refreshControl.beginRefreshing()
    refreshControl.endRefreshing()
  }
  
  @objc func performRefresh() {
    guard let conversation = self.conversation else { return }
    
    if let isGroupChat = conversation.isGroupChat.value, isGroupChat {
      chatLogHistoryFetcher.loadPreviousMessages(messages, conversation, messagesToLoad, true)
    } else {
      chatLogHistoryFetcher.loadPreviousMessages(messages, conversation, messagesToLoad, false)
    }
  }
  
  private var collectionViewLoaded = false {
    didSet {
      if collectionViewLoaded && shouldScrollToBottom && !oldValue {
        collectionView.scrollToBottom(animated: false)
      }
    }
  }
  
  // MARK: - Lifecycle
  
  override func loadView() {
    super.loadView()
    loadViews()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCollectionView()
    setupInputView()
    setRightBarButtonItem()
    setupTitleName()
    configurePlaceholderTitleView()
    setupBottomScrollButton()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(keyboardWillShow(_:)),
																					 name: UIResponder.keyboardWillShowNotification,
                                           object: nil)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    configureProgressBar()
    unblockInputViewConstraints()
    if savedContentOffset != nil {
      UIView.performWithoutAnimation {
        self.view.layoutIfNeeded()
        self.collectionView.contentOffset = self.savedContentOffset
      }
    }
   
    if collectionView.numberOfSections == groupedMessages.count + 1 {
      guard let cell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: groupedMessages.count)) as? TypingIndicatorCell else { return }
      cell.restart()
    }
  }

  private var savedContentOffset: CGPoint!
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    savedContentOffset = collectionView.contentOffset
    blockInputViewConstraints()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    if self.navigationController?.visibleViewController is UserInfoTableViewController ||
      self.navigationController?.visibleViewController is GroupAdminControlsTableViewController ||
      self.navigationController?.visibleViewController is OtherReportController ||
			self.navigationController?.visibleViewController is SharedMediaController ||
      UIApplication.topViewController() is CropViewController ||
      UIApplication.topViewController() is SFSafariViewController {
      return
    }
    print("did dissappear")
    isTyping = false
    if typingIndicatorReference != nil {
      typingIndicatorReference.removeObserver(withHandle: typingIndicatorHandle)
    }

    if userStatusReference != nil {
      userStatusReference.removeObserver(withHandle: userHandler)
    }

    groupMembersManager.removeAllObservers()

    removeBanObservers()
		// MARK: - DATABASE REMOVING OBSERVERS // TO MOVE
    for element in messageChangesHandles {
      let messageID = element.uid
      let messagesReference = Database.database().reference().child("messages").child(messageID)
      messagesReference.removeObserver(withHandle: element.handle)
    }

    if let messagesFetcher = messagesFetcher {
      if messagesFetcher.userMessagesReference != nil {
        messagesFetcher.userMessagesReference.removeAllObservers()
      }
      
      if messagesFetcher.messagesReference != nil {
        messagesFetcher.messagesReference.removeAllObservers()
      }
      messagesFetcher.cleanAllObservers()
      messagesFetcher.collectionDelegate = nil
      messagesFetcher.delegate = nil
    }
     inputContainerView.recordVoiceButton.reset()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
    print("\n CHATLOG CONTROLLER DE INIT \n")
  }

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {

		//TODO content offset fix
		//TODO inputContainerView height fix

		DispatchQueue.main.async { [weak self] in
			self?.collectionView.reloadData()
		}
		
		inputContainerView.handleRotation()
		collectionView.collectionViewLayout.invalidateLayout()
		super.traitCollectionDidChange(previousTraitCollection)
	}

  override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    if let observedObject = object as? ChatCollectionView, observedObject == collectionView {
      collectionViewLoaded = true
      collectionView.removeObserver(self, forKeyPath: "contentSize")
    }
  }
  
  // MARK: - Setup

  private func loadViews() {
    let view = ChatLogContainerView()
    view.backgroundView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    view.add(collectionView)

    if let membersIDs = conversation?.chatParticipantsIDs,
      let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
        view.add(inputContainerView)
    } else {
      view.add(inputBlockerContainerView)
    }
    self.view = view
  }

  func reloadInputView(view: UIView) {
    if let currentView = self.view as? ChatLogContainerView {
      DispatchQueue.main.async {
        currentView.add(view)
      }
    }
  }

  func blockInputViewConstraints() {
    guard let view = view as? ChatLogContainerView else { return }
    if let constant = keyboardLayoutGuide.topConstant {
      print(constant)
      if inputContainerView.inputTextView.isFirstResponder ||
        inputContainerView.attachButton.isFirstResponder ||
        inputContainerView.recordVoiceButton.isFirstResponder {
        view.blockBottomConstraint(constant: -constant)
        view.layoutIfNeeded()
      }
    }
  }

  func unblockInputViewConstraints() {
    guard let view = view as? ChatLogContainerView else { return }
    view.unblockBottomConstraint()
  }

  private func setupInputView() {
    guard let view = view as? ChatLogContainerView else {
      fatalError("Root view is not ChatLogContainerView")
    }
    view.addLayoutGuide(keyboardLayoutGuide)
    view.inputViewContainer.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor).isActive = true
  }

  private func addIPadCloseButton() {
    let leftBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeChatLog))
    navigationItem.leftBarButtonItem = leftBarButton
  }

  @objc func closeChatLog() {
    splitViewController?.showDetailViewController(SplitPlaceholderViewController(), sender: self)
    chatLogPresenter.deallocate()
  }

  private func setupBottomScrollButton() {
    view.addSubview(bottomScrollConainer)
    bottomScrollConainer.translatesAutoresizingMaskIntoConstraints = false
    bottomScrollConainer.widthAnchor.constraint(equalToConstant: 45).isActive = true
    bottomScrollConainer.heightAnchor.constraint(equalToConstant: 45).isActive = true

    guard let view = view as? ChatLogContainerView else {
      fatalError("Root view is not ChatLogContainerView")
    }

    bottomScrollConainer.rightAnchor.constraint(equalTo: view.inputViewContainer.rightAnchor,
                                                constant: -10).isActive = true
    bottomScrollConainer.bottomAnchor.constraint(equalTo: view.inputViewContainer.topAnchor,
                                                 constant: -10).isActive = true
  }
  
  private func setupCollectionView() {
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.bottom
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor

    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .never
    }

    if traitCollection.forceTouchCapability == .available {
      registerForPreviewing(with: self, sourceView: collectionView)
    }

    collectionView.delegate = self
    collectionView.dataSource = self
    chatLogHistoryFetcher.delegate = self
    groupMembersManager.delegate = self
    groupMembersManager.observeMembersChanges(conversation)

    if DeviceType.isIPad {
      addIPadCloseButton()
    }

    collectionView.addObserver(self, forKeyPath: "contentSize", options: .old, context: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    collectionView.addSubview(refreshControl)
    collectionView.register(IncomingTextMessageCell.self, forCellWithReuseIdentifier: incomingTextMessageCellID)
    collectionView.register(OutgoingTextMessageCell.self, forCellWithReuseIdentifier: outgoingTextMessageCellID)
    collectionView.register(TypingIndicatorCell.self, forCellWithReuseIdentifier: typingIndicatorCellID)
    collectionView.register(PhotoMessageCell.self, forCellWithReuseIdentifier: photoMessageCellID)
    collectionView.register(IncomingPhotoMessageCell.self, forCellWithReuseIdentifier: incomingPhotoMessageCellID)
    collectionView.register(OutgoingVoiceMessageCell.self, forCellWithReuseIdentifier: outgoingVoiceMessageCellID)
    collectionView.register(IncomingVoiceMessageCell.self, forCellWithReuseIdentifier: incomingVoiceMessageCellID)
    collectionView.register(InformationMessageCell.self, forCellWithReuseIdentifier: informationMessageCellID)
    collectionView.register(ChatLogViewControllerSupplementaryView.self,
														forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: "lol")

    configureRefreshControlInitialTintColor()
    configureCellContextMenuView()
    addBlockerView()
  }

  fileprivate let blocker = ViewBlockerContainer()

  fileprivate func addBlockerView() {
    guard let chatID = conversation?.chatID, let currentUserID = Auth.auth().currentUser?.uid else { return }
    guard chatID != currentUserID else { return }
    let contains = globalDataStorage.falconUsers.contains { (user) -> Bool in
      return user.id == chatID
    }

    let permitted = conversation?.permitted.value ?? false
    guard contains == false, permitted != true else { return }

    if let isGroupChat = conversation?.isGroupChat.value, !isGroupChat {
      view.addSubview(blocker)
      blocker.translatesAutoresizingMaskIntoConstraints = false
      blocker.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      blocker.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      blocker.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      blocker.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
  }
// MARK: - DATABASE REMOVE BLOCKER VIEW // TO MOVE
  @objc func removeBlockerView() {
    blocker.remove(from: view)
    guard let chatID = conversation?.chatID, let currentUserID = Auth.auth().currentUser?.uid else { return }
    Database.database().reference()
    .child("user-messages").child(currentUserID).child(chatID).child(messageMetaDataFirebaseFolder)
    .updateChildValues(["permitted": true])
  }

  @objc func blockAndDelete() {
    guard let chatID = conversation?.chatID else { return }
    userBlockingManager.blockUser(userID: chatID)
    inputBlockerAction()
  }

  @objc private func changeTheme() {
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    navigationController?.navigationBar.barStyle = ThemeManager.currentTheme().barStyle
    navigationController?.navigationBar.barTintColor = ThemeManager.currentTheme().barBackgroundColor
    refreshControl.tintColor = ThemeManager.currentTheme().generalTitleColor
    collectionView.updateColors()

    func updateTitleColor() {
      if let stack = navigationItem.titleView as? UIStackView, stack.arrangedSubviews.indices.contains(0) {
        guard let title = stack.arrangedSubviews[0] as? UILabel  else { return }
        title.textColor = ThemeManager.currentTheme().generalTitleColor
      }
    }

    func updateTypingIndicatorIfNeeded() {
      if collectionView.numberOfSections == groupedMessages.count + 1 {
        guard let cell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: 1)) as? TypingIndicatorCell else { return }
        cell.restart()
      }
    }
    updateTitleColor()
    updateTypingIndicatorIfNeeded()
    inputContainerView.inputTextView.reloadInputViews()
  }

  func setRightBarButtonItem () {

    let infoButton = UIButton(type: .infoLight)
    infoButton.addTarget(self, action: #selector(getInfoAction), for: .touchUpInside)
    let infoBarButtonItem = UIBarButtonItem(customView: infoButton)

    guard let uid = Auth.auth().currentUser?.uid,
      let conversationID = conversation?.chatID, uid != conversationID  else {
				navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .organize,
																														target: self,
																														action: #selector(openSharedMediaForStorage))
				return
		}
    navigationItem.rightBarButtonItem = infoBarButtonItem
    if isCurrentUserMemberOfCurrentGroup() {
      navigationItem.rightBarButtonItem?.isEnabled = true
    } else {
      navigationItem.rightBarButtonItem?.isEnabled = false
    }
  }

	@objc fileprivate func openSharedMediaForStorage() {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		let destination = SharedMediaController(collectionViewLayout: UICollectionViewFlowLayout())
		destination.fetchingData = (userID: uid, chatID: uid)
		inputContainerView.resignAllResponders()
		navigationController?.pushViewController(destination, animated: true)
	}

  @objc func getInfoAction() {
    inputContainerView.resignAllResponders()

    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {

      let destination = GroupAdminControlsTableViewController()
      destination.chatID = conversation?.chatID ?? ""
      if conversation?.admin != Auth.auth().currentUser?.uid {
        destination.adminControls = destination.defaultAdminControlls
      }

      if DeviceType.isIPad {

        let navigation = UINavigationController(rootViewController: destination)
         navigation.modalPresentationStyle = .popover
         navigation.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(navigation, animated: true, completion: nil)
      } else {
        self.navigationController?.pushViewController(destination, animated: true)
      }
      // admin group info controller
    } else {
      // regular default chat info controller
      let destination = UserInfoTableViewController()
      destination.delegate = self
      destination.conversationID = conversation?.chatID ?? ""
      if DeviceType.isIPad {
        let navigation = UINavigationController(rootViewController: destination)
        navigation.modalPresentationStyle = .popover
        navigation.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(navigation, animated: true, completion: nil)
      } else {
        self.navigationController?.pushViewController(destination, animated: true)
      }
    }
  }

  @objc func inputBlockerAction() {
    guard let chatID = conversation?.chatID else { return }
    if DeviceType.isIPad {
      splitViewController?.showDetailViewController(SplitPlaceholderViewController(), sender: self)
    } else {
      navigationController?.popViewController(animated: true)
    }

    deleteAndExitDelegate?.deleteAndExit(from: chatID)
  }

  // MARK: - Keyboard

  @objc open dynamic func keyboardWillShow(_ notification: Notification) {
    if isScrollViewAtTheBottom() {
      collectionView.scrollToBottom(animated: false)
    }
  }

// MARK: - DATABASE TYPING INDICATOR // TO MOVE
  private var localTyping = false

  var isTyping: Bool {
    get {
      return localTyping
    }
    set {
      localTyping = newValue
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }
      let typingData: NSDictionary = [currentUserID: newValue] //??
      if localTyping {
        sendTypingStatus(data: typingData)
      } else {
        if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
          guard let conversationID = conversation?.chatID else { return }
          let userIsTypingRef = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID).child(currentUserID)
          userIsTypingRef.removeValue()
        } else {
          guard let conversationID = conversation?.chatID else { return }
          let userIsTypingRef = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(typingIndicatorDatabaseID)
          userIsTypingRef.removeValue()
        }
      }
    }
  }

  func sendTypingStatus(data: NSDictionary) {
    guard let currentUserID = Auth.auth().currentUser?.uid,
      let conversationID = conversation?.chatID, currentUserID != conversationID else { return }

    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
      let userIsTypingRef = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID)
      userIsTypingRef.updateChildValues(data as! [AnyHashable: Any])
    } else {
      let userIsTypingRef = Database.database().reference().child("user-messages").child(currentUserID).child(conversationID).child(typingIndicatorDatabaseID)
      userIsTypingRef.setValue(data)
    }
  }

  func observeTypingIndicator () {
    guard let currentUserID = Auth.auth().currentUser?.uid,
      let conversationID = conversation?.chatID, currentUserID != conversationID else { return }

    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat {
      let indicatorRemovingReference = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID).child(currentUserID)
      indicatorRemovingReference.onDisconnectRemoveValue()
      typingIndicatorReference = Database.database().reference().child("groupChatsTemp").child(conversationID).child(typingIndicatorDatabaseID)
      typingIndicatorHandle = typingIndicatorReference.observe(.value, with: { (snapshot) in

        guard let dictionary = snapshot.value as? [String: AnyObject], let firstKey = dictionary.first?.key else {
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

  func handleTypingIndicatorAppearance(isEnabled: Bool) {
    if isEnabled {
      guard collectionView.numberOfSections < groupedMessages.count + 1 else { return }
      self.collectionView.performBatchUpdates ({
        self.typingIndicatorSection = ["TypingIndicator"]
        print("inserting")
        self.collectionView.insertSections([groupedMessages.count])

      }, completion: { (isCompleted) in
        print(isCompleted)
        if self.isScrollViewAtTheBottom() {
          if self.collectionView.contentSize.height < self.collectionView.bounds.height {
            return
          }
          self.collectionView.scrollToBottom(animated: true)
        }
      })

    } else {

      guard collectionView.numberOfSections == groupedMessages.count + 1 else { return }
      self.collectionView.performBatchUpdates ({
          self.typingIndicatorSection.removeAll()

        if self.collectionView.numberOfSections > groupedMessages.count {
          self.collectionView.deleteSections([groupedMessages.count])

          guard let cell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: groupedMessages.count)) as? TypingIndicatorCell else {
            return
          }
          cell.typingIndicator.stopAnimating()
          if isScrollViewAtTheBottom() {
            collectionView.scrollToBottom(animated: true)
          }
        }
      }, completion: nil)
    }
  }

 // MARK: - DATABASE MESSAGE STATUS // TO MOVE
  func updateMessageStatus(messageRef: DatabaseReference) {

    guard let uid = Auth.auth().currentUser?.uid, currentReachabilityStatus != .notReachable else { return }

    var senderID: String?

    messageRef.child("fromId").observeSingleEvent(of: .value, with: { (snapshot) in

      if !snapshot.exists() { return }

      senderID = snapshot.value as? String
      guard uid != senderID,
        (self.navigationController?.visibleViewController is UserInfoTableViewController ||
          self.navigationController?.visibleViewController is ChatLogViewController ||
          self.navigationController?.visibleViewController is GroupAdminControlsTableViewController ||
          self.navigationController?.visibleViewController is OtherReportController ||
					self.navigationController?.visibleViewController is SharedMediaController ||
          UIApplication.topViewController() is CropViewController ||
          UIApplication.topViewController() is INSPhotosViewController ||
          UIApplication.topViewController() is SFSafariViewController) else { senderID = nil; return }
      messageRef.updateChildValues(["seen": true, "status": messageStatusRead], withCompletionBlock: { (_, _) in
        self.resetBadgeForSelf()
      })
    })
  }

  fileprivate func resetBadgeForSelf() {
    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    let badgeRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(messageMetaDataFirebaseFolder).child("badge")
    badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
      var value = mutableData.value as? Int
      value = 0
      mutableData.value = value!
      return TransactionResult.success(withValue: mutableData)
    })
  }

  func updateMessageStatusUI(sentMessage: Message) {
    DispatchQueue.global(qos: .default).async {
      guard let index = self.messages.index(where: { (message) -> Bool in
        return message.messageUID == sentMessage.messageUID
      }) else { return }

      guard index >= 0 else { return }

      self.messages[index].status = sentMessage.status
      self.groupedMessages = Message.groupedMessages(self.messages)
      guard let indexPath = Message.get(indexPathOf: self.messages[index], in: self.groupedMessages) else { return }
      DispatchQueue.main.async {
        self.collectionView.performBatchUpdates({
          self.collectionView.reloadItems(at: [indexPath])
        }, completion: nil)
      }

      guard sentMessage.status == messageStatusDelivered,
        self.messages[index].messageUID == self.messages.last?.messageUID,
        userDefaults.currentBoolObjectState(for: userDefaults.inAppSounds) else { return }
      SystemSoundID.playFileNamed(fileName: "sent", withExtenstion: "caf")
    }
  }

  // MARK: - Title view
  fileprivate func configureProgressBar() {

    guard navigationController?.navigationBar != nil else { return }
    guard !uploadProgressBar.isDescendant(of: navigationController!.navigationBar) else { return }

    navigationController?.navigationBar.addSubview(uploadProgressBar)
    uploadProgressBar.translatesAutoresizingMaskIntoConstraints = false
    uploadProgressBar.bottomAnchor.constraint(equalTo: navigationController!.navigationBar.bottomAnchor).isActive = true
    uploadProgressBar.leftAnchor.constraint(equalTo: navigationController!.navigationBar.leftAnchor).isActive = true
    uploadProgressBar.rightAnchor.constraint(equalTo: navigationController!.navigationBar.rightAnchor).isActive = true
  }

  fileprivate var userHandler: UInt = 01
  fileprivate var onlineStatusInString: String?

  func setupTitleName() {
    guard let currentUserID = Auth.auth().currentUser?.uid, let toId = conversation?.chatID else { return }
    if currentUserID == toId {
      self.navigationItem.setTitle(title: NameConstants.personalStorage, subtitle: "")
    } else {
      self.navigationItem.setTitle(title: conversation?.chatName ?? "", subtitle: "")
    }
  }

  func configurePlaceholderTitleView() {

    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat,
      let title = conversation?.chatName,
			let membersCount = conversation?.chatParticipantsIDs.count {

      let subtitle = "\(membersCount) members"
      self.navigationItem.setTitle(title: title, subtitle: subtitle)
      return
    }

    guard let currentUserID = Auth.auth().currentUser?.uid, let toId = conversation?.chatID else { return }

    if currentUserID == toId {
      self.navigationItem.title = NameConstants.personalStorage
      return
    }

    guard let index = globalDataStorage.falconUsers.index(where: { (user) -> Bool in
      return user.id == conversation?.chatID
    }) else { return }
    let status = globalDataStorage.falconUsers[index].onlineStatus as AnyObject
    onlineStatusInString = manageNavigationItemTitle(onlineStatusObject: status)
  }

	// MARK: - DATABASE ONLINE STATUS // TO MOVE
  func configureTitleViewWithOnlineStatus() {

    if let isGroupChat = conversation?.isGroupChat.value, isGroupChat,
			let title = conversation?.chatName, let membersCount = conversation?.chatParticipantsIDs.count {
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
      self.onlineStatusInString = self.manageNavigationItemTitle(onlineStatusObject: status)
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

      //user got server timestamp in miliseconds
    } else if let onlineStatusTimeIntervalStamp = onlineStatusObject as? TimeInterval {
      let date = Date(timeIntervalSince1970: onlineStatusTimeIntervalStamp/1000)
      let subtitle = "Last seen " + timeAgoSinceDate(date)
      self.navigationItem.setTitle(title: title, subtitle: subtitle)
      return subtitle
    }
    return ""
  }

  // MARK: Scroll view
  func isScrollViewAtTheBottom() -> Bool {
    if collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.frame.size.height - 450) {
      return true
    }
    return false
  }

  private var canRefresh = true

  func scrollViewDidScroll(_ scrollView: UIScrollView) {

    if isScrollViewAtTheBottom() {
      DispatchQueue.main.async {
        self.bottomScrollConainer.isHidden = true
      }
    } else {
      DispatchQueue.main.async {
        self.bottomScrollConainer.isHidden = false
      }
    }

    if scrollView.contentOffset.y <= 0 { //change 100 to whatever you want
      if collectionView.contentSize.height < UIScreen.main.bounds.height - 50 {
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

  // MARK: Messages sending

  @objc func handleSend() {
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
      return
    }

    isTyping = false
    let text = inputContainerView.inputTextView.text
    let media = inputContainerView.attachedMedia
    inputContainerView.attachButton.reset()
    inputContainerView.prepareForSend()
    let messageSender = MessageSender(conversation, text: text, media: media)
    messageSender.delegate = self
    messageSender.sendMessage()
  }
}
