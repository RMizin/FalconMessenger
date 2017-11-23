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


private let incomingTextMessageCellID = "incomingTextMessageCellID"

private let outgoingTextMessageCellID = "outgoingTextMessageCellID"

private let typingIndicatorCellID = "typingIndicatorCellID"

private let photoMessageCellID = "photoMessageCellID"

private let typingIndicatorDatabaseID = "typingIndicator"

private let typingIndicatorStateDatabaseKeyID = "Is typing"

private let incomingPhotoMessageCellID = "incomingPhotoMessageCellID"


protocol MessagesLoaderDelegate: class {
  func messagesLoader( didFinishLoadingWith messages: [Message] )
}


class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  
  weak var delegate: MessagesLoaderDelegate?
  
   var user: User? {
    didSet {
      loadMessages()
      self.title = user?.name
      configureTitleViewWithOnlineStatus()
    }
  }
  
  var userMessagesLoadingReference: DatabaseQuery!

  var messagesLoadingReference: DatabaseReference!
  
  var typingIndicatorReference: DatabaseReference!
  
  var userStatusReference: DatabaseReference!
  
  var messages = [Message]()
  
  var mediaMessages = [Message]()
  
  var sections = ["Messages"]
  
  let messagesToLoad = 50
  
  var mediaPickerController: MediaPickerControllerNew! = nil
  
  var inputTextViewTapGestureRecognizer = UITapGestureRecognizer()
  
  var uploadProgressBar = UIProgressView(progressViewStyle: .bar)

  
  func scrollToBottom() {
    if self.messages.count - 1 <= 0 {
      return
    }
    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
    DispatchQueue.main.async {
      self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
    }
  }
  
  func scrollToBottomOnNewLine() {
    if self.messages.count - 1 <= 0 {
      return
    }
    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
    DispatchQueue.main.async {
      self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
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

  
  fileprivate var isInitialChatMessagesLoad = true
  
  func loadMessages() {
    
    var appendingMessages = [Message]()
    let initialLoadGroup = DispatchGroup()
    guard let uid = Auth.auth().currentUser?.uid,let toId = user?.id else {
      return
    }
    
    userMessagesLoadingReference = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(messagesToLoad))
    userMessagesLoadingReference?.keepSynced(true)
    userMessagesLoadingReference?.observeSingleEvent(of: .value, with: { (snapshot) in
    
      for _ in 0 ..< snapshot.childrenCount {
        initialLoadGroup.enter()
      }
      
      initialLoadGroup.notify(queue: DispatchQueue.main, execute: {
        
        self.isInitialChatMessagesLoad = false
        
        if snapshot.exists() {
          appendingMessages.sort(by: { (message1, message2) -> Bool in
            return message1.timestamp!.int32Value < message2.timestamp!.int32Value
          })
       
         self.delegate?.messagesLoader(didFinishLoadingWith: appendingMessages)
         self.observeTypingIndicator()
         self.updateMessageStatus(messageRef: self.messagesLoadingReference)
        } else {
         self.delegate?.messagesLoader(didFinishLoadingWith: self.messages)
         self.observeTypingIndicator()
        }
      })
      
      self.userMessagesLoadingReference?.observe( .childAdded, with: { (snapshot) in
        let messageUID = snapshot.key
        self.messagesLoadingReference = Database.database().reference().child("messages").child(messageUID)
        self.messagesLoadingReference.keepSynced(true)
        self.messagesLoadingReference.observeSingleEvent(of: .value, with: { (snapshot) in
        
          guard var dictionary = snapshot.value as? [String: AnyObject] else {
            return
          }
          
          dictionary.updateValue(messageUID as AnyObject, forKey: "messageUID")
          
          if let messageText = Message(dictionary: dictionary).text { /* pre-calculateCellSizes */
            dictionary.updateValue( self.estimateFrameForText(messageText) as AnyObject , forKey: "estimatedFrameForText" )
          } else if let imageWidth = Message(dictionary: dictionary).imageWidth?.floatValue, let imageHeight =  Message(dictionary: dictionary).imageHeight?.floatValue {
            let cellHeight = CGFloat(imageHeight / imageWidth * 200).rounded()
            dictionary.updateValue( cellHeight as AnyObject , forKey: "imageCellHeight" )
          }
        
          if self.isInitialChatMessagesLoad {
            appendingMessages.append(Message(dictionary: dictionary))
  
            if (Message(dictionary: dictionary).imageUrl != nil || Message(dictionary: dictionary).localImage != nil) && Message(dictionary: dictionary).videoUrl == nil {
              if Message(dictionary: dictionary).localVideoUrl == nil {
                self.mediaMessages.append(Message(dictionary: dictionary))
              }
            }
      
            initialLoadGroup.leave()
          
          } else {
          
            if Message(dictionary: dictionary).fromId == uid || Message(dictionary: dictionary).fromId == Message(dictionary:dictionary).toId { /* outbox */
              
              self.messagesLoadingReference.observe(.childChanged, with: { (snapshot) in
                if snapshot.exists() && snapshot.key == "status" {
                  let newMessageStatus = snapshot.value!
                  dictionary.updateValue(newMessageStatus as AnyObject, forKey: "status")
                  self.updateMessageStatusUI(dictionary: dictionary)
                }
              })
              
              self.updateMessageStatus(messageRef: self.messagesLoadingReference)
              self.updateMessageStatusUI(dictionary: dictionary)
              
              if UserDefaults.standard.bool(forKey: "In-AppSounds") {
                SystemSoundID.playFileNamed(fileName: "sent", withExtenstion: "caf")
              }
              return
            }
          
            if Message(dictionary: dictionary).toId == uid { /* inbox */
              
              self.collectionView?.performBatchUpdates ({
                self.messages.append(Message(dictionary: dictionary))
                
                if (Message(dictionary: dictionary).imageUrl != nil || Message(dictionary: dictionary).localImage != nil) && Message(dictionary: dictionary).videoUrl == nil {
                  if Message(dictionary: dictionary).localVideoUrl == nil {
                    self.mediaMessages.append(Message(dictionary: dictionary))
                  }
                }
                
                if self.messages.count - 1 >= 0 {
                  let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                  self.collectionView?.insertItems(at: [indexPath])
                } else {
                  return
                }
             
                if self.messages.count - 2 >= 0 {
                  self.collectionView?.reloadItems(at: [IndexPath (row: self.messages.count - 2, section: 0)])
                }
            
                if self.messages.count - 1 >= 0 && self.isScrollViewAtTheBottom {
                  let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                  
                  DispatchQueue.main.async {
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                  }
                }
              }, completion: { (true) in
                self.updateMessageStatus(messageRef: self.messagesLoadingReference)
              })
            }
          }
      }, withCancel: { (error) in
        print("error loading message")
      })
    }, withCancel: { (error) in
      print("error loading message iDS")
    })
    })
  }
  
  var queryStartingID = String()
  var queryEndingID = String()
  
  func loadPreviousMessages() {
    
    let numberOfMessagesToLoad = messages.count + messagesToLoad
    let nextMessageIndex = messages.count + 1
    let mediaMessagesCount = mediaMessages.count
    let oldestMessagesLoadingGroup = DispatchGroup()
    
    guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
      return
    }
    
    if messages.count <= 0 {
       self.refreshControl.endRefreshing()
    }
    
    let startingIDRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(numberOfMessagesToLoad))
    startingIDRef.observeSingleEvent(of: .childAdded, with: { (snapshot) in
      
      if snapshot.exists() {
        self.queryStartingID = snapshot.key
      }
      
      let endingIDRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(nextMessageIndex))
      endingIDRef.observeSingleEvent(of: .childAdded, with: { (snapshot) in
        self.queryEndingID = snapshot.key
        
        if self.queryStartingID == self.queryEndingID {
          self.refreshControl.endRefreshing()
          return
        }
        
        var userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryOrderedByKey()
          userMessagesRef = userMessagesRef.queryStarting(atValue: self.queryStartingID).queryEnding(atValue: self.queryEndingID)
        
        userMessagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
          for _ in 0 ..< snapshot.childrenCount {
            oldestMessagesLoadingGroup.enter()
          }
          
          oldestMessagesLoadingGroup.notify(queue: DispatchQueue.main, execute: {
            var arrayWithShiftedMessages = self.messages
            let shiftingIndex = self.messagesToLoad - (numberOfMessagesToLoad - self.messages.count )
            
            arrayWithShiftedMessages.shiftInPlace(withDistance: -shiftingIndex)
            self.mediaMessages.shiftInPlace(withDistance: mediaMessagesCount - self.mediaMessages.count)
            
            self.messages = arrayWithShiftedMessages
            userMessagesRef.removeAllObservers()
            
            contentSizeWhenInsertingToTop = self.collectionView?.contentSize
            isInsertingCellsToTop = true
            self.refreshControl.endRefreshing()
            
            DispatchQueue.main.async {
              self.collectionView?.reloadData()
            }
          })
        })
        
          userMessagesRef.observe(.childAdded, with: { (snapshot) in
            let messagesRef = Database.database().reference().child("messages").child(snapshot.key)
            let messageUID = snapshot.key
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
              guard var dictionary = snapshot.value as? [String: AnyObject] else {
                return
              }
            
              dictionary.updateValue(messageUID as AnyObject, forKey: "messageUID")
              
              if let messageText = Message(dictionary: dictionary).text { /* pre-calculateCellSizes */
                dictionary.updateValue(self.estimateFrameForText(messageText) as AnyObject , forKey: "estimatedFrameForText" )
              } else if let imageWidth = Message(dictionary: dictionary).imageWidth?.floatValue, let imageHeight =  Message(dictionary: dictionary).imageHeight?.floatValue {
                let cellHeight = CGFloat(imageHeight / imageWidth * 200).rounded()
                dictionary.updateValue( cellHeight as AnyObject , forKey: "imageCellHeight" )
              }
            
              self.messages.append(Message(dictionary: dictionary))
            
              if (Message(dictionary: dictionary).imageUrl != nil || Message(dictionary: dictionary).localImage != nil) && Message(dictionary: dictionary).videoUrl == nil {
                if Message(dictionary: dictionary).localVideoUrl == nil {
                  self.mediaMessages.append(Message(dictionary: dictionary))
                }
              }
              oldestMessagesLoadingGroup.leave()
            }, withCancel: nil) // messagesRef
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
      let typingData: NSDictionary = [typingIndicatorStateDatabaseKeyID : newValue]
      if localTyping {
        sendTypingStatus(data: typingData)
      } else {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
          return
        }
        let userIsTypingRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(typingIndicatorDatabaseID)
        userIsTypingRef.removeValue()
      }
    }
  }
  
  
  func sendTypingStatus(data: NSDictionary) {
    
    guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
      return
    }
    
    if uid == toId { /* If you are chatting with yourself */
        return
    }
    
    let userIsTypingRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(typingIndicatorDatabaseID)
    userIsTypingRef.setValue(data)
  }
  
  
  func observeTypingIndicator () {
    
    guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
      return
    }
    
    if uid == toId { /* If you are chatting with yourself */
        return
    }
    
    let internalTypingIndicatorRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(typingIndicatorDatabaseID)
    internalTypingIndicatorRef.onDisconnectRemoveValue()
    
    typingIndicatorReference = Database.database().reference().child("user-messages").child(toId).child(uid).child(typingIndicatorDatabaseID).child(typingIndicatorStateDatabaseKeyID)
    typingIndicatorReference.onDisconnectRemoveValue()
    typingIndicatorReference.observe( .value, with: { (isTyping) in
      
      if let isUserTypingToYou = isTyping.value! as? Bool {
        
        if isUserTypingToYou {
          self.handleTypingIndicatorAppearance(isEnabled: true)
          
        } else {
          self.handleTypingIndicatorAppearance(isEnabled: false)
        }
        
      } else { /* if typing indicator not exist */
        self.handleTypingIndicatorAppearance(isEnabled: false)
      }
    })
  }
  
  
  fileprivate func handleTypingIndicatorAppearance(isEnabled: Bool) {
    
    let sectionsIndexSet: IndexSet = [1]
    
    if isEnabled {
      self.collectionView?.performBatchUpdates ({
        
        self.sections = ["Messages", "TypingIndicator"]
        
        self.collectionView?.insertSections(sectionsIndexSet)
        
      }, completion: { (true) in
        if self.collectionView!.contentOffset.y >= (self.collectionView!.contentSize.height - self.collectionView!.frame.size.height - 200) {
          self.scrollToBottomOfTypingIndicator()
        }
      })
      
    } else {
      
      self.collectionView?.performBatchUpdates ({
        
        self.sections = ["Messages"]
        
        if self.collectionView!.numberOfSections > 1 {
          self.collectionView?.deleteSections(sectionsIndexSet)
          
          guard let cell = self.collectionView?.cellForItem(at: IndexPath(item: 0, section: 1 ) ) as? TypingIndicatorCell else {
            return
          }
          
          cell.typingIndicator.animatedImage = nil
          if self.collectionView!.contentOffset.y >= (self.collectionView!.contentSize.height - self.collectionView!.frame.size.height + 200) {
            self.scrollToBottomOnNewLine()
          }
        }
      }, completion: nil)
    }
  }
  
  
  fileprivate func updateMessageStatus(messageRef: DatabaseReference) {
    
    guard let uid = Auth.auth().currentUser?.uid, currentReachabilityStatus != .notReachable else {
      return
    }
  
    var recieverID: String?
    messageRef.child("toId").observeSingleEvent(of: .value, with: { (snapshot) in
        
      if !snapshot.exists() {
       return
      }
      
      recieverID = snapshot.value as? String
      
      if uid == recieverID  { /* if i'm a reciever */
        if self.navigationController?.visibleViewController is ChatLogController {
          messageRef.updateChildValues(["seen" : true, "status": messageStatusRead], withCompletionBlock: { (error, reference) in
            self.resetBadgeForReciever()
          })
        }
      } else { /* if i'm a sender */
        recieverID = nil
      }
    })
  }
  
  
  func updateMessageStatusUI(dictionary: [String : AnyObject]) {
    
    if let lastMessageStatus = dictionary["status"] as? String {
      if self.messages.count - 1 >= 0 {
        self.messages[self.messages.count - 1].status = lastMessageStatus
        self.collectionView?.reloadItems(at: [IndexPath(row: self.messages.count-1 ,section: 0)])
        print("value")
      }
    }
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCollectionView()
    setRightBarButtonItem()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    if self.navigationController?.visibleViewController is UserInfoTableViewController {
        return
    }
    
    if userMessagesLoadingReference != nil {
      userMessagesLoadingReference.removeAllObservers()
    }

    if messagesLoadingReference != nil {
      messagesLoadingReference.removeAllObservers()
    }

    if typingIndicatorReference != nil {
      typingIndicatorReference.removeAllObservers()
    }

    if userStatusReference != nil {
      userStatusReference.removeAllObservers()
    }

    isTyping = false
    
  }
  
  
  private var oldOffset: CGPoint?
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    oldOffset = self.collectionView!.contentOffset
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if oldOffset != nil  {
      collectionView?.setContentOffset(oldOffset!, animated: false)
      oldOffset = nil
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    configureProgressBar()
  
    if oldOffset != nil {
      collectionView?.setContentOffset(oldOffset!, animated: false)
      collectionView?.collectionViewLayout.invalidateLayout()
      collectionView?.layoutIfNeeded()
      oldOffset = nil
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
      collectionView.scrollToItem(at: IndexPath(item: messages.count-1, section: 0), at: .bottom, animated: false)
    }
    didLayoutFlag = true
    }
  }
  
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
         super.willTransition(to: newCollection, with: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
         super.viewWillTransition(to: size, with: coordinator)
      
        collectionView?.collectionViewLayout.invalidateLayout()
        inputContainerView.inputTextView.invalidateIntrinsicContentSize()
        inputContainerView.invalidateIntrinsicContentSize()
  
        DispatchQueue.main.async {
           self.inputContainerView.attachedImages.frame.size.width = self.inputContainerView.inputTextView.frame.width
            self.collectionView?.reloadData()
        }
    }
  
  deinit {
    print("\n CHATLOG CONTROLLER DE INIT \n")
  }
  
  fileprivate func configureProgressBar() {
    
    guard navigationController?.navigationBar != nil else {
      return
    }
    
    if uploadProgressBar.isDescendant(of: navigationController!.navigationBar) {
      return
    } else {
      navigationController?.navigationBar.addSubview(uploadProgressBar)
      uploadProgressBar.translatesAutoresizingMaskIntoConstraints = false
      uploadProgressBar.bottomAnchor.constraint(equalTo: navigationController!.navigationBar.bottomAnchor).isActive = true
      uploadProgressBar.leftAnchor.constraint(equalTo: navigationController!.navigationBar.leftAnchor).isActive = true
      uploadProgressBar.rightAnchor.constraint(equalTo: navigationController!.navigationBar.rightAnchor).isActive = true
    }
  }

  fileprivate func setupCollectionView () {
    inputTextViewTapGestureRecognizer = UITapGestureRecognizer(target: inputContainerView.chatLogController, action: #selector(ChatLogController.toggleTextView))
    inputTextViewTapGestureRecognizer.delegate = inputContainerView
  
    if #available(iOS 11.0, *) {
      collectionView?.translatesAutoresizingMaskIntoConstraints = false
      extendedLayoutIncludesOpaqueBars = true
      automaticallyAdjustsScrollViewInsets = false
      navigationItem.largeTitleDisplayMode = .never
      collectionView?.scrollIndicatorInsets = UIEdgeInsets.zero
      collectionView?.autoresizingMask = UIViewAutoresizing()
    
      collectionView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
      collectionView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
      collectionView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
      collectionView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    } else {
      collectionView?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - inputContainerView.frame.height  )
      automaticallyAdjustsScrollViewInsets = true
      extendedLayoutIncludesOpaqueBars = true
   }

    view.backgroundColor = .white
    collectionView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
    collectionView?.keyboardDismissMode = .interactive
    collectionView?.backgroundColor = UIColor.white
    collectionView?.delaysContentTouches = false
    collectionView?.alwaysBounceVertical = true
    collectionView?.isPrefetchingEnabled = true
    
    collectionView?.addSubview(refreshControl)
    collectionView?.register(IncomingTextMessageCell.self, forCellWithReuseIdentifier: incomingTextMessageCellID)
    collectionView?.register(OutgoingTextMessageCell.self, forCellWithReuseIdentifier: outgoingTextMessageCellID)
    collectionView?.register(TypingIndicatorCell.self, forCellWithReuseIdentifier: typingIndicatorCellID)
    collectionView?.register(PhotoMessageCell.self, forCellWithReuseIdentifier: photoMessageCellID)
    collectionView?.register(IncomingPhotoMessageCell.self, forCellWithReuseIdentifier: incomingPhotoMessageCellID)
    collectionView?.registerNib(UINib(nibName: "TimestampView", bundle: nil), forRevealableViewReuseIdentifier: "timestamp")
  }
  
  
  func configureTitleViewWithOnlineStatus() {
    userStatusReference = Database.database().reference().child("users").child(user!.id!).child("OnlineStatus")
    userStatusReference.observe(.value, with: { (snapshot) in
      
      guard let uid = Auth.auth().currentUser?.uid, let toId = self.user?.id else {
        return
      }
      
      if uid == toId {
         self.navigationItem.setTitle(title: self.user!.name!, subtitle: "You")
       
        return
      }
      
      if snapshot.exists() {
        if snapshot.value as! String == "Online" {
          DispatchQueue.main.async {
            self.navigationItem.setTitle(title: self.user!.name!, subtitle: "Online")
          }
        } else {
           let date = NSDate(timeIntervalSince1970:  (snapshot.value as! String).doubleValue )
            DispatchQueue.main.async {
                self.navigationItem.setTitle(title: self.user!.name!, subtitle: ("Last seen " + timeAgoSinceDate(date: date, timeinterval: (snapshot.value as! String).doubleValue, numericDates: false)))
            }
        }
      }
    })
  }
  
  
  func setRightBarButtonItem () {
    
    let infoButton = UIButton(type: .infoLight)
    
    infoButton.addTarget(self, action: #selector(getInfoAction), for: .touchUpInside)
    
    let infoBarButtonItem = UIBarButtonItem(customView: infoButton)

    navigationItem.rightBarButtonItem = infoBarButtonItem
  }
  
  @objc func getInfoAction() {
    
    let destination = UserInfoTableViewController()
    destination.contactName = user?.name ?? ""
    destination.contactPhoneNumbers = [user?.phoneNumber ?? ""]
    destination.contactPhoto = NSURL(string: user?.photoURL ?? "")
    destination.user = user
    
    self.navigationController?.pushViewController(destination, animated: true)
  }
  
  
  lazy var inputContainerView: ChatInputContainerView = {
    var chatInputContainerView = ChatInputContainerView()
    chatInputContainerView.chatLogController = self
    chatInputContainerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
    
    return chatInputContainerView
  }()
  
  
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
  
  
  let refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    refreshControl.addTarget(self, action: #selector(performRefresh), for: .valueChanged)
    
    return refreshControl
  }()
  
  
  @objc func performRefresh () {
    loadPreviousMessages()
  }
  
  
  override var inputAccessoryView: UIView? {
    get {
      return inputContainerView
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
    if indexPath.section == 0 {
      return selectCell(for: indexPath)!
    } else {
      return showTypingIndicator(indexPath: indexPath)! as! TypingIndicatorCell
    }
  }

  
  fileprivate func showTypingIndicator(indexPath: IndexPath) -> UICollectionViewCell? {
    
    let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: typingIndicatorCellID, for: indexPath) as! TypingIndicatorCell
    
    guard let gifURL = Bundle.main.url(forResource: "typingIndicator", withExtension: "gif") else {
        return nil
    }
    
    guard let gifData = NSData(contentsOf: gifURL) else {
        return nil
    }
    
    cell.typingIndicator.animatedImage = FLAnimatedImage(animatedGIFData: gifData as Data)
    
    return cell
  }
  
  
  fileprivate func selectCell(for indexPath: IndexPath) -> RevealableCollectionViewCell? {
    
    let message = messages[indexPath.item]
    
    if let messageText = message.text { /* If current message is a text message */
      
      if message.fromId == Auth.auth().currentUser?.uid { /* Outgoing message with blue bubble */
      
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: outgoingTextMessageCellID, for: indexPath) as! OutgoingTextMessageCell
        
        UIView.performWithoutAnimation {
      
            cell.textView.text = messageText

          cell.bubbleView.frame = CGRect(x: collectionView!.frame.width - /*estimateFrameForText(messageText).width */ message.estimatedFrameForText!.width - 35,
                                         y: 0,
                                         width: /*estimateFrameForText(messageText).width*/  message.estimatedFrameForText!.width + 30,
                                         height: cell.frame.size.height).integral
        
         
          cell.textView.frame.size = CGSize(width: cell.bubbleView.frame.width.rounded(),
                                            height: cell.bubbleView.frame.height.rounded())
            
           DispatchQueue.main.async {
            cell.deliveryStatus.frame = CGRect(x: cell.frame.width - 80, y: cell.bubbleView.frame.height + 2, width: 70, height: 10).integral
            
            switch indexPath.row == self.messages.count - 1 {
              
            case true:
              cell.deliveryStatus.text = self.messages[indexPath.row].status
              cell.deliveryStatus.isHidden = false
              break
              
            default:
              cell.deliveryStatus.isHidden = true
              break
            }
          
            if let view = self.collectionView?.dequeueReusableRevealableView(withIdentifier: "timestamp") as? TimestampView {
          
              view.titleLabel.text = message.timestamp?.doubleValue.getTimeStringFromUTC() // configure
          
              cell.setRevealableView(view, style: .slide, direction: .left)
            }
          }
        }
        
        return cell
      
        } else { /* Incoming message with grey bubble */
        
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingTextMessageCellID, for: indexPath) as! IncomingTextMessageCell
        
          UIView.performWithoutAnimation {
            
           
            cell.textView.text = messageText
        
            cell.bubbleView.frame.size = CGSize(width: (/*estimateFrameForText(messageText).width*/ message.estimatedFrameForText!.width + 30).rounded(),
                                          height: cell.frame.size.height.rounded())//.integral
          
            cell.textView.frame.size = CGSize(width: cell.bubbleView.frame.width.rounded(),
                                              height: cell.bubbleView.frame.height.rounded())
            
            DispatchQueue.main.async {
              if let view = self.collectionView?.dequeueReusableRevealableView(withIdentifier: "timestamp") as? TimestampView {
              
                view.titleLabel.text = message.timestamp?.doubleValue.getTimeStringFromUTC() // configure
            
                cell.setRevealableView(view, style: .over , direction: .left)
              }
            }
          }
        
          return cell
        }
      
    } else if message.imageUrl != nil || message.localImage != nil { /* If current message is a photo/video message */
      
     
      if message.fromId == Auth.auth().currentUser?.uid { /* Outgoing message with blue bubble */
        
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: photoMessageCellID, for: indexPath) as! PhotoMessageCell
        
        cell.chatLogController = self
        
        UIView.performWithoutAnimation {
          
        cell.message = message
        cell.bubbleView.frame.origin = CGPoint(x: (cell.frame.width - 210).rounded(), y: 0)
        cell.bubbleView.frame.size.height = cell.frame.size.height.rounded()
    
        DispatchQueue.main.async {
          
          cell.deliveryStatus.frame = CGRect(x: cell.frame.width - 80, y: cell.bubbleView.frame.height + 2, width: 70, height: 10).integral
          
          switch indexPath.row == self.messages.count - 1 {
            
          case true:
            cell.deliveryStatus.text = self.messages[indexPath.row].status//messageStatus
            cell.deliveryStatus.isHidden = false
            break
            
          default:
            cell.deliveryStatus.isHidden = true
            break
          }
          
          if let view = self.collectionView?.dequeueReusableRevealableView(withIdentifier: "timestamp") as? TimestampView {
            
            view.titleLabel.text = message.timestamp?.doubleValue.getTimeStringFromUTC() // configure
            
            cell.setRevealableView(view, style: .slide , direction: .left)
          }
        }
        
        cell.messageImageView.isUserInteractionEnabled = false
        }
        
        if let image = message.localImage {
          
          cell.messageImageView.image = image
          cell.progressView.isHidden = true
          cell.messageImageView.isUserInteractionEnabled = true
          
          cell.playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
          
          return cell
        }
        
        if let messageImageUrl = message.imageUrl {
          
          cell.progressView.isHidden = false
          
          cell.messageImageView.sd_setImage(with: URL(string: messageImageUrl), placeholderImage: nil, options: [.continueInBackground, .lowPriority, .scaleDownLargeImages], progress: { (downloadedSize, expectedSize, url) in
            let progress = Double(100 * downloadedSize/expectedSize)
            
            DispatchQueue.main.async {
              cell.progressView.setProgress(progress * 0.01, animated: false)
              cell.progressView.setNeedsLayout()
              cell.progressView.layoutIfNeeded()
            }
            
          }, completed: { (image, error, cacheType, url) in
            cell.progressView.isHidden = true
            cell.messageImageView.isUserInteractionEnabled = true
            cell.playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
            
          })
        }
        
        return cell
        
      } else { /* Incoming message with grey bubble */
        
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingPhotoMessageCellID, for: indexPath) as! IncomingPhotoMessageCell
        
        cell.chatLogController = self
        UIView.performWithoutAnimation {
          
        cell.message = message
        cell.bubbleView.frame.size.height = cell.frame.size.height.rounded()
        
        DispatchQueue.main.async {
          
          if let view = self.collectionView?.dequeueReusableRevealableView(withIdentifier: "timestamp") as? TimestampView {
            
            view.titleLabel.text = message.timestamp?.doubleValue.getTimeStringFromUTC() // configure
            
            cell.setRevealableView(view, style: .over , direction: .left)
          }
        }
        
        cell.messageImageView.isUserInteractionEnabled = false
        }
        if let image = message.localImage {
          
          cell.messageImageView.image = image
          cell.progressView.isHidden = true
          cell.messageImageView.isUserInteractionEnabled = true
          
          cell.playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
          
          return cell
        }
        
        if let messageImageUrl = message.imageUrl {
          cell.progressView.isHidden = false
          cell.messageImageView.sd_setImage(with: URL(string: messageImageUrl), placeholderImage: nil, options:  [.continueInBackground, .lowPriority, .scaleDownLargeImages], progress: { (downloadedSize, expectedSize, url) in
            
            let progress = Double(100 * downloadedSize/expectedSize)
            
            DispatchQueue.main.async {
              cell.progressView.setProgress(progress * 0.01, animated: false)
              cell.progressView.setNeedsLayout()
              cell.progressView.layoutIfNeeded()
            }
            
          }, completed: { (image, error, cacheType, url) in
            
            cell.progressView.isHidden = true
            
            cell.messageImageView.isUserInteractionEnabled = true
            
             cell.playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
          })
        }
        
        return cell
      }
    
    } else {
      
      return nil
    }
  }
  
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return selectSize(indexPath: indexPath)
  }

  func selectSize(indexPath: IndexPath) -> CGSize  {
    
    var cellHeight: CGFloat = 80
    
    if indexPath.section == 0 {
      let message = messages[indexPath.row]
    
      if message.text != nil {
        cellHeight = /*estimateFrameForText(text).height*/  message.estimatedFrameForText!.height + 20
      } else if message.imageWidth?.floatValue != nil && message.imageHeight?.floatValue != nil {
        
        cellHeight = CGFloat(truncating: message.imageCellHeight!)// CGFloat(imageHeight / imageWidth * 200).rounded()
      }
      
      return CGSize(width: self.collectionView!.frame.width, height: cellHeight)
    } else {
      return CGSize(width: self.collectionView!.frame.width, height: 40)
    }
  }
  
  
  func estimateFrameForText(_ text: String) -> CGRect {
    let size = CGSize(width: 200, height: 10000)
    let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
    return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13)], context: nil).integral
  }
  
  
  @objc func handleSend() {
    
    if currentReachabilityStatus != .notReachable {
        
      inputContainerView.inputTextView.isScrollEnabled = false
      inputContainerView.invalidateIntrinsicContentSize()

      inputContainerView.sendButton.isEnabled = false
    
      if inputContainerView.inputTextView.text != "" {
        let properties = ["text": inputContainerView.inputTextView.text!]
    
          sendMessageWithProperties(properties as [String : AnyObject])
      }
    
      isTyping = false
      inputContainerView.placeholderLabel.isHidden = false
    
      handleMediaMessageSending()
    } else {
      basicErrorAlertWith(title: "No internet", message: noInternetError, controller: self)
    }
  }
  

  func handleMediaMessageSending () {
    
    if !inputContainerView.selectedMedia.isEmpty {
      let selectedMedia = inputContainerView.selectedMedia
      
      let selected = mediaPickerController.collectionView.indexPathsForSelectedItems
      
      for indexPath in selected!  {
        mediaPickerController.collectionView.deselectItem(at: indexPath, animated: false)
      }
   
      if self.inputContainerView.selectedMedia.count - 1 >= 0 {
        
        for index in 0...self.inputContainerView.selectedMedia.count - 1 {
          
          if index <= -1 {
            break
          }
         
          print("equals")
          self.inputContainerView.selectedMedia.remove(at: 0)
          self.inputContainerView.attachedImages.deleteItems(at: [IndexPath(item: 0, section: 0)])
        }
      } else {
        self.inputContainerView.selectedMedia.remove(at: 0)
        self.inputContainerView.attachedImages.deleteItems(at: [IndexPath(item: 0, section: 0)])
      }
      
      inputContainerView.resetChatInputConntainerViewSettings()
      
      let uploadingMediaCount = selectedMedia.count
      var percentCompleted: CGFloat = 0.0
      
       UIView.animate(withDuration: 3, delay: 0, options: [.curveEaseOut], animations: {
        self.uploadProgressBar.setProgress(0.25, animated: true)
       }, completion: nil)
      
      let defaultMessageStatus = messageStatusSent
      
      guard let toId = user?.id, let fromId = Auth.auth().currentUser?.uid else {
        return
      }
      
      let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
      
      for selectedMedia in selectedMedia {
        
        if selectedMedia.phAsset?.mediaType == PHAssetMediaType.image || selectedMedia.phAsset == nil {
          
          let values: [String: AnyObject] = ["toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "localImage": selectedMedia.object!.asUIImage!, "imageWidth":selectedMedia.object!.asUIImage!.size.width as AnyObject, "imageHeight": selectedMedia.object!.asUIImage!.size.height as AnyObject]
          
          reloadCollectionViewAfterSending(values: values)
          
          uploadToFirebaseStorageUsingImage(selectedMedia.object!.asUIImage!, completion: { (imageURL) in
            self.sendMessageWithImageUrl(imageURL, image: selectedMedia.object!.asUIImage!)
            
           percentCompleted += CGFloat(1.0)/CGFloat(uploadingMediaCount)
           self.uploadProgressBar.setProgress(Float(percentCompleted), animated: true)
            
            if percentCompleted == 1.0 {
              DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
               self.uploadProgressBar.setProgress(0.0, animated: false)
              
              })
            }
          })
        }
        
        if selectedMedia.phAsset?.mediaType == PHAssetMediaType.video {

          guard let path = selectedMedia.fileURL else {
            print("no file url returning")
            return
          }
          
          let valuesForVideo: [String: AnyObject] = ["toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "localImage": selectedMedia.object!.asUIImage!, "imageWidth":selectedMedia.object!.asUIImage!.size.width as AnyObject, "imageHeight": selectedMedia.object!.asUIImage!.size.height as AnyObject, "localVideoUrl" : path as AnyObject]
          
          self.reloadCollectionViewAfterSending(values: valuesForVideo)
          
          uploadToFirebaseStorageUsingVideo(selectedMedia.videoObject!, completion: { (videoURL) in
            
            self.uploadToFirebaseStorageUsingImage(selectedMedia.object!.asUIImage!, completion: { (imageUrl) in
              
              print("\n UPLOAD COMPLETED \n")
              
              let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": selectedMedia.object!.asUIImage?.size.width as AnyObject, "imageHeight": selectedMedia.object!.asUIImage?.size.height as AnyObject, "videoUrl": videoURL as AnyObject]
              
              self.sendMediaMessageWithProperties(properties)
              
              percentCompleted += CGFloat(1.0)/CGFloat(uploadingMediaCount)
              
              self.uploadProgressBar.setProgress(Float(percentCompleted), animated: true)
              
              if percentCompleted == 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                  self.uploadProgressBar.setProgress(0.0, animated: false)
                })
              }
            })
          })
        }
      }
    }
  }
  
  
  fileprivate func sendMessageWithImageUrl(_ imageUrl: String, image: UIImage) {
    
   let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": image.size.width as AnyObject, "imageHeight": image.size.height as AnyObject]
    sendMediaMessageWithProperties(properties)
  }
  
  
  func sendMediaMessageWithProperties(_ properties: [String: AnyObject]) {
    
    let ref = Database.database().reference().child("messages")
    
    let childRef = ref.childByAutoId()
    
    let defaultMessageStatus = messageStatusSent
    
    guard let toId = user?.id, let fromId = Auth.auth().currentUser?.uid else {
      return
    }
    
    self.inputContainerView.inputTextView.text = nil
    
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    
    
    var values: [String: AnyObject] = ["toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp]
    
    properties.forEach({values[$0] = $1})
    
    childRef.updateChildValues(values) { (error, ref) in
      
      if error != nil {
        print(error as Any)
        // here need to notify user that message has not been sent
        return
      }
      
      let messageId = childRef.key
      
      let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(userMessagesFirebaseFolder)
      
      userMessagesRef.updateChildValues([messageId: 1])
      
      let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId).child(userMessagesFirebaseFolder)
      
      recipientUserMessagesRef.updateChildValues([messageId: 1])
      
      self.incrementBadgeForReciever()
      self.setupMetadataForSender()
    }
  }
  
  
  fileprivate func uploadToFirebaseStorageUsingImage(_ image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
    let imageName = UUID().uuidString
    let ref = Storage.storage().reference().child("messageImages").child(imageName)
    
    if let uploadData = UIImageJPEGRepresentation(image, 1) {
      ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
        
        if error != nil {
          print("Failed to upload image:", error as Any)
          return
        }
        
        if let imageUrl = metadata?.downloadURL()?.absoluteString {
          completion(imageUrl)
        }
      })
    }
  }
  
  fileprivate func uploadToFirebaseStorageUsingVideo(_ uploadData: Data, completion: @escaping (_ videoUrl: String) -> ()) {
    let videoName = UUID().uuidString + ".mov"
    
    let ref = Storage.storage().reference().child("messageMovies").child(videoName)
    
      ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
        
        if error != nil {
          print("Failed to upload image:", error as Any)
          return
        }
        
        if let videoUrl = metadata?.downloadURL()?.absoluteString {
          completion(videoUrl)
        }
      })
  }
  

  fileprivate func reloadCollectionViewAfterSending(values: [String: AnyObject]) {
    
    var values = values
    
    if let messageText = Message(dictionary: values).text { /* pre-calculateCellSizes */
      values.updateValue(self.estimateFrameForText(messageText) as AnyObject , forKey: "estimatedFrameForText" )
    } else if let imageWidth = Message(dictionary: values).imageWidth?.floatValue, let imageHeight =  Message(dictionary: values).imageHeight?.floatValue {
      let cellHeight = CGFloat(imageHeight / imageWidth * 200).rounded()
      values.updateValue( cellHeight as AnyObject , forKey: "imageCellHeight" )
    }
    
    self.collectionView?.performBatchUpdates ({
      
      self.messages.append(Message(dictionary: values ))
      
      let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
   
      self.messages[indexPath.item].status = messageStatusSending
      
      self.collectionView?.insertItems(at: [indexPath])
      
      if self.messages.count - 2 >= 0 {
        
          self.collectionView?.reloadItems(at: [IndexPath(row: self.messages.count-2 ,section:0)])
      }
      
      if (self.messages[indexPath.item].imageUrl != nil || self.messages[indexPath.item].localImage != nil) && self.messages[indexPath.item].videoUrl == nil {
        if self.messages[indexPath.item].localVideoUrl == nil {
          self.mediaMessages.append(self.messages[indexPath.item])
        }
      }
      
      let indexPath1 = IndexPath(item: self.messages.count - 1, section: 0)
      
      DispatchQueue.main.async {
        
        self.collectionView?.scrollToItem(at: indexPath1, at: .bottom, animated: true)
      }
      
    }, completion: nil)
  }
  
  
  fileprivate func sendMessageWithProperties(_ properties: [String: AnyObject]) {
    
    let ref = Database.database().reference().child("messages")
    
    let childRef = ref.childByAutoId()
    
    let defaultMessageStatus = messageStatusSent
    
    guard let toId = user?.id, let fromId = Auth.auth().currentUser?.uid else {
      return
    }
    
    self.inputContainerView.inputTextView.text = nil
    
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    
    
    var values: [String: AnyObject] = ["toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp]
    
    properties.forEach({values[$0] = $1})
    
    self.reloadCollectionViewAfterSending(values: values)
    childRef.updateChildValues(values) { (error, ref) in
      
      if error != nil {
        print(error as Any)
        // here need to notify user that message has not been sent
        return
      }
      
      let messageId = childRef.key
      let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(userMessagesFirebaseFolder)
      
      userMessagesRef.updateChildValues([messageId: 1])
      
      let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId).child(userMessagesFirebaseFolder)
      
      recipientUserMessagesRef.updateChildValues([messageId: 1])
      
      self.incrementBadgeForReciever()
      self.setupMetadataForSender()
    }
  }
  
  
  func resetBadgeForReciever() {
    
    guard let toId = user?.id, let fromId = Auth.auth().currentUser?.uid else {
      return
    }
    
    let badgeRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(messageMetaDataFirebaseFolder).child("badge")
    
    badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
      var value = mutableData.value as? Int
      
      value = 0
      
      mutableData.value = value!
      return TransactionResult.success(withValue: mutableData)
    })
    
  }
  
  
  func setupMetadataForSender() {
    
    guard let toId = user?.id, let fromId = Auth.auth().currentUser?.uid else {
      return
    }
    
    var ref = Database.database().reference().child("user-messages").child(fromId).child(toId)
    ref.observeSingleEvent(of: .value, with: { (snapshot) in
      
      
      if snapshot.hasChild(messageMetaDataFirebaseFolder) {
        return
        
      } else {
        ref = ref.child(messageMetaDataFirebaseFolder)
        ref.updateChildValues(["badge": 0], withCompletionBlock: { (error, reference) in
          
          if error != nil {
            return
          }
        })
      }
    })
  }
  
  func incrementBadgeForReciever() {
    
    guard let toId = user?.id, let fromId = Auth.auth().currentUser?.uid else {
      return
    }
    
    var ref = Database.database().reference().child("user-messages").child(toId).child(fromId)
    ref.observeSingleEvent(of: .value, with: { (snapshot) in
      
      
      if snapshot.hasChild(messageMetaDataFirebaseFolder) {
        ref = ref.child(messageMetaDataFirebaseFolder).child("badge")
        ref.runTransactionBlock({ (mutableData) -> TransactionResult in
          var value = mutableData.value as? Int
          if value == nil  {
            value = 0
          }
          mutableData.value = value! + 1
          return TransactionResult.success(withValue: mutableData)
        })
        
      } else {
        ref = ref.child(messageMetaDataFirebaseFolder)
        ref.updateChildValues(["badge": 1], withCompletionBlock: { (error, reference) in
          
        })
      }
    })
  }
}



/*
 func startCollectionViewAtBottom () {
 
 let collectionViewInsets: CGFloat = (collectionView!.contentInset.bottom + collectionView!.contentInset.top)// + inputContainerView.inputTextView.frame.height
 let contentSize = self.collectionView?.collectionViewLayout.collectionViewContentSize
 
 if Double(contentSize!.height) > Double(self.collectionView!.bounds.size.height) {
 let targetContentOffset = CGPoint(x: 0.0, y: contentSize!.height - (self.collectionView!.bounds.size.height - collectionViewInsets))
 self.collectionView?.contentOffset = targetContentOffset
 }
 */
