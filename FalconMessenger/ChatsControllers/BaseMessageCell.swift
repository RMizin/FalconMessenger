//
//  BaseMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

struct CellSizes {

  static func timestampWidth() -> CGFloat {
    if DeviceType.IS_IPAD_PRO {
      return 80
    } else if DeviceType.isIPad {
      return 57
    } else {
      return 47
    }
  }
  
  static func bubbleViewMaxWidth() -> CGFloat {
    if DeviceType.IS_IPAD_PRO {
      return ScreenSize.minLength * 0.50
    } else if DeviceType.isIPad {
      return ScreenSize.minLength * 0.45
    } else {
      return ScreenSize.minLength * 0.75
    }
  }
  
  static func landscapeBubbleViewMaxWidth() -> CGFloat {
    if DeviceType.IS_IPAD_PRO {
      return ScreenSize.maxLength * 0.50
    } else if DeviceType.isIPad {
      return ScreenSize.maxLength * 0.50
    } else {
      return ScreenSize.maxLength * 0.75
    }
  }
  
  static func mediaMaxWidth() -> CGFloat {
    if DeviceType.IS_IPAD_PRO {
      return ScreenSize.minLength * 0.50
    } else if DeviceType.isIPad {
      return ScreenSize.minLength * 0.45
    } else {
      return ScreenSize.minLength * 0.75
    }
  }
}

struct MessageFontsAppearance {
  
  static var defaultMessageTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 22)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 19)
    } else {
      return .systemFont(ofSize: 16)
    }
  }
  
  static var defaultVoiceMessageTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 20)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 17)
    } else {
      return .systemFont(ofSize: 14)
    }
  }
  
  static var defaultInformationMessageTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 20)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 17)
    } else {
      return .systemFont(ofSize: 14)
    }
  }
  
  static var defaultDeliveryStatusTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 15)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 13)
    } else {
      return .systemFont(ofSize: 10)
    }
  }
  
  static var defaultTimestampTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 14)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 11)
    } else {
      return .systemFont(ofSize: 8)
    }
  }
  
 static var defaultMessageAuthorNameFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 21)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 18)
    } else {
      return .systemFont(ofSize: 15)
    }
  }
}

class BaseMessageCell: RevealableCollectionViewCell {
  
  weak var message: Message?
  
  weak var chatLogController: ChatLogViewController?

  static let textViewTopInset: CGFloat = 6
  
  static let textViewBottomInset: CGFloat = 6
  
  static let incomingTextViewLeftInset: CGFloat = 8
  
  static let incomingTextViewRightInset: CGFloat = 3
  
  static let outgoingTextViewLeftInset: CGFloat = 5
  
  static let outgoingTextViewRightInset: CGFloat = 8
  
  static let incomingMessageHorisontalInsets = 2 * (incomingTextViewLeftInset + incomingTextViewRightInset)
  
  static let outgoingMessageHorisontalInsets = (2 * (outgoingTextViewLeftInset + outgoingTextViewRightInset))
  
  static let scrollIndicatorInset: CGFloat = 5
  
  static let incomingMessageAuthorNameLeftInset = incomingTextViewLeftInset + 5
  
  static let bubbleViewMaxWidth: CGFloat = CellSizes.bubbleViewMaxWidth()
  
  static let landscapeBubbleViewMaxWidth: CGFloat = CellSizes.landscapeBubbleViewMaxWidth()
  
  static let bubbleViewMaxHeight: CGFloat = 10000
  
  static let mediaMaxWidth: CGFloat = CellSizes.mediaMaxWidth()

  static let incomingGroupMessageAuthorNameLabelMaxWidth = bubbleViewMaxWidth - incomingMessageHorisontalInsets
  
  static let landscapeIncomingGroupMessageAuthorNameLabelMaxWidth = landscapeBubbleViewMaxWidth - incomingMessageHorisontalInsets

  static let incomingGroupMessageAuthorNameLabelHeight: CGFloat = 25
  
  static let groupIncomingTextViewTopInset: CGFloat = incomingGroupMessageAuthorNameLabelHeight
  
  static let incomingGroupMessageAuthorNameLabelHeightWithInsets: CGFloat = incomingGroupMessageAuthorNameLabelHeight
  
  static let incomingBubbleOrigin = CGPoint(x: 5, y: 0)
  
  static let minimumMediaCellHeight: CGFloat = 66
 
  static let incomingGroupMinimumMediaCellHeight: CGFloat = BaseMessageCell.minimumMediaCellHeight + incomingGroupMessageAuthorNameLabelHeight
  
  static let groupTextMessageInsets = groupIncomingTextViewTopInset + textViewBottomInset
  
  static let defaultTextMessageInsets = textViewBottomInset + textViewTopInset
  
  static let defaultVoiceMessageHeight: CGFloat = 35
  
  static let groupIncomingVoiceMessageHeight: CGFloat = defaultVoiceMessageHeight + incomingGroupMessageAuthorNameLabelHeightWithInsets
  
  let bubbleView: UIImageView = {
    let bubbleView = UIImageView()
    bubbleView.isUserInteractionEnabled = true
    
    return bubbleView
  }()
  
  var deliveryStatus: UILabel = {
    var deliveryStatus = UILabel()
    deliveryStatus.text = "status"
    deliveryStatus.font = MessageFontsAppearance.defaultDeliveryStatusTextFont
    deliveryStatus.textColor =  ThemeManager.currentTheme().generalSubtitleColor
    deliveryStatus.isHidden = true
    deliveryStatus.textAlignment = .right
    
    return deliveryStatus
  }()
  
  let nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.font = MessageFontsAppearance.defaultMessageAuthorNameFont
    nameLabel.numberOfLines = 1
    nameLabel.backgroundColor = .clear
    nameLabel.textColor = FalconPalette.defaultBlue
    nameLabel.frame.size.height = BaseMessageCell.incomingGroupMessageAuthorNameLabelHeight
    nameLabel.frame.origin = CGPoint(x: incomingMessageAuthorNameLeftInset, y: BaseMessageCell.textViewTopInset)
    
    return nameLabel
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame.integral)
    
    setupViews()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureDeliveryStatus(at indexPath: IndexPath, lastMessageIndex: Int, message:Message ) {
    switch indexPath.row == lastMessageIndex {
    case true:
      DispatchQueue.main.async {
        self.deliveryStatus.frame = CGRect(x: self.frame.width - 80, y: self.bubbleView.frame.height + 2, width: 70, height: 10).integral
        self.deliveryStatus.text = message.status
        self.deliveryStatus.isHidden = false
        self.deliveryStatus.layoutIfNeeded()
      }
      break
      
    default:
      DispatchQueue.main.async {
        self.deliveryStatus.isHidden = true
        self.deliveryStatus.layoutIfNeeded()
      }
      break
    }
  }
  
  func setupTimestampView(message: Message, isOutgoing:Bool) {
    DispatchQueue.main.async {
      if let view = self.chatLogController?.collectionView.dequeueReusableRevealableView(withIdentifier: "timestamp") as? TimestampView {
        view.titleLabel.text = message.convertedTimestamp
        let style:RevealStyle = isOutgoing ? .slide : .over
        self.setRevealableView(view, style: style, direction: .left)
      }
    }
  }

  func setupViews() {
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  func prepareViewsForReuse() {}
  
  override func prepareForReuse() {
    super.prepareForReuse()
    prepareViewsForReuse()
    deliveryStatus.text = ""
  }
}
