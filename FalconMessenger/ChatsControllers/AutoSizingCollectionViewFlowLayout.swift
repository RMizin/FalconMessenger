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
    if globalVariables.isInsertingCellsToTop == true {
      if let collectionView = collectionView, let oldContentSize = globalVariables.contentSizeWhenInsertingToTop {
        let newContentSize = collectionViewContentSize
        let contentOffsetY = collectionView.contentOffset.y + (newContentSize.height - oldContentSize.height)
        let newOffset = CGPoint(x: collectionView.contentOffset.x, y: contentOffsetY)
				UIView.performWithoutAnimation {
					collectionView.setContentOffset(newOffset, animated: false)
				}
      }
			globalVariables.contentSizeWhenInsertingToTop = nil
			globalVariables.isInsertingCellsToTop = false
    }
  }
}
