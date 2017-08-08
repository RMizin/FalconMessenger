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


class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  
  var user: User? {
    didSet {
     // loadMessages()
      self.title = user?.name
      //setNavifationTitle(username: user?.name)
    }
  }


  var messages = [Message]()
  
  var sections = ["Messages"]
  
  fileprivate var refreshControlCanRefresh = true
  
  fileprivate var isScrollViewAtTheBottom = true
  
  
  
  var containerViewBottomAnchor: NSLayoutConstraint?
  
  lazy var inputContainerView: ChatInputContainerView = {
    var chatInputContainerView = ChatInputContainerView(frame: CGRect.zero)
    
    let height = chatInputContainerView.inputTextView.frame.height
    chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
    chatInputContainerView.chatLogController = self
    
    return chatInputContainerView
  }()
  
  let refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    refreshControl.addTarget(self, action: #selector(performRefresh), for: .valueChanged)
    
    return refreshControl
    
  }()
  
  
  func performRefresh () {}
  

  override func viewDidLoad() {
      super.viewDidLoad()
   
    setupCollectionView()
    setupKeyboardObservers()
    
  }
  
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    NotificationCenter.default.removeObserver(self)
    //isTyping = false
  }
  
  
  override var inputAccessoryView: UIView? {
    get {
      return inputContainerView
    }
  }
  
  override var canBecomeFirstResponder : Bool {
    return true
  }
  
  
  fileprivate func setupCollectionView () {
    
   let autoSizingCollectionViewFlowLayout = AutoSizingCollectionViewFlowLayout()
    collectionView?.collectionViewLayout = autoSizingCollectionViewFlowLayout
    autoSizingCollectionViewFlowLayout.minimumLineSpacing = 5
    
    collectionView?.keyboardDismissMode = .interactive
    collectionView?.backgroundColor = UIColor.white
    collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)
    collectionView?.alwaysBounceVertical = true
    collectionView?.addSubview(refreshControl)
    
    collectionView?.register(IncomingTextMessageCell.self, forCellWithReuseIdentifier: incomingTextMessageCellID)
    collectionView?.register(OutgoingTextMessageCell.self, forCellWithReuseIdentifier: outgoingTextMessageCellID)

  }
  
  fileprivate func setNavifationTitle (username: String?) {
    let titleLabel = UILabel(frame: CGRect(x:0, y:0, width: 200, height: 40))
    titleLabel.text = username
    titleLabel.textColor = UIColor.black
    titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    titleLabel.backgroundColor = UIColor.clear
    titleLabel.adjustsFontSizeToFitWidth = true
    titleLabel.textAlignment = .center
    self.navigationItem.titleView = titleLabel
  }
  
  
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    if collectionView!.contentOffset.y >= (collectionView!.contentSize.height - collectionView!.frame.size.height) {
      isScrollViewAtTheBottom = true
    } else {
      isScrollViewAtTheBottom = false
    }
    if scrollView.contentOffset.y < 0 { //change 100 to whatever you want
      
      if collectionView!.contentSize.height < UIScreen.main.bounds.height - 50 {
        refreshControlCanRefresh = false
        refreshControl.endRefreshing()
      }
      
      if refreshControlCanRefresh && !refreshControl.isRefreshing {
        
        refreshControlCanRefresh = false
        
        refreshControl.beginRefreshing()
        
        performRefresh()
      }
      
    } else if scrollView.contentOffset.y >= 0 {
      refreshControlCanRefresh = true
    }
  }
  
  
  func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
  }
  
  
  func handleKeyboardDidShow() {
    if messages.count > 0 {
      
      let indexPath = IndexPath(item: messages.count - 1, section: 0)
      collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
    }
  }
  
  
  
  func handleKeyboardWillShow(_ notification: Notification) {
    let keyboardFrame = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
    let keyboardDuration = ((notification as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
    
    containerViewBottomAnchor?.constant = -keyboardFrame!.height
    
    UIView.animate(withDuration: keyboardDuration!, animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  
  func handleKeyboardWillHide(_ notification: Notification) {
    let keyboardDuration = ((notification as NSNotification).userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
    
    containerViewBottomAnchor?.constant = 0
    
    UIView.animate(withDuration: keyboardDuration!, animations: {
      self.view.layoutIfNeeded()
    })
  }


  
    // MARK: UICollectionViewDataSource

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
   // if indexPath.section == 0 {
      //return selectCell(for: indexPath)!
   // } else {
      //return showTypingIndicator(indexPath: indexPath)!
   // }
    return selectCell(for: indexPath)!
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
          
        return cell
          
        } else {/* Incoming message with grey bubble */
          let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: incomingTextMessageCellID, for: indexPath) as! IncomingTextMessageCell
          
          cell.bubbleView.frame = CGRect(x: 10,
                                         y: 0,
                                         width: estimateFrameForText(messageText).width + 30,
                                         height: cell.frame.size.height).integral

          
          cell.textView.text = messageText
          
          return cell
        }
      }
    
    
    return nil
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
  
  
  
  
  
  
  
  func handleSend() {
    
    inputContainerView.sendButton.isEnabled = false
    let properties = ["text": inputContainerView.inputTextView.text!]
    sendMessageWithProperties(properties as [String : AnyObject])
    
  //  isTyping = false
    inputContainerView.placeholderLabel.isHidden = false
    inputContainerView.invalidateIntrinsicContentSize()
  }
  
  
  fileprivate func sendMessageWithProperties(_ properties: [String: AnyObject]) {
    
    self.inputContainerView.inputTextView.text = nil
    
    let ref = Database.database().reference().child("messages")
    
    let childRef = ref.childByAutoId()
    
    let defaultMessageStatus = "Отправлено"
    
    let toId = user!.id!
    
    let fromId = Auth.auth().currentUser!.uid
    
    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
    
    
    var values: [String: AnyObject] = ["toId": toId as AnyObject, "status": defaultMessageStatus as AnyObject , "fromId": fromId as AnyObject, "timestamp": timestamp]
    
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
      
      //self.newOutboxMessage = true
      
      userMessagesRef.updateChildValues([messageId: 1])
      
      let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId).child(userMessagesFirebaseFolder)
      
      recipientUserMessagesRef.updateChildValues([messageId: 1])
    }
  }
  
  
  fileprivate func reloadCollectionViewAfterSending(values: [String: AnyObject]) {
    
    
    self.collectionView?.performBatchUpdates({
      self.messages.append(Message(dictionary: values ))
      let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
      self.collectionView?.insertItems(at: [indexPath])
      
      if self.messages.count - 2 >= 0 {
        self.collectionView?.reloadItems(at: [IndexPath(row: self.messages.count-2 ,section:0)])
      }
     // messageStatus.text = ""
      
    }, completion: { (true) in
      let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
      self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
    })
  }
}


