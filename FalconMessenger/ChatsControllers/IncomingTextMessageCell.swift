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
  
  lazy var textView: FalconTextView = {
    let textView = FalconTextView()
    textView.textColor = ThemeManager.currentTheme().incomingBubbleTextColor
    textView.textContainerInset =  UIEdgeInsets(top: BaseMessageCell.textViewTopInset,
                                                left: BaseMessageCell.incomingTextViewLeftInset,
                                                bottom: BaseMessageCell.textViewBottomInset,
                                                right: BaseMessageCell.incomingTextViewRightInset)
    return textView
  }()
  
  override func setupViews() {
    super.setupViews()
    textView.delegate = self
    bubbleView.addSubview(textView)
    textView.addSubview(nameLabel)
    bubbleView.addSubview(timeLabel)
    
    bubbleView.frame.origin = BaseMessageCell.incomingBubbleOrigin
    timeLabel.backgroundColor = .clear
    timeLabel.textColor = UIColor.darkGray.withAlphaComponent(0.7)
    bubbleView.tintColor = ThemeManager.currentTheme().incomingBubbleTintColor
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    bubbleView.tintColor = ThemeManager.currentTheme().incomingBubbleTintColor
    textView.textColor = ThemeManager.currentTheme().incomingBubbleTextColor
  }

  func setupData(message: Message, isGroupChat: Bool) {
    guard let messageText = message.text else { return }
    textView.text = messageText
    
    if isGroupChat {
      nameLabel.text = message.senderName ?? ""
      nameLabel.sizeToFit()
      bubbleView.frame.size = setupGroupBubbleViewSize(message: message)
      
      textView.textContainerInset.top = BaseMessageCell.groupIncomingTextViewTopInset
      textView.frame.size = CGSize(width: bubbleView.frame.width.rounded(), height: bubbleView.frame.height.rounded())
    } else {
      bubbleView.frame.size = setupDefaultBubbleViewSize(message: message)
      textView.frame.size = CGSize(width: bubbleView.frame.width, height: bubbleView.frame.height)
    }
    
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width,
                                     y: bubbleView.frame.height-timeLabel.frame.height-5)
		timeLabel.text = message.convertedTimestamp
 
    if let isCrooked = message.isCrooked.value, isCrooked {
      bubbleView.image = ThemeManager.currentTheme().incomingBubble
    } else {
      bubbleView.image = ThemeManager.currentTheme().incomingPartialBubble
    }
  }
  
  fileprivate func setupDefaultBubbleViewSize(message: Message) -> CGSize {
    guard let portaritEstimate = message.estimatedFrameForText?.width.value,
      let landscapeEstimate = message.landscapeEstimatedFrameForText?.width.value else { return CGSize() }
    
    let portraitRect = setupFrameWithLabel(bubbleView.frame.origin.x, BaseMessageCell.bubbleViewMaxWidth,
                                           CGFloat(portaritEstimate), BaseMessageCell.incomingMessageHorisontalInsets,
                                           frame.size.height, 10).integral
    
    let landscapeRect = setupFrameWithLabel(bubbleView.frame.origin.x, BaseMessageCell.landscapeBubbleViewMaxWidth,
                                           CGFloat(landscapeEstimate), BaseMessageCell.incomingMessageHorisontalInsets,
                                           frame.size.height, 10).integral
    switch UIDevice.current.orientation {
    case .landscapeRight, .landscapeLeft:
      return landscapeRect.size
    default:
     return portraitRect.size
    }
  }
  
  fileprivate func setupGroupBubbleViewSize(message: Message) -> CGSize {
    guard let portaritWidth = message.estimatedFrameForText?.width.value else { return CGSize() }
    guard let landscapeWidth = message.landscapeEstimatedFrameForText?.width.value  else { return CGSize() }
    let portraitBubbleMaxW = BaseMessageCell.bubbleViewMaxWidth
    let portraitAuthorMaxW = BaseMessageCell.incomingGroupMessageAuthorNameLabelMaxWidth
    let landscapeBubbleMaxW = BaseMessageCell.landscapeBubbleViewMaxWidth
    let landscapeAuthoMaxW = BaseMessageCell.landscapeIncomingGroupMessageAuthorNameLabelMaxWidth
    
    switch UIDevice.current.orientation {
    case .landscapeRight, .landscapeLeft:
      return getGroupBubbleSize(messageWidth: CGFloat(landscapeWidth),
                                bubbleMaxWidth: landscapeBubbleMaxW,
                                authorMaxWidth: landscapeAuthoMaxW)
    default:
      return getGroupBubbleSize(messageWidth: CGFloat(portaritWidth),
                                bubbleMaxWidth: portraitBubbleMaxW,
                                authorMaxWidth: portraitAuthorMaxW)
    }
  }
  
  fileprivate func getGroupBubbleSize(messageWidth: CGFloat, bubbleMaxWidth: CGFloat, authorMaxWidth: CGFloat) -> CGSize {
    let horisontalInsets = BaseMessageCell.incomingMessageHorisontalInsets
    
    let rect = setupFrameWithLabel(bubbleView.frame.origin.x,
                                   bubbleMaxWidth,
                                   messageWidth,
                                   horisontalInsets,
                                   frame.size.height, 10).integral

    if nameLabel.frame.size.width >= rect.width - horisontalInsets {
      if nameLabel.frame.size.width >= authorMaxWidth {
        nameLabel.frame.size.width = authorMaxWidth
        return CGSize(width: bubbleMaxWidth, height: frame.size.height.rounded())
      }
      return CGSize(width: (nameLabel.frame.size.width + horisontalInsets).rounded(),
                    height: frame.size.height.rounded())
    } else {
      return rect.size
    }
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
    
    svc.preferredControlTintColor = tintColor
    svc.preferredBarTintColor = ThemeManager.currentTheme().generalBackgroundColor
    chatLogController?.inputContainerView.resignAllResponders()
    chatLogController?.present(svc, animated: true, completion: nil)
    
    return false
  }
}
