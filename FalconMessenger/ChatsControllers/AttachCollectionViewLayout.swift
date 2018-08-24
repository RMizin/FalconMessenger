//
//  AttachCollectionViewLayout.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/23/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class AttachCollectionViewLayout: UICollectionViewFlowLayout {
  override init() {
    super.init()
    minimumLineSpacing = 5
    minimumInteritemSpacing = 5
    scrollDirection = .horizontal
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
