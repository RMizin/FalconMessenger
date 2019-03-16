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
		appearanceExampleCollectionView.translatesAutoresizingMaskIntoConstraints = false

		return appearanceExampleCollectionView
	}()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .default, reuseIdentifier: reuseIdentifier)
		backgroundColor = .clear

		contentView.addSubview(appearanceExampleCollectionView)

		if #available(iOS 11.0, *) {
			appearanceExampleCollectionView.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor).isActive = true
			appearanceExampleCollectionView.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor).isActive = true
		} else {
			appearanceExampleCollectionView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
			appearanceExampleCollectionView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
		}

		appearanceExampleCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
		appearanceExampleCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	override func prepareForReuse() {
		super.prepareForReuse()

	}
}
