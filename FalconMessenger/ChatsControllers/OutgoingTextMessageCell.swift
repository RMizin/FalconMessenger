//
//  OutgoingTextMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SafariServices


class OutgoingTextMessageCell: BaseMessageCell {
  
  let textView: FalconTextView = {
    let textView = FalconTextView()
    textView.font = MessageFontsAppearance.defaultMessageTextFont
    textView.backgroundColor = .clear
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsetsMake(textViewTopInset, outgoingTextViewLeftInset, textViewBottomInset, outgoingTextViewRightInset)
    textView.dataDetectorTypes = .all
    textView.textColor = .white
    textView.linkTextAttributes = [NSAttributedStringKey.underlineStyle.rawValue: NSUnderlineStyle.styleSingle.rawValue]

    return textView
  }()
  
  func setupData(message: Message) {
    self.message = message
    guard let messageText = message.text else { return }
    textView.text = messageText
    timeLabel.text = self.message?.convertedTimestamp
    bubbleView.frame = setupBubbleViewFrame(message: message)
    textView.frame.size = CGSize(width: bubbleView.frame.width, height: bubbleView.frame.height)
    timeLabel.frame.origin = CGPoint(x: bubbleView.frame.width-timeLabel.frame.width-5, y: bubbleView.frame.height-timeLabel.frame.height-5)
    
    if let isCrooked = self.message?.isCrooked, isCrooked {
      bubbleView.image = ThemeManager.currentTheme().outgoingBubble
    } else {
      bubbleView.image = ThemeManager.currentTheme().outgoingPartialBubble
    }
  }
  
  fileprivate func setupBubbleViewFrame(message: Message) -> CGRect {
    guard let portaritEstimate = message.estimatedFrameForText?.width, let landscapeEstimate = message.landscapeEstimatedFrameForText?.width else { return CGRect() }

    let portraitX = frame.width - portaritEstimate - BaseMessageCell.outgoingMessageHorisontalInsets - BaseMessageCell.scrollIndicatorInset
    let portraitFrame = setupFrameWithLabel(portraitX, BaseMessageCell.bubbleViewMaxWidth,
                                            portaritEstimate, BaseMessageCell.outgoingMessageHorisontalInsets, frame.size.height)
    let landscapeX = frame.width - landscapeEstimate - BaseMessageCell.outgoingMessageHorisontalInsets - BaseMessageCell.scrollIndicatorInset
    let landscapeFrame = setupFrameWithLabel(landscapeX, BaseMessageCell.landscapeBubbleViewMaxWidth,
                                             landscapeEstimate, BaseMessageCell.outgoingMessageHorisontalInsets, frame.size.height)
    switch UIDevice.current.orientation {
    case .landscapeLeft, .landscapeRight:
      return landscapeFrame
   default:
      return portraitFrame
    }
  }
  
  override func setupViews() {
    textView.delegate = self
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
    contentView.addSubview(bubbleView)
    bubbleView.addSubview(textView)
    contentView.addSubview(deliveryStatus)
    bubbleView.addSubview(timeLabel)
    timeLabel.backgroundColor = .clear
    timeLabel.textColor = .white
  }
  
  override func prepareViewsForReuse() {
     bubbleView.image = nil
  }
}

extension OutgoingTextMessageCell: UITextViewDelegate {
  
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
