//
//  AutoSizingCollectionViewFlowLayout.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 4/27/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class AutoSizingCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
  override func prepare() {
    super.prepare()
    minimumLineSpacing = 2
    sectionHeadersPinToVisibleBounds = true
    if globalDataStorage.isInsertingCellsToTop == true {
      if let collectionView = collectionView, let oldContentSize = globalDataStorage.contentSizeWhenInsertingToTop {
        let newContentSize = collectionViewContentSize
        let contentOffsetY = collectionView.contentOffset.y + (newContentSize.height - oldContentSize.height)
        let newOffset = CGPoint(x: collectionView.contentOffset.x, y: contentOffsetY)
				UIView.performWithoutAnimation {
					collectionView.setContentOffset(newOffset, animated: false)
				}
      }
      globalDataStorage.contentSizeWhenInsertingToTop = nil
      globalDataStorage.isInsertingCellsToTop = false
    }
  }
}
