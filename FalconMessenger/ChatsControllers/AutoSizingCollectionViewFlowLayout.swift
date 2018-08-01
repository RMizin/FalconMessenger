//
//  AutoSizingCollectionViewFlowLayout.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 4/27/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
  
class AutoSizingCollectionViewFlowLayout: UICollectionViewFlowLayout {
  
  static let lineSpacing: CGFloat = 2
  
  override func prepare() {
    super.prepare()
    
    if globalDataStorage.isInsertingCellsToTop == true {
      if let collectionView = collectionView, let oldContentSize = globalDataStorage.contentSizeWhenInsertingToTop {
        let newContentSize = collectionViewContentSize
        let contentOffsetY = collectionView.contentOffset.y + (newContentSize.height - oldContentSize.height)
        let newOffset = CGPoint(x: collectionView.contentOffset.x, y: contentOffsetY)
        collectionView.setContentOffset(newOffset, animated: false)
      }
      globalDataStorage.contentSizeWhenInsertingToTop = nil
      globalDataStorage.isInsertingCellsToTop = false
    }
  }
}
