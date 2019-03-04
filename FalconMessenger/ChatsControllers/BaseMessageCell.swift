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
		return .systemFont(ofSize: CGFloat(UserDefaultsManager().currentFloatObjectState(for: UserDefaultsManager().chatLogDefaultFontSizeID)))
  }
  
  static var defaultVoiceMessageTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 19)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 17)
    } else {
      return .systemFont(ofSize: 14)
    }
  }
  
  static var defaultInformationMessageTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 19)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 17)
    } else {
      return .systemFont(ofSize: 14)
    }
  }
  
  static var defaultTimeLabelTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 14)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 12)
    } else {
      return .italicSystemFont(ofSize: 11)
    }
  }
  
  static var defaultDeliveryStatusTextFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 14)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 13)
    } else {
      return .systemFont(ofSize: 10)
    }
  }
  
 static var defaultMessageAuthorNameFont: UIFont {
    if DeviceType.IS_IPAD_PRO {
      return .systemFont(ofSize: 18)
    } else if DeviceType.isIPad {
      return .systemFont(ofSize: 16)
    } else {
      return .systemFont(ofSize: 15)
    }
  }
}

class BaseMessageCell: UICollectionViewCell {
  
//	weak var message: Message?
  
	weak var chatLogController: ChatLogViewController? {
		didSet {
			resendButton.addTarget(chatLogController, action: #selector(ChatLogViewController.presentResendActions(_:)), for: .touchUpInside)
		}
	}

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
  
  static let messageTimeHeight: CGFloat = 20
  
  static var messageTimeWidth: CGFloat {
    if DeviceType.IS_IPAD_PRO {
      return 95
    } else if DeviceType.isIPad {
      return 78
    } else {
      return 68
    }
  }

  static let groupIncomingTextViewTopInset: CGFloat = incomingGroupMessageAuthorNameLabelHeight
  
  static let incomingGroupMessageAuthorNameLabelHeightWithInsets: CGFloat = incomingGroupMessageAuthorNameLabelHeight
  
  static let incomingBubbleOrigin = CGPoint(x: 5, y: 0)
  
  static let minimumMediaCellHeight: CGFloat = 66
 
  static let incomingGroupMinimumMediaCellHeight: CGFloat = BaseMessageCell.minimumMediaCellHeight + incomingGroupMessageAuthorNameLabelHeight
  
  static let groupTextMessageInsets = groupIncomingTextViewTopInset + textViewBottomInset
  
  static let defaultTextMessageInsets = textViewBottomInset + textViewTopInset

  static let defaultVoiceMessageHeight: CGFloat = 35
  
  static let groupIncomingVoiceMessageHeight: CGFloat = defaultVoiceMessageHeight + incomingGroupMessageAuthorNameLabelHeightWithInsets
  
  lazy var bubbleView: UIImageView = {
    let bubbleView = UIImageView()
    bubbleView.isUserInteractionEnabled = true
    
    return bubbleView
  }()

	lazy var resendButton: UIButton = {
		let resendButton = UIButton(type: .infoDark)
		resendButton.tintColor = FalconPalette.dismissRed
		resendButton.isHidden = true
		
		return resendButton
	}()
  
  lazy var deliveryStatus: UILabel = {
    var deliveryStatus = UILabel()
    deliveryStatus.text = "status"
    deliveryStatus.font = MessageFontsAppearance.defaultDeliveryStatusTextFont
    deliveryStatus.textColor =  ThemeManager.currentTheme().generalSubtitleColor
    deliveryStatus.isHidden = true
    deliveryStatus.textAlignment = .right
    
    return deliveryStatus
  }()
  
  lazy var nameLabel: UILabel = {
    var nameLabel = UILabel()
    nameLabel.font = MessageFontsAppearance.defaultMessageAuthorNameFont
    nameLabel.numberOfLines = 1
    nameLabel.backgroundColor = .clear
    nameLabel.textColor = ThemeManager.currentTheme().authorNameTextColor//FalconPalette.defaultBlue
    nameLabel.frame.size.height = BaseMessageCell.incomingGroupMessageAuthorNameLabelHeight
		nameLabel.frame.origin = CGPoint(x: BaseMessageCell.incomingMessageAuthorNameLeftInset, y: BaseMessageCell.textViewTopInset)
    
    return nameLabel
  }()

  lazy var timeLabel: UILabel = {
    let timeLabel = UILabel()
    timeLabel.font = MessageFontsAppearance.defaultTimeLabelTextFont
    timeLabel.numberOfLines = 1
    timeLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    timeLabel.frame.size.height = BaseMessageCell.messageTimeHeight
    timeLabel.frame.size.width = BaseMessageCell.messageTimeWidth
    timeLabel.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    timeLabel.layer.masksToBounds = true
    timeLabel.layer.cornerRadius = 10
    timeLabel.textAlignment = .center
    timeLabel.alpha = 0.85
    timeLabel.text = "10:46 AM"

    return timeLabel
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

	func resendButtonFrame(message: Message) {
		if message.status == messageStatusNotSent {
			resendButton.sizeToFit()
			resendButton.frame.origin = CGPoint(x: frame.width - resendButton.frame.width - 10, y: frame.height - resendButton.frame.height)
			resendButton.isHidden = false
		} else {
			resendButton.frame = CGRect.zero
			resendButton.isHidden = true
		}
	}

	func resendButtonWidth() -> CGFloat {
		if resendButton.frame.width > 0 {
			return resendButton.frame.width + 10
		} else {
			return 0
		}
	}

  func configureDeliveryStatus(at indexPath: IndexPath, groupMessages: [MessageSection], message: Message) {

    guard let lastItem = groupMessages.last else { return }
    let lastRow = lastItem.messages.count - 1
    let lastSection = groupMessages.count - 1
    
    let lastIndexPath = IndexPath(row: lastRow, section: lastSection)
    
    switch indexPath == lastIndexPath {
    case true:
			deliveryStatus.frame = CGRect(x: frame.width - 80, y: bubbleView.frame.height + 2,
																				 width: 70, height: 12)//.integral
			deliveryStatus.text = message.status
			deliveryStatus.isHidden = false
			deliveryStatus.layoutIfNeeded()

    default:
			deliveryStatus.isHidden = true
			deliveryStatus.layoutIfNeeded()
    }
  }
  
  func setupFrameWithLabel(_ x: CGFloat, _ bubbleMaxWidth: CGFloat, _ estimate: CGFloat,
                           _ insets: CGFloat, _ cellHeight: CGFloat, _ spacer: CGFloat = 10) -> CGRect {
    var x = x
    if (estimate + BaseMessageCell.messageTimeWidth <=  bubbleMaxWidth) ||
      estimate <= BaseMessageCell.messageTimeWidth {
      x = x - BaseMessageCell.messageTimeWidth + spacer
    }
    
    var width: CGFloat = estimate + insets
    if (estimate + BaseMessageCell.messageTimeWidth <=  bubbleMaxWidth) ||
      estimate <= BaseMessageCell.messageTimeWidth {
      width = width + BaseMessageCell.messageTimeWidth - spacer
    }
    
    let rect = CGRect(x: x, y: 0, width: width, height: cellHeight).integral
    return rect
  }

  func setupViews() {
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))))
    contentView.addSubview(bubbleView)
  }
  
 private func prepareViewsForReuse() {
    deliveryStatus.text = ""
    nameLabel.text = ""
    nameLabel.textColor = ThemeManager.currentTheme().authorNameTextColor
    bubbleView.image = nil
    timeLabel.backgroundColor = .clear
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    prepareViewsForReuse()
  }
}
