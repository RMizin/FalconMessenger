//
//  ChatLogController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

private let incomingTextMessageCellID = "incomingTextMessageCellID"

private let outgoingTextMessageCellID = "outgoingTextMessageCellID"

private let typingIndicatorCellID = "typingIndicatorCellID"

private let typingIndicatorDatabaseID = "typingIndicator"

private let typingIndicatorStateDatabaseKeyID = "Is typing"

private var messageStatus = String()

protocol MessagesLoaderDelegate: class {
  func messagesLoader(_ chatLogController: ChatLogController, didFinishLoadingWith messages: [Message] )
}


class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  
  weak var delegate: MessagesLoaderDelegate?
  
  var user: User? {
    didSet {
      loadMessages()
      self.title = user?.name
    }
  }
  
  var messages = [Message]()
  
  var sections = ["Messages"]
  
  let messagesToLoad = 50
  
  var mediaPickerController = MediaPickerController()
  
  var inputTextViewTapGestureRecognizer = UITapGestureRecognizer()

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
  
  var newOutboxMessage = false
  
  var newInboxMessage = false
  
 
  func loadMessages() {
    
    guard let uid = Auth.auth().currentUser?.uid,let toId = user?.id else {
      return
    }
    
    let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryLimited(toLast: UInt(messagesToLoad))
    userMessagesRef.keepSynced(true)
    userMessagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
      
    if snapshot.exists() {
  
   
      userMessagesRef.observe( .childAdded, with: { (snapshot) in
      self.messagesIds.append(snapshot.key)
      
        let messagesRef = Database.database().reference().child("messages").child(snapshot.key)
        messagesRef.keepSynced(true)
        messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
        
          guard let dictionary = snapshot.value as? [String: AnyObject] else {
            print("returning")
            return
          }
        
          switch true {
          
            case self.newOutboxMessage:
          
              self.updateMessageStatus(messagesRef: messagesRef)
              self.newOutboxMessage = false
          
            break
          
            case self.newInboxMessage:
          
              self.collectionView?.performBatchUpdates ({
            
                self.messages.append(Message(dictionary: dictionary))
                let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                self.collectionView?.insertItems(at: [indexPath])
            
                if self.messages.count - 2 >= 0 {
          
                  self.collectionView?.reloadItems(at: [IndexPath (row: self.messages.count - 2, section: 0)])
                }
                
                let indexPath1 = IndexPath(item: self.messages.count - 1, section: 0)
            
                if self.messages.count - 1 > 0 && self.isScrollViewAtTheBottom {
                  DispatchQueue.main.async {
                    self.collectionView?.scrollToItem(at: indexPath1, at: .bottom, animated: true)
                  }
                }
              }, completion: { (true) in
                self.updateMessageStatus(messagesRef: messagesRef)
              })
          
            break
          
          default:
          
            self.appendingMessages.append(Message(dictionary: dictionary))
          
            if self.appendingMessages.count == self.messagesIds.count {
            
              self.appendingMessages.sort(by: { (message1, message2) -> Bool in
              
                return message1.timestamp!.int32Value < message2.timestamp!.int32Value
              })
            
              self.delegate?.messagesLoader(self, didFinishLoadingWith: self.appendingMessages)
            
              DispatchQueue.main.async {
                self.newInboxMessage = true
                self.observeTypingIndicator()
                self.updateMessageStatus(messagesRef: messagesRef)
              }

              break
          }
        }
        
      }, withCancel: { (error) in
        print("error loading message")
      })
      
    }, withCancel: { (error) in
      print("error loading message iDS")
    })
        
      } else {
        self.delegate?.messagesLoader(self, didFinishLoadingWith: self.messages)
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
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(userMessagesFirebaseFolder).queryOrderedByKey()
        userMessagesRef.queryStarting(atValue: self.queryStartingID).queryEnding(atValue: self.queryEndingID).observe(.childAdded, with: { (snapshot) in
          self.messagesIds.append(snapshot.key)
          
          let messagesRef = Database.database().reference().child("messages").child(snapshot.key)
          messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
              return
            }
            
            self.messages.append(Message(dictionary: dictionary))
            
            if self.messages.count == self.messagesIds.count {
              
              var arrayWithShiftedMessages = self.messages
              
              let shiftingIndex = self.messagesToLoad - (numberOfMessagesToLoad - self.messagesIds.count )
              print(-shiftingIndex, "shifting index")
              
              arrayWithShiftedMessages.shiftInPlace(withDistance: -shiftingIndex)
              
              self.messages = arrayWithShiftedMessages
              
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
    
    let typingIndicatorRef = Database.database().reference().child("user-messages").child(uid).child(toId).child(typingIndicatorDatabaseID)
    typingIndicatorRef.onDisconnectRemoveValue()
    
    let userTypingToRef = Database.database().reference().child("user-messages").child(toId).child(uid).child(typingIndicatorDatabaseID).child(typingIndicatorStateDatabaseKeyID)
    userTypingToRef.onDisconnectRemoveValue()
    userTypingToRef.observe( .value, with: { (isTyping) in
      
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
  
  
  fileprivate func updateMessageStatus(messagesRef: DatabaseReference) {
    
    if currentReachabilityStatus != .notReachable {
      
      var recieverID = String()
      
      messagesRef.child("toId").observeSingleEvent(of: .value, with: { (snapshot) in
        
        if snapshot.exists() {

          recieverID = snapshot.value as! String
        }
        
        if (Auth.auth().currentUser?.uid)! == recieverID {
          if self.navigationController?.visibleViewController is ChatLogController {
          
            messagesRef.updateChildValues(["seen" : true])
          }
          
        } else {

            recieverID = ""
        }
      })
    
      messagesRef.child("status") .observe(.value, with: { (messageStatusValue) in
        
        if let lastMessageStatus = messageStatusValue.value as? String {
          messageStatus = lastMessageStatus
          
          if self.messages.count - 1 >= 0 {
             self.collectionView?.reloadItems(at: [IndexPath(row: self.messages.count-1 ,section: 0)])
          }
          
        }
      })
      
      messagesRef.observe(.childChanged, with: { (snapshot) in
        
        if Auth.auth().currentUser?.uid != self.user!.id {
          
          if snapshot.value != nil && snapshot.key == "status" {
            
            let status = snapshot.value as! String
            
            messageStatus = status
    
            self.collectionView?.reloadItems(at: [IndexPath(row: self.messages.count-1 ,section:0)])
          }
        }
      })
    }
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCollectionView()
  }
  
 
  fileprivate func setupCollectionView () {
    inputTextViewTapGestureRecognizer = UITapGestureRecognizer(target: inputContainerView.chatLogController, action: #selector(ChatLogController.toggleTextView))
    inputTextViewTapGestureRecognizer.delegate = inputContainerView
    view.backgroundColor = .white
    collectionView?.delaysContentTouches = false
    collectionView?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - inputContainerView.frame.height)
    collectionView?.keyboardDismissMode = .interactive
    collectionView?.backgroundColor = UIColor.white
    collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)
    collectionView?.alwaysBounceVertical = true
    collectionView?.addSubview(refreshControl)
    collectionView?.register(IncomingTextMessageCell.self, forCellWithReuseIdentifier: incomingTextMessageCellID)
    collectionView?.register(OutgoingTextMessageCell.self, forCellWithReuseIdentifier: outgoingTextMessageCellID)
    collectionView?.register(TypingIndicatorCell.self, forCellWithReuseIdentifier: typingIndicatorCellID)
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
  
  //handle upload tap
  
  override var inputAccessoryView: UIView? {
    get {
      return inputContainerView
    }
  }
  
  
  override var canBecomeFirstResponder : Bool {
    return true
  }
  

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
  
    isTyping = false
    messageStatus = ""
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
      return showTypingIndicator(indexPath: indexPath)!
    }
    
  }
  
  
  fileprivate func showTypingIndicator(indexPath: IndexPath) -> UICollectionViewCell? {
    let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: typingIndicatorCellID, for: indexPath) as! TypingIndicatorCell
    return cell
  }
  
  
  fileprivate func selectCell(for indexPath: IndexPath) -> UICollectionViewCell? {
    
    let message = messages[indexPath.item]
    
    if let messageText = message.text { /* If current message is a text message */
      
      if message.fromId == Auth.auth().currentUser?.uid { /* Outgoing message with blue bubble */
        
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: outgoingTextMessageCellID, for: indexPath) as! OutgoingTextMessageCell
        
        cell.textView.text = messageText
        
        cell.bubbleView.frame = CGRect(x: view.frame.width - estimateFrameForText(messageText).width - 35,
                                       y: 0,
                                       width: estimateFrameForText(messageText).width + 30,
                                       height: cell.frame.size.height).integral
        
        cell.textView.frame.size = CGSize(width: cell.bubbleView.frame.width,
                                          height: cell.bubbleView.frame.height)
        
        cell.deliveryStatus.frame = CGRect(x: cell.frame.width - 80, y: cell.bubbleView.frame.height+2, width: 70, height: 10)

      
        switch indexPath.row == self.messages.count - 1 {
          
          case true:
            cell.deliveryStatus.text = messageStatus
            cell.deliveryStatus.isHidden = false
          break
          
          default:
            cell.deliveryStatus.isHidden = true
          break
        }
        
        return cell
        
      } else { /* Incoming message with grey bubble */
        
        let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingTextMessageCellID, for: indexPath) as! IncomingTextMessageCell
        
        cell.textView.text = messageText
        
        cell.bubbleView.frame = CGRect(x: 10,
                                       y: 0,
                                       width: estimateFrameForText(messageText).width + 30,
                                       height: cell.frame.size.height).integral
        
        cell.textView.frame.size = CGSize(width: cell.bubbleView.frame.width,
                                          height: cell.bubbleView.frame.height)

        return cell
      }
    }
    return nil
  }
  
  
  /*
  fileprivate func selectCell(for indexPath: IndexPath) -> UICollectionViewCell? {
    
    let message = messages[indexPath.item]
    
    if let messageText = message.text { /* If current message is a text message */
      
      let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: textMessageCellID, for: indexPath) as! TextMessageCell
      
      cell.textView.text = messageText
      
      if message.fromId == Auth.auth().currentUser?.uid { /* Outgoing message with blue bubble */
        
        
        if indexPath.row == messages.count-1  {
          
          cell.deliveryStatus.isHidden = false
          cell.deliveryStatus.text = messageStatus.text
        } else {
          
          cell.deliveryStatus.isHidden = true
        }
        
        cell.bubbleView.image = BaseMessageCell.blueBubbleImage
        
        cell.textView.textColor = UIColor.white
        
        cell.textView.textContainerInset.left = 7
        
        cell.bubbleView.frame = CGRect(x: view.frame.width - estimateFrameForText(messageText).width - 35,
                                       y: 0,
                                       width: estimateFrameForText(messageText).width + 30,
                                       height: cell.frame.size.height).integral
        
        
        cell.textView.frame.size = CGSize(width: cell.bubbleView.frame.width,
                                          height: cell.bubbleView.frame.height)
        
      } else { /* Incoming message with grey bubble */
        
        cell.deliveryStatus.isHidden = true
        
        cell.bubbleView.image = BaseMessageCell.grayBubbleImage
        
        cell.textView.textColor = UIColor.darkText
        
        cell.textView.textContainerInset.left = 12
        
        cell.bubbleView.frame = CGRect(x: 10,
                                       y: 0,
                                       width: estimateFrameForText(messageText).width + 30,
                                       height: cell.frame.size.height).integral
        
        cell.textView.frame.size = CGSize(width: cell.bubbleView.frame.width,
                                          height: cell.bubbleView.frame.height)
      }
      
      return cell
      
    } else if message.imageUrl != nil { /* If current message is a photo/video message */
      
      let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: photoMessageCellID, for: indexPath) as! PhotoMessageCell
      
      cell.chatLogController = self
      cell.message = message
      
      if message.fromId == Auth.auth().currentUser?.uid { /* Outgoing message with blue bubble */
        
        if indexPath.row == messages.count-1  {
          
          cell.deliveryStatus.isHidden = false
          cell.deliveryStatus.text = messageStatus.text
        } else {
          
          cell.deliveryStatus.isHidden = true
        }
        
        cell.bubbleView.frame = CGRect(x: view.frame.width - 210, y: 0, width: 200, height: cell.frame.size.height).integral
        
      } else { /* Incoming message with grey bubble */
        
        cell.deliveryStatus.isHidden = true
        
        cell.bubbleView.frame = CGRect(x: 10, y: 0, width: 200, height: cell.frame.size.height).integral
      }
      
      DispatchQueue.global(qos: .default).async(execute: {() -> Void in
        if let messageImageUrl = message.imageUrl {
          cell.messageImageView.loadImageUsingCacheWithUrlString(messageImageUrl)
        }
      })
      
      cell.playButton.isHidden = message.videoUrl == nil
      
      
      return cell
    } else {
      return nil
    }
    
  } */
  
  
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
        
        cellHeight = CGFloat(imageHeight / imageWidth * 200)
      }
      
      return CGSize(width: deviceScreen.width, height: cellHeight)
      
    } else {
      
      return CGSize(width: deviceScreen.width, height: 40)
    }
  }
  
  
  func estimateFrameForText(_ text: String) -> CGRect {
    let size = CGSize(width: 200, height: 1000)
    let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
    return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)], context: nil)
  }
  
  
  var containerViewBottomAnchor: NSLayoutConstraint?
  
  func handleSend() {
    inputContainerView.inputTextView.isScrollEnabled = false
    inputContainerView.invalidateIntrinsicContentSize()

    inputContainerView.sendButton.isEnabled = false
    let properties = ["text": inputContainerView.inputTextView.text!]
    sendMessageWithProperties(properties as [String : AnyObject])
    
    isTyping = false
    inputContainerView.placeholderLabel.isHidden = false
  }
  
  
  fileprivate func sendMessageWithImageUrl(_ imageUrl: String, image: UIImage) {
    let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": image.size.width as AnyObject, "imageHeight": image.size.height as AnyObject]
    sendMessageWithProperties(properties)
  }
  
  
  fileprivate func reloadCollectionViewAfterSending(values: [String: AnyObject]) {
    
    
    self.collectionView?.performBatchUpdates ({
      
      self.messages.append(Message(dictionary: values ))
      
      let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
      
      messageStatus = messageStatusSending
      
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
    
    let toId = user!.id!
    
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
      
      self.newOutboxMessage = true
      
      userMessagesRef.updateChildValues([messageId: 1])
      
      let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId).child(userMessagesFirebaseFolder)
      
      recipientUserMessagesRef.updateChildValues([messageId: 1])
    }
  }
  
  /*
  var startingFrame: CGRect?
  var blackBackgroundView: UIView?
  var startingImageView: UIImageView?
  
  
  func performZoomInForStartingImageView(_ startingImageView: UIImageView) {
    print("tapped")
    self.startingImageView = startingImageView
    self.startingImageView?.isHidden = true
    
    startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
    
    let zoomingImageView = UIImageView(frame: startingFrame!)
    zoomingImageView.backgroundColor = UIColor.red
    zoomingImageView.image = startingImageView.image
    zoomingImageView.isUserInteractionEnabled = true
    zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
    
    if let keyWindow = UIApplication.shared.keyWindow {
      blackBackgroundView = UIView(frame: keyWindow.frame)
      blackBackgroundView?.backgroundColor = UIColor.black
      blackBackgroundView?.alpha = 0
      keyWindow.addSubview(blackBackgroundView!)
      keyWindow.addSubview(zoomingImageView)
      
      UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
        
        self.blackBackgroundView?.alpha = 1
        self.inputContainerView.alpha = 0
        
        // math?
        // h2 / w1 = h1 / w1
        // h2 = h1 / w1 * w1
        let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
        
        zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
        
        zoomingImageView.center = keyWindow.center
        
      }, completion: { (completed) in
        // do nothing
      })
    }
  }
  
  
  func handleZoomOut(_ tapGesture: UITapGestureRecognizer) {
    if let zoomOutImageView = tapGesture.view {
      //need to animate back out to controller
      zoomOutImageView.layer.cornerRadius = 16
      zoomOutImageView.clipsToBounds = true
      
      UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
        
        zoomOutImageView.frame = self.startingFrame!
        self.blackBackgroundView?.alpha = 0
        self.inputContainerView.alpha = 1
        
      }, completion: { (completed) in
        zoomOutImageView.removeFromSuperview()
        self.startingImageView?.isHidden = false
      })
    }
  }*/
}
