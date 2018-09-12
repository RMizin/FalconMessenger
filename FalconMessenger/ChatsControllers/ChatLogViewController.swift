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
  
  weak var typingIndicatorManager: TypingIndicatorManager?
  
  var messagesFetcher: MessagesFetcher?
  let chatLogHistoryFetcher = ChatLogHistoryFetcher()
  let userBlockingManager = UserBlockingManager()

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
  
  var mediaPickerController: MediaPickerControllerNew! = nil
  var voiceRecordingViewController: VoiceRecordingViewController! = nil
  var chatLogAudioPlayer: AVAudioPlayer!
  var inputTextViewTapGestureRecognizer = UITapGestureRecognizer()
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
  
  fileprivate func configureRefreshControlInitialTintColor() { /* fixes bug of not setting refresh control tint color on initial refresh */
    collectionView.contentOffset = CGPoint(x: 0, y: -refreshControl.frame.size.height)
    refreshControl.beginRefreshing()
    refreshControl.endRefreshing()
  }
  
  @objc func performRefresh() {
    guard let conversation = self.conversation else { return }
    
    if let isGroupChat = conversation.isGroupChat, isGroupChat {
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
  
  //MARK: LIFECYCLE
  
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
   
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
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

    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    if self.navigationController?.visibleViewController is UserInfoTableViewController ||
      self.navigationController?.visibleViewController is GroupAdminControlsTableViewController ||
      self.navigationController?.visibleViewController is OtherReportController ||
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
    
    removeBanObservers()
    
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

    guard voiceRecordingViewController != nil, voiceRecordingViewController.recorder != nil else { return }
    
    voiceRecordingViewController.stop()
    voiceRecordingViewController.deleteAllRecordings()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
    print("\n CHATLOG CONTROLLER DE INIT \n")
  }
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    collectionView.collectionViewLayout.invalidateLayout()
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    collectionView.collectionViewLayout.invalidateLayout()

    inputContainerView.handleRotation()
    DispatchQueue.main.async { [unowned self] in
      self.collectionView.reloadData()
    }
  }
  
  override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
  
  fileprivate func blockInputViewConstraints() {
    guard let view = view as? ChatLogContainerView else { return }
    if let constant = keyboardLayoutGuide.topConstant {
      print(constant)
      if inputContainerView.inputTextView.isFirstResponder {
        view.blockBottomConstraint(constant: -constant)
        view.layoutIfNeeded()
      }
    }
  }
  
  fileprivate func unblockInputViewConstraints() {
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
  }
  
  private func setupBottomScrollButton() {
    view.addSubview(bottomScrollConainer)
    bottomScrollConainer.translatesAutoresizingMaskIntoConstraints = false
    bottomScrollConainer.widthAnchor.constraint(equalToConstant: 45).isActive = true
    bottomScrollConainer.heightAnchor.constraint(equalToConstant: 45).isActive = true
    
    guard let view = view as? ChatLogContainerView else {
      fatalError("Root view is not ChatLogContainerView")
    }
    
    bottomScrollConainer.rightAnchor.constraint(equalTo: view.inputViewContainer.rightAnchor, constant: -10).isActive = true
    bottomScrollConainer.bottomAnchor.constraint(equalTo: view.inputViewContainer.topAnchor, constant: -10).isActive = true
  }
  
  private func setupCollectionView() {
    extendedLayoutIncludesOpaqueBars = true
    edgesForExtendedLayout = UIRectEdge.bottom
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    
    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .never
    }
    
    collectionView.delegate = self
    collectionView.dataSource = self
    chatLogHistoryFetcher.delegate = self
    
    if DeviceType.isIPad {
      addIPadCloseButton()
    }
    
    collectionView.addObserver(self, forKeyPath: "contentSize", options: .old, context: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    inputTextViewTapGestureRecognizer = UITapGestureRecognizer(target: inputContainerView.chatLogController,
                                                               action: #selector(ChatLogViewController.toggleTextView))
    
    inputTextViewTapGestureRecognizer.delegate = inputContainerView

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
                            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "lol")
    
    configureRefreshControlInitialTintColor()
    configureCellContextMenuView()
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
    
    guard let uid = Auth.auth().currentUser?.uid, let conversationID = conversation?.chatID, uid != conversationID  else { return }
    navigationItem.rightBarButtonItem = infoBarButtonItem
    if isCurrentUserMemberOfCurrentGroup() {
      navigationItem.rightBarButtonItem?.isEnabled = true
    } else {
      navigationItem.rightBarButtonItem?.isEnabled = false
    }
  }
  
  @objc func getInfoAction() {
    inputContainerView.inputTextView.resignFirstResponder()
    if let isGroupChat = conversation?.isGroupChat, isGroupChat {
      
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
  
  @objc func keyboardDidHide(notification: NSNotification) {
    inputContainerView.inputTextView.inputView = nil
  }
  
  
  // MARK: Observers
  
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
        reloadInputView(view: inputContainerView)
        observeTypingIndicator()
        addChatsControllerTypingObserver()
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
      reloadInputView(view: inputBlockerContainerView)
      removeChatsControllerTypingObserver()
      navigationItem.rightBarButtonItem?.isEnabled = false
      if typingIndicatorReference != nil { typingIndicatorReference.removeObserver(withHandle: typingIndicatorHandle); typingIndicatorReference = nil }
      guard DeviceType.isIPad else { return }
      presentedViewController?.dismiss(animated: true, completion: nil)
    }
  }
  
  fileprivate func removeChatsControllerTypingObserver() {
    guard let chatID = conversation?.chatID else { return }
    typingIndicatorManager?.removeTypingIndicator(for: chatID)
  }
  
  fileprivate func addChatsControllerTypingObserver() {
     guard let chatID = conversation?.chatID else { return }
     typingIndicatorManager?.observeChangesForDefaultTypingIndicator(with: chatID)
     typingIndicatorManager?.observeChangesForGroupTypingIndicator(with: chatID)
  }
  
  func removeSubtitleInGroupChat() {
    if let isGroupChat = conversation?.isGroupChat, isGroupChat, let title = conversation?.chatName {
      let subtitle = ""
      navigationItem.setTitle(title: title, subtitle: subtitle)
      return
    }
  }
  
  private var localTyping = false
  
  var isTyping: Bool {
    get {
      return localTyping
    }
    set {
      localTyping = newValue
      guard let currentUserID = Auth.auth().currentUser?.uid else { return }
      let typingData: NSDictionary = [currentUserID : newValue] //??
      if localTyping {
        sendTypingStatus(data: typingData)
      } else {
        if let isGroupChat = conversation?.isGroupChat, isGroupChat {
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
          
          guard let cell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: groupedMessages.count ) ) as? TypingIndicatorCell else {
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
          UIApplication.topViewController() is CropViewController ||
          UIApplication.topViewController() is INSPhotosViewController ||
          UIApplication.topViewController() is SFSafariViewController) else { senderID = nil; return }
      messageRef.updateChildValues(["seen" : true, "status": messageStatusRead], withCompletionBlock: { (error, reference) in
        self.resetBadgeForSelf()
      })
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
   
      guard sentMessage.status == messageStatusDelivered, self.messages[index].messageUID == self.messages.last?.messageUID,
        userDefaults.currentBoolObjectState(for: userDefaults.inAppSounds) else { return }
      SystemSoundID.playFileNamed(fileName: "sent", withExtenstion: "caf")
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
    
    guard let index = globalDataStorage.falconUsers.index(where: { (user) -> Bool in
      return user.id == conversation?.chatID
    }) else { return }
    let status = globalDataStorage.falconUsers[index].onlineStatus as AnyObject
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
  
  //MARK: Scroll view
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
  
  
  //MARK: Messages sending
  
  @objc func handleSend() {
    
    guard currentReachabilityStatus != .notReachable else {
      basicErrorAlertWith(title: "No internet", message: noInternetError, controller: self)
      return
    }

    isTyping = false
    let text = inputContainerView.inputTextView.text ?? ""
    
    inputContainerView.inputTextView.text = ""
    inputContainerView.confirugeHeightConstraint()
    inputContainerView.sendButton.isEnabled = false
    inputContainerView.placeholderLabel.isHidden = false
    inputContainerView.inputTextView.isScrollEnabled = false
    
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
    
    guard !inputContainerView.attachedMedia.isEmpty else {
      if let unwrappedTextMessageProperties = textMessageProperties {
        sendMessageWithProperties(unwrappedTextMessageProperties, updateLocaly: true, updateRemotely: true, childRef: childtextMessageIDReference)
      }
      return
    }
    
    if let unwrappedTextMessageProperties = textMessageProperties {
      sendMessageWithProperties(unwrappedTextMessageProperties, updateLocaly: true, updateRemotely: false, childRef: childtextMessageIDReference)
    }
    
    guard let toId = conversation?.chatID, let fromId = Auth.auth().currentUser?.uid else { return }
    
    let attachedMedia = inputContainerView.attachedMedia
    
    if mediaPickerController != nil, let selected = mediaPickerController.collectionView.indexPathsForSelectedItems {
      for indexPath in selected  { mediaPickerController.collectionView.deselectItem(at: indexPath, animated: false) }
    }
    
    inputContainerView.attachedMedia.removeAll()
    inputContainerView.attachCollectionView.reloadData()
    inputContainerView.resetChatInputConntainerViewSettings()
    
    var mediaToUpload = CGFloat()
    var progressArray = [(objectID: String, progress: Double)]()
    var mediaMessageObjectsToSend = [(properties: [String:AnyObject], childRef: DatabaseReference)]()
    let uploadMediaGroup = DispatchGroup()
    
    for mediaObject in attachedMedia {
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
    
    for attachedMedia in attachedMedia {
      
      let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
      let ref = Database.database().reference().child("messages")
      let childRef = ref.childByAutoId()
      
      let isVoiceMessage = attachedMedia.audioObject != nil
      let isPhotoMessage = (attachedMedia.phAsset?.mediaType == PHAssetMediaType.image || attachedMedia.phAsset == nil) && attachedMedia.audioObject == nil
      let isVideoMessage = attachedMedia.phAsset?.mediaType == PHAssetMediaType.video
      
      
      if isVoiceMessage {
        let bae64string = attachedMedia.audioObject?.base64EncodedString()
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
          let values: [String: AnyObject] = ["messageUID": childRef.key as AnyObject, "toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "localImage": attachedMedia.object!.asUIImage!, "imageWidth":attachedMedia.object!.asUIImage!.size.width as AnyObject, "imageHeight": attachedMedia.object!.asUIImage!.size.height as AnyObject]
          
          reloadCollectionViewAfterSending(values: values)
          uploadToFirebaseStorageUsingImage(attachedMedia.object!.asUIImage!, progress: { (snapshot) in
            if let progressCount = snapshot?.progress?.fractionCompleted {
              progressArray = self.setProgressForElement(progress: progressCount*0.98, id: id, array: progressArray)
              self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
            }
          }) { (imageURL) in
            progressArray = self.setProgressForElement(progress: 1.0, id: id, array: progressArray)
            self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
            let image = attachedMedia.object!.asUIImage!
            let properties: [String: AnyObject] = ["imageUrl": imageURL as AnyObject, "imageWidth": image.size.width as AnyObject, "imageHeight": image.size.height as AnyObject]
            mediaMessageObjectsToSend.append((properties: properties, childRef: childRef))
            uploadMediaGroup.leave()
          }
        } else
          
          if isVideoMessage {
            
            guard let path = attachedMedia.fileURL else { return }
            let videoId = childRef.key
            let imageId = childRef.key + "image"
            let valuesForVideo: [String: AnyObject] = ["messageUID": childRef.key as AnyObject, "toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "localImage": attachedMedia.object!.asUIImage!, "imageWidth":attachedMedia.object!.asUIImage!.size.width as AnyObject, "imageHeight": attachedMedia.object!.asUIImage!.size.height as AnyObject, "localVideoUrl" : path as AnyObject]
            
            reloadCollectionViewAfterSending(values: valuesForVideo)
            uploadToFirebaseStorageUsingVideo(attachedMedia.videoObject!, progress: {[unowned self] (snapshot) in
              if let progressCount = snapshot?.progress?.fractionCompleted {
                progressArray = self.setProgressForElement(progress: progressCount*0.98, id: videoId, array: progressArray)
                self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
              }
            }) { (videoURL) in
              progressArray = self.setProgressForElement(progress: 1.0, id: videoId, array: progressArray)
              self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
              
              self.uploadToFirebaseStorageUsingImage(attachedMedia.object!.asUIImage!, progress: { [unowned self] (snapshot) in
                
                if let progressCount = snapshot?.progress?.fractionCompleted {
                  progressArray = self.setProgressForElement(progress: progressCount*0.98, id: imageId, array: progressArray)
                  self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
                }
                
                }, completion: { (imageUrl) in
                  progressArray = self.setProgressForElement(progress: 1.0, id: imageId, array: progressArray)
                  self.updateProgressBar(array: progressArray, totalUploadsCount: mediaToUpload)
                  let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": attachedMedia.object!.asUIImage?.size.width as AnyObject, "imageHeight": attachedMedia.object!.asUIImage?.size.height as AnyObject, "videoUrl": videoURL as AnyObject]
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [unowned self] in
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
