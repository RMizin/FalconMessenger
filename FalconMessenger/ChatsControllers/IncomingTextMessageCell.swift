//
//  IncomingTextMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SafariServices


class IncomingTextMessageCell: BaseMessageCell {
  
  let textView: FalconTextView = {
    let textView = FalconTextView()
    textView.font = MessageFontsAppearance.defaultMessageTextFont
    textView.backgroundColor = .clear
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsetsMake(textViewTopInset, incomingTextViewLeftInset, textViewBottomInset, incomingTextViewRightInset)
    textView.dataDetectorTypes = .all
    textView.textColor = .darkText
    textView.linkTextAttributes = [NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue]
    
    return textView
  }()
  
  func setupData(message: Message, isGroupChat: Bool) {
    
    self.message = message
    guard let messageText = message.text else { return }
    textView.text = messageText
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.sizeToFit()
      
      if message.estimatedFrameForText!.width < nameLabel.frame.size.width {
        
        if nameLabel.frame.size.width >= BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth {
          nameLabel.frame.size.width = BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth
          bubbleView.frame.size = CGSize(width: BaseMessageCell.bubbleViewMaxWidth, height: frame.size.height.rounded())
        } else {
          bubbleView.frame.size = CGSize(width: (nameLabel.frame.size.width + BaseMessageCell.incomingMessageHorisontalInsets).rounded(), height: frame.size.height.rounded())
        }
      } else {
        bubbleView.frame.size = CGSize(width: (message.estimatedFrameForText!.width + BaseMessageCell.incomingMessageHorisontalInsets).rounded(), height: frame.size.height.rounded())
      }
      
      textView.textContainerInset.top = BaseMessageCell.groupIncomingTextViewTopInset
      textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: bubbleView.frame.height.rounded())
      
    } else {
      let width = (message.estimatedFrameForText!.width + BaseMessageCell.incomingMessageHorisontalInsets).rounded()
      bubbleView.frame.size = CGSize(width: width, height: frame.size.height.rounded())
      textView.frame.size = CGSize(width: bubbleView.frame.width, height: bubbleView.frame.height)
    }
    setupTimestampView(message: message, isOutgoing: false)
    
    if let isCrooked = self.message?.isCrooked, isCrooked {
      bubbleView.image = ThemeManager.currentTheme().incomingBubble
    } else {
      bubbleView.image = ThemeManager.currentTheme().incomingPartialBubble
    }
  }
  
  override func setupViews() {
    textView.delegate = self
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textView)
    textView.addSubview(nameLabel)
    bubbleView.frame.origin = BaseMessageCell.incomingBubbleOrigin
  }
  
  override func prepareViewsForReuse() {
    bubbleView.image = nil
    nameLabel.text = ""
  }
}

extension IncomingTextMessageCell: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    guard interaction != .preview else { return false }
    guard ["http", "https"].contains(URL.scheme?.lowercased() ?? "")  else { return true }
    var svc = SFSafariViewController(url: URL as URL)
    
    if #available(iOS 11.0, *) {
      let configuration = SFSafariViewController.Configuration()
      configuration.entersReaderIfAvailable = true
      svc = SFSafariViewController(url: URL as URL, configuration: configuration)
    }
    
    svc.preferredControlTintColor = FalconPalette.defaultBlue
    svc.preferredBarTintColor = ThemeManager.currentTheme().generalBackgroundColor
    chatLogController?.present(svc, animated: true, completion: nil)
    
    return false
  }
}
