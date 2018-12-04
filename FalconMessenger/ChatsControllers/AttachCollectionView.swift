//
//  AttachCollectionView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class AttachCollectionView: UICollectionView {
  
  static let height: CGFloat = 165
  static let cellHeight: CGFloat = 160
  
  override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
    super.init(frame: frame, collectionViewLayout: AttachCollectionViewLayout())

    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false
    backgroundColor = .clear
    autoresizesSubviews = false
		decelerationRate = UIScrollView.DecelerationRate.fast
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
