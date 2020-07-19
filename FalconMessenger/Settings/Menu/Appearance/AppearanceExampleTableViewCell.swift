//
//  AppearanceExampleTableViewCell.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 3/16/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class AppearanceExampleTableViewCell: UITableViewCell {

    let appearanceExampleCollectionView: AppearanceExampleCollectionView = {
        let appearanceExampleCollectionView = AppearanceExampleCollectionView()
        return appearanceExampleCollectionView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        guard let flow = appearanceExampleCollectionView.collectionViewLayout as? AutoSizingCollectionViewFlowLayout else { return }
        flow.estimatedItemSize = CGSize(width: 1, height: 1)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(appearanceExampleCollectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority) -> CGSize {
        if #available(iOS 11.0, *) {
            appearanceExampleCollectionView.frame = CGRect(
                x: 0,
                y: -20,
                width: targetSize.width - safeAreaInsets.left - safeAreaInsets.right,
                height: appearanceExampleCollectionView.fullContentSize().height + 55)
        } else {
            appearanceExampleCollectionView.frame = CGRect(
                x: 0,
                y: -20,
                width: targetSize.width,
                height: appearanceExampleCollectionView.fullContentSize().height + 55)
        }
        return appearanceExampleCollectionView.collectionViewLayout.collectionViewContentSize
    }
}
