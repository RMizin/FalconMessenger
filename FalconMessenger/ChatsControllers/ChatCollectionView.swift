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

  required public init() {
    super.init(frame: .zero, collectionViewLayout: AutoSizingCollectionViewFlowLayout())
    
    alwaysBounceVertical = true
    contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
    delaysContentTouches = false
    isPrefetchingEnabled = true
    keyboardDismissMode = .interactive
    updateColors()
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
  
  public func instantMoveToBottom() {
    guard contentSize.height > bounds.size.height else { return }
    UIView.performWithoutAnimation {
      setContentOffset(CGPoint(x: 0, y: (contentSize.height - bounds.size.height) + (contentInset.bottom)),
                       animated: false)
    }
  }
}
