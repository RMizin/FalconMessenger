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
      configureTitileViewWithOnlineStatus()
    }
  }
  
  var startingFrame: CGRect?
  var blackBackgroundView:ImageViewBackgroundView! = nil
  var startingImageView: UIImageView?
  var zoomingImageView: UIImageView!
  let zoomOutGesture = UITapGestureRecognizer(target: self, action: #selector(handleZoomOut))
  
  var userMessagesLoadingReference: DatabaseQuery!
  
  var messagesLoadingReference: DatabaseReference!
  
  var typingIndicatorReference: DatabaseReference!
  
  var userStatusReference: DatabaseReference!
  
  var messages = [Message]()
  
  //var mediaMessages = [Message]()
  
  var sections = ["Messages"]
  
  let messagesToLoad = 50
  
  var mediaPickerController = MediaPickerController()
  
  var inputTextViewTapGestureRecognizer = UITapGestureRecognizer()
  
  let messageSendingProgressBar = UIProgressView(progressViewStyle: .bar)

  
  func startCollectionViewAtBottom () {
    
    let collectionViewInsets: CGFloat = (collectionView!.contentInset.bottom + collectionView!.contentInset.top)// + inputContainerView.inputTextView.frame.height
    
    let contentSize = self.collectionView?.collectionViewLayout.collectionViewContentSize
    if Double(contentSize!.height) > Double(self.collectionView!.bounds.size.height) {
      let targetContentOffset = CGPoint(x: 0.0, y: contentSize!.height - (self.collectionView!.bounds.size.height - collectionViewInsets))
      self.collectionView?.contentOffset = targetContentOffset
    }
  }
  
  
  var messagesIds = [String]()
  
  var appendingMessages = [Message]()
  
 
  fileprivate var isInitialLoad = true
  
  func loadMessages() {
    
    guard let uid = Auth.auth().currentUser?.uid,let toId = user?.id else {
      return
    }
    
    userMessagesLoadingReference = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(messagesToLoad))
    userMessagesLoadingReference?.keepSynced(true)
    userMessagesLoadingReference?.observeSingleEvent(of: .value, with: { (snapshot) in
      
    if snapshot.exists() {
  
      self.userMessagesLoadingReference?.observe( .childAdded, with: { (snapshot) in
        
        self.messagesIds.append(snapshot.key)
        let messageUID = snapshot.key
    
        self.messagesLoadingReference = Database.database().reference().child("messages").child(snapshot.key)
        self.messagesLoadingReference.keepSynced(true)
        self.messagesLoadingReference.observeSingleEvent(of: .value, with: { (snapshot) in
        
          guard var dictionary = snapshot.value as? [String: AnyObject] else {
            return
          }
          dictionary.updateValue(messageUID as AnyObject, forKey: "messageUID")
          
          
          if self.isInitialLoad {
            
            self.appendingMessages.append(Message(dictionary: dictionary))
            
//            if Message(dictionary: dictionary).imageUrl != nil || Message(dictionary: dictionary).videoUrl != nil {
//              self.mediaMessages.append(Message(dictionary: dictionary))
//            }
            
            if self.appendingMessages.count == self.messagesIds.count {
              
              self.appendingMessages.sort(by: { (message1, message2) -> Bool in
                
                return message1.timestamp!.int32Value < message2.timestamp!.int32Value
              })
              
              self.delegate?.messagesLoader(didFinishLoadingWith: self.appendingMessages)
              
              DispatchQueue.main.async {
            
                self.observeTypingIndicator()
                self.updateMessageStatus(messageRef: self.messagesLoadingReference)
                self.updateMessageStatusUI(dictionary: dictionary)
              }
              
              self.isInitialLoad = false
              return
            }
          } else {
          
            if Message(dictionary: dictionary).fromId == uid || Message(dictionary: dictionary).fromId == Message(dictionary:dictionary).toId { /* outbox */
              
              self.updateMessageStatus(messageRef: self.messagesLoadingReference)
              
              self.updateMessageStatusUI(dictionary: dictionary)
            
              SystemSoundID.playFileNamed(fileName: "sent", withExtenstion: "caf")
             
              return
            }
          
          
            if Message(dictionary: dictionary).toId == uid {
              
              self.collectionView?.performBatchUpdates ({
              
                self.messages.append(Message(dictionary: dictionary))
                
//                if Message(dictionary: dictionary).imageUrl != nil || Message(dictionary: dictionary).videoUrl != nil {
//                  self.mediaMessages.append(Message(dictionary: dictionary))
//                }
              
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
                
                  self.updateMessageStatusUI(dictionary: dictionary)
                
                return
              })
            }
          }
      }, withCancel: { (error) in
        print("error loading message")
      })
      
    }, withCancel: { (error) in
      print("error loading message iDS")
    })
        
      } else {
        self.delegate?.messagesLoader(didFinishLoadingWith: self.messages)
      }
    })
  }
  
  
  var queryStartingID = String()
  var queryEndingID = String()
  
  func loadPreviousMessages() {
    
    let numberOfMessagesToLoad = messages.count + messagesToLoad
    let nextMessageIndex = messages.count + 1
    
    guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
      return
    }
    
    let startingIDRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(numberOfMessagesToLoad))
    startingIDRef.observeSingleEvent(of: .childAdded, with: { (snapshot) in
      
      if snapshot.exists() {
        self.queryStartingID = snapshot.key
        print(self.queryStartingID)
      }
      
      let endingIDRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(nextMessageIndex))
      endingIDRef.observeSingleEvent(of: .childAdded, with: { (snapshot) in
        self.queryEndingID = snapshot.key
        print(self.queryEndingID)
        
        if self.queryStartingID == self.queryEndingID {
          self.refreshControl.endRefreshing()
          print("ALL messages downloaded")
          return
        }
        var userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryOrderedByKey()
          userMessagesRef = userMessagesRef.queryStarting(atValue: self.queryStartingID).queryEnding(atValue: self.queryEndingID)
          userMessagesRef.observe(.childAdded, with: { (snapshot) in
          self.messagesIds.append(snapshot.key)
          
          let messagesRef = Database.database().reference().child("messages").child(snapshot.key)
          messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
              return
            }
            
            self.messages.append(Message(dictionary: dictionary))
            
//            if Message(dictionary: dictionary).imageUrl != nil || Message(dictionary: dictionary).videoUrl != nil {
//              self.mediaMessages.append(Message(dictionary: dictionary))
//            }
            
            if self.messages.count == self.messagesIds.count {
              
              var arrayWithShiftedMessages = self.messages
              
              let shiftingIndex = self.messagesToLoad - (numberOfMessagesToLoad - self.messagesIds.count )
              print(-shiftingIndex, "shifting index")
              
              arrayWithShiftedMessages.shiftInPlace(withDistance: -shiftingIndex)
              
              self.messages = arrayWithShiftedMessages
              userMessagesRef.removeAllObservers()
              
              contentSizeWhenInsertingToTop = self.collectionView?.contentSize
              isInsertingCellsToTop = true
              self.refreshControl.endRefreshing()
              DispatchQueue.main.async {
                self.collectionView?.reloadData()
              }
              
            } // if self.messages.count == numberOfMessagesToLoad
            
          }, withCancel: { (error) in
            
            print("error loading messages (Message)")
            
          }) // messagesRef
          
        }) { (error) in
          
          print("error loading user-messages (ID's)")
          
        } // error
        
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
      
      sendTypingStatus(data: typingData)
    }
  }
  
  
  func sendTypingStatus(data: NSDictionary) {
    
    guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
      return
    }
    
    let userIsTypingRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(typingIndicatorDatabaseID)
    userIsTypingRef.setValue(data)
  }
  
  
  func observeTypingIndicator () {
    
    guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
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
        
        let indexPath = IndexPath(row: 0, section: 1)
        
        let isIndexPathValid = self.indexPathIsValid(indexPath: indexPath as NSIndexPath)
        
        if isIndexPathValid && self.isScrollViewAtTheBottom {
          
          DispatchQueue.main.async {
            self.collectionView?.scrollToItem(at: indexPath , at: .bottom, animated: true)
          }
          
        } else {
          
          return
        }
      })
      
    } else {
      
      self.collectionView?.performBatchUpdates ({
        
        self.sections = ["Messages"]
        
        if self.collectionView!.numberOfSections > 1 {
          self.collectionView?.deleteSections(sectionsIndexSet)
        }
      }, completion: nil)
    }
  }
  
  
  func indexPathIsValid(indexPath: NSIndexPath) -> Bool {
    if indexPath.section >= self.numberOfSections(in: collectionView!) {
      return false
    }
    if indexPath.row >= collectionView!.numberOfItems(inSection: indexPath.section) {
      return false
    }
    return true
  }
  

  fileprivate func updateMessageStatus(messageRef: DatabaseReference) {
    
    if currentReachabilityStatus != .notReachable {
      
      var recieverID = String()
      
      messageRef.child("toId").observeSingleEvent(of: .value, with: { (snapshot) in
        
        if snapshot.exists() {

          recieverID = snapshot.value as! String
        }
        
        if (Auth.auth().currentUser?.uid)! == recieverID && (Auth.auth().currentUser?.uid != nil)  {
          
          if self.navigationController?.visibleViewController is ChatLogController {
          
             messageRef.updateChildValues(["seen" : true], withCompletionBlock: { (error, reference) in
              self.resetBadgeForReciever()
             }) //updateChildValues(["seen" : true])
          }
          
        } else {
          
           recieverID = ""
        }
      })
    }
  }
  
  
  func updateMessageStatusUI(dictionary: [String : AnyObject]) {
    
    if let lastMessageStatus = dictionary["status"] as? String {
      
      self.messages[self.messages.count - 1].status = lastMessageStatus
      
      if self.messages.count - 1 >= 0 {
        
        self.collectionView?.reloadItems(at: [IndexPath(row: self.messages.count-1 ,section: 0)])
        print("value")
      }
    }
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCollectionView()
    setupProgressBar()
    setRightBarButtonItem()
  }

  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
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
  
  
  func setupProgressBar() {
  
    let pSetY = CGFloat(64)
    messageSendingProgressBar.frame = CGRect(x: 0, y: pSetY, width: deviceScreen.width, height: 5)
    self.view.addSubview(messageSendingProgressBar)
  }
  

  fileprivate func setupCollectionView () {
    inputTextViewTapGestureRecognizer = UITapGestureRecognizer(target: inputContainerView.chatLogController, action: #selector(ChatLogController.toggleTextView))
    inputTextViewTapGestureRecognizer.delegate = inputContainerView
    view.backgroundColor = .white
    collectionView?.delaysContentTouches = false
    collectionView?.frame = CGRect(x: 0, y: 64, width: view.frame.width, height: view.frame.height - inputContainerView.frame.height - 64)
    collectionView?.keyboardDismissMode = .interactive
    collectionView?.backgroundColor = UIColor.white
    collectionView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
    automaticallyAdjustsScrollViewInsets = false
    collectionView?.alwaysBounceVertical = true
    
    collectionView?.addSubview(refreshControl)
    collectionView?.register(IncomingTextMessageCell.self, forCellWithReuseIdentifier: incomingTextMessageCellID)
    collectionView?.register(OutgoingTextMessageCell.self, forCellWithReuseIdentifier: outgoingTextMessageCellID)
    collectionView?.register(TypingIndicatorCell.self, forCellWithReuseIdentifier: typingIndicatorCellID)
    collectionView?.register(PhotoMessageCell.self, forCellWithReuseIdentifier: photoMessageCellID)
    collectionView?.register(IncomingPhotoMessageCell.self, forCellWithReuseIdentifier: incomingPhotoMessageCellID)
    collectionView?.registerNib(UINib(nibName: "TimestampView", bundle: nil), forRevealableViewReuseIdentifier: "timestamp")
  }
  
  
  func configureTitileViewWithOnlineStatus() {
    userStatusReference = Database.database().reference().child("users").child(user!.id!).child("OnlineStatus")
    userStatusReference.observe(.value, with: { (snapshot) in
      
      guard let uid = Auth.auth().currentUser?.uid,let toId = self.user?.id else {
        return
      }
      
      if uid == toId {
         self.navigationItem.setTitle(title: self.user!.name!, subtitle: "You")
        return
      }
      
      if snapshot.exists() {
        if snapshot.value as! String == "Online" {
          self.navigationItem.setTitle(title: self.user!.name!, subtitle: "Online")
        } else {
          self.navigationItem.setTitle(title: self.user!.name!, subtitle: ("Last seen " + (snapshot.value as! String).doubleValue.getDateStringFromUTC()))
        }
      }
    })
  }
  
  
  func setRightBarButtonItem () {
    
    let infoButton = UIButton(type: .infoLight)
    
   // infoButton.addTarget(self, action: #selector(getInfoAction), for: .touchUpInside)
    
    let infoBarButtonItem = UIBarButtonItem(customView: infoButton)

    navigationItem.rightBarButtonItem = infoBarButtonItem
  }
  
  
  lazy var inputContainerView: ChatInputContainerView = {
    var chatInputContainerView = ChatInputContainerView(frame: CGRect.zero)
    let height = chatInputContainerView.inputTextView.frame.height
    chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
    chatInputContainerView.chatLogController = self
    
    return chatInputContainerView
  }()
  
  
  var canRefresh = true
  
  fileprivate var isScrollViewAtTheBottom = true
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    if collectionView!.contentOffset.y >= (collectionView!.contentSize.height - collectionView!.frame.size.height - 200) {
      isScrollViewAtTheBottom = true
    } else {
      isScrollViewAtTheBottom = false
    }
    if scrollView.contentOffset.y < 0 { //change 100 to whatever you want
      
      if collectionView!.contentSize.height < UIScreen.main.bounds.height - 50 {
        canRefresh = false
        refreshControl.endRefreshing()
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
  
  
  func performRefresh () {
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
    return cell
  }
  
  
  fileprivate func selectCell(for indexPath: IndexPath) -> RevealableCollectionViewCell? {
    
    let message = messages[indexPath.item]
    
    if let messageText = message.text { /* If current message is a text message */
      
      if message.fromId == Auth.auth().currentUser?.uid { /* Outgoing message with blue bubble */
      
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: outgoingTextMessageCellID, for: indexPath) as! OutgoingTextMessageCell
        
        UIView.performWithoutAnimation {
          
          cell.textView.text = messageText
          
          cell.bubbleView.frame = CGRect(x: view.frame.width - estimateFrameForText(messageText).width - 35,
                                         y: 0,
                                         width: estimateFrameForText(messageText).width + 30,
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
        
            cell.bubbleView.frame.size = CGSize(width: estimateFrameForText(messageText).width + 30,
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
        
        cell.message = message
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
        
        if let image = message.localImage {
          
          cell.messageImageView.image = image
          cell.progressView.isHidden = true
          cell.messageImageView.isUserInteractionEnabled = true
          
          cell.playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
          
          return cell
        }
        
        if let messageImageUrl = message.imageUrl {
          cell.progressView.isHidden = false
          cell.messageImageView.sd_setImage(with: URL(string: messageImageUrl), placeholderImage: nil, options:  [.continueInBackground, .lowPriority], progress: { (downloadedSize, expectedSize) in
            
            let progress = Double(100 * downloadedSize/expectedSize)
            
            cell.progressView.setProgress(progress * 0.01, animated: false)
            
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
        
        cell.message = message
        
        cell.bubbleView.frame.size.height = cell.frame.size.height.rounded()
        
        DispatchQueue.main.async {
          
          if let view = self.collectionView?.dequeueReusableRevealableView(withIdentifier: "timestamp") as? TimestampView {
            
            view.titleLabel.text = message.timestamp?.doubleValue.getTimeStringFromUTC() // configure
            
            cell.setRevealableView(view, style: .over , direction: .left)
          }
        }
        
        cell.messageImageView.isUserInteractionEnabled = false
        
        if let image = message.localImage {
          
          cell.messageImageView.image = image
          cell.progressView.isHidden = true
          cell.messageImageView.isUserInteractionEnabled = true
          
          cell.playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
          
          return cell
        }
        
        if let messageImageUrl = message.imageUrl {
          cell.progressView.isHidden = false
          cell.messageImageView.sd_setImage(with: URL(string: messageImageUrl), placeholderImage: nil, options:  [.continueInBackground, .lowPriority], progress: { (downloadedSize, expectedSize) in
            
            let progress = Double(100 * downloadedSize/expectedSize)
            
            cell.progressView.setProgress(progress * 0.01, animated: false)
            
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
  
  deinit {
    print("\n chatlog controller deinit \n")
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    collectionView?.collectionViewLayout.invalidateLayout()
  }
  
  
  fileprivate var cellHeight: CGFloat = 80
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    if indexPath.section == 0 {
      let message = messages[indexPath.row]
      
      if let text = message.text {
        
        cellHeight = estimateFrameForText(text).height + 20
        
      } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
        
        cellHeight = CGFloat(imageHeight / imageWidth * 200).rounded()
      }
      
      return CGSize(width: deviceScreen.width, height: cellHeight)
      
    } else {
      
      return CGSize(width: deviceScreen.width, height: 40)
    }
  }
  
  
  func estimateFrameForText(_ text: String) -> CGRect {
    let size = CGSize(width: 200, height: 10000)
    let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
    return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13)], context: nil).integral
  }
  
  
  var containerViewBottomAnchor: NSLayoutConstraint?
  
  func handleSend() {
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
  }
  

  func handleMediaMessageSending () {
    
    if !inputContainerView.selectedMedia.isEmpty {
      let selectedMedia = inputContainerView.selectedMedia
      
      let selected = mediaPickerController.customMediaPickerView.collectionView.indexPathsForSelectedItems
      
      
      for indexPath in selected!  {
        mediaPickerController.customMediaPickerView.collectionView.deselectItem(at: indexPath, animated: false)
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
        self.messageSendingProgressBar.setProgress(0.25, animated: true)
       
       }, completion: nil)
      
      let defaultMessageStatus = messageStatusSent
      
      let toId = user!.id!
      
      let fromId = Auth.auth().currentUser!.uid
      
      let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
      
      for selectedMedia in selectedMedia {
        
        if selectedMedia.phAsset?.mediaType == PHAssetMediaType.image || selectedMedia.phAsset == nil {
          
          let values: [String: AnyObject] = ["toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "seen": false as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp, "localImage": selectedMedia.object!.asUIImage!, "imageWidth":selectedMedia.object!.asUIImage!.size.width as AnyObject, "imageHeight": selectedMedia.object!.asUIImage!.size.height as AnyObject]
          
          reloadCollectionViewAfterSending(values: values)
          
          uploadToFirebaseStorageUsingImage(selectedMedia.object!.asUIImage!, completion: { (imageURL) in
            self.sendMessageWithImageUrl(imageURL, image: selectedMedia.object!.asUIImage!)
            
            percentCompleted += CGFloat(1.0)/CGFloat(uploadingMediaCount)
           
            self.messageSendingProgressBar.setProgress(Float(percentCompleted), animated: true)
            
            if percentCompleted == 1.0 {
              DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                self.messageSendingProgressBar.setProgress(0.0, animated: false)
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
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
              
              self.messageSendingProgressBar.setProgress(Float(percentCompleted), animated: true)
              
              if percentCompleted == 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                  self.messageSendingProgressBar.setProgress(0.0, animated: false)
                  self.view.setNeedsLayout()
                  self.view.layoutIfNeeded()
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
    
    self.inputContainerView.inputTextView.text = nil
    
    let ref = Database.database().reference().child("messages")
    
    let childRef = ref.childByAutoId()
    
    let defaultMessageStatus = messageStatusSent
    
    let toId = user!.id!
    
    let fromId = Auth.auth().currentUser!.uid
    
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
    
    self.collectionView?.performBatchUpdates ({
      
      self.messages.append(Message(dictionary: values ))
      
      let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
   
      self.messages[indexPath.item].status = messageStatusSending
      
      self.collectionView?.insertItems(at: [indexPath])
      
      if self.messages.count - 2 >= 0 {
        
          self.collectionView?.reloadItems(at: [IndexPath(row: self.messages.count-2 ,section:0)])
      }
      
      let indexPath1 = IndexPath(item: self.messages.count - 1, section: 0)
      
      DispatchQueue.main.async {
        
        self.collectionView?.scrollToItem(at: indexPath1, at: .bottom, animated: true)
      }
      
    }, completion: nil)
  }
  
  
  fileprivate func sendMessageWithProperties(_ properties: [String: AnyObject]) {
    
    self.inputContainerView.inputTextView.text = nil
    
    let ref = Database.database().reference().child("messages")
    
    let childRef = ref.childByAutoId()
    
    let defaultMessageStatus = messageStatusSent
    
    guard let toId = user?.id else {
      return
    }
    
    let fromId = Auth.auth().currentUser!.uid
    
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
    }
  }
  
  
  func resetBadgeForReciever() {
    
    let toId = user!.id!
    
    let fromId = Auth.auth().currentUser!.uid
    
    let badgeRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(messageMetaDataFirebaseFolder).child("badge")
    
    badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
      var value = mutableData.value as? Int
      
      value = 0
      
      mutableData.value = value!
      return TransactionResult.success(withValue: mutableData)
    })
    
  }
  
  
  func incrementBadgeForReciever() {
    
    let toId = user!.id!
    
    let fromId = Auth.auth().currentUser!.uid
    
    var ref = Database.database().reference().child("user-messages").child(toId).child(fromId)
    ref.observeSingleEvent(of: .value, with: { (snapshot) in
      
      
      if snapshot.hasChild(messageMetaDataFirebaseFolder) {
        
        print("true rooms exist")
        
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
        
        print("false room doesn't exist")
        
        ref = ref.child(messageMetaDataFirebaseFolder)
        ref.updateChildValues(["badge": 1], withCompletionBlock: { (error, reference) in
          
        })
      }
    })
  }
}
