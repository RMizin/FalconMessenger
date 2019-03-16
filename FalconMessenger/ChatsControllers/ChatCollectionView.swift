//
//  ChatCollectionView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import Photos

class ChatCollectionView: UICollectionView {

	let incomingTextMessageCellID = "incomingTextMessageCellID"
	let outgoingTextMessageCellID = "outgoingTextMessageCellID"
	let typingIndicatorCellID = "typingIndicatorCellID"
	let photoMessageCellID = "photoMessageCellID"
	let outgoingVoiceMessageCellID = "outgoingVoiceMessageCellID"
	let incomingVoiceMessageCellID = "incomingVoiceMessageCellID"

	let incomingPhotoMessageCellID = "incomingPhotoMessageCellID"
	let informationMessageCellID = "informationMessageCellID"


  required public init() {
    super.init(frame: .zero, collectionViewLayout: AutoSizingCollectionViewFlowLayout())
    
    alwaysBounceVertical = true
    contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
    delaysContentTouches = false
    isPrefetchingEnabled = true
    keyboardDismissMode = .interactive
    updateColors()
		registerCells()
  }


	fileprivate func registerCells() {
		register(IncomingTextMessageCell.self, forCellWithReuseIdentifier: incomingTextMessageCellID)
		register(OutgoingTextMessageCell.self, forCellWithReuseIdentifier: outgoingTextMessageCellID)
		register(TypingIndicatorCell.self, forCellWithReuseIdentifier: typingIndicatorCellID)
		register(PhotoMessageCell.self, forCellWithReuseIdentifier: photoMessageCellID)
		register(IncomingPhotoMessageCell.self, forCellWithReuseIdentifier: incomingPhotoMessageCellID)
		register(OutgoingVoiceMessageCell.self, forCellWithReuseIdentifier: outgoingVoiceMessageCellID)
		register(IncomingVoiceMessageCell.self, forCellWithReuseIdentifier: incomingVoiceMessageCellID)
		register(InformationMessageCell.self, forCellWithReuseIdentifier: informationMessageCellID)
		register(ChatLogViewControllerSupplementaryView.self,
						 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
						 withReuseIdentifier: "lol")
	}
  
  func updateColors() {
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    if DeviceType.isIPad {
			let visibleSections = indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader).map({$0.section})
      UIView.performWithoutAnimation {
        reloadSections(IndexSet(visibleSections))
      }
    }
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public func scrollToBottom(animated: Bool) {
    guard contentSize.height > bounds.size.height else { return }
    setContentOffset(CGPoint(x: 0, y: (contentSize.height - bounds.size.height) + (contentInset.bottom)),
                     animated: animated)
  }

	public func setupCellHeight(isGroupChat: Bool, isOutgoingMessage: Bool, frame: RealmCGRect?, indexPath: IndexPath) -> CGFloat {
		guard let frame = frame, let width = frame.width.value, let height = frame.height.value else { return 0 }

		var timeHeight: CGFloat!
		let bubbleMaxWidth = UIDevice.current.orientation.isLandscape ? BaseMessageCell.landscapeBubbleViewMaxWidth : BaseMessageCell.bubbleViewMaxWidth
		if (CGFloat(width) + BaseMessageCell.messageTimeWidth <= bubbleMaxWidth) ||
			CGFloat(width) < BaseMessageCell.messageTimeWidth {
			timeHeight = 0
		} else {
			timeHeight = BaseMessageCell.messageTimeHeight
		}

		if isGroupChat, !isOutgoingMessage {
			return CGFloat(height) + BaseMessageCell.groupTextMessageInsets + timeHeight
		} else {
			return CGFloat(height) + BaseMessageCell.defaultTextMessageInsets + timeHeight
		}
	}
}



