//
//  OverlayPhotoBottomView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/31/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class OverlayPhotoBottomView: UIView {

	fileprivate var bottomViewHeightAnchor: NSLayoutConstraint!

	let captionLabel: UILabel = {
		let captionLabel = UILabel()
		captionLabel.translatesAutoresizingMaskIntoConstraints = false
		captionLabel.backgroundColor = UIColor.clear
		captionLabel.numberOfLines = 0
		captionLabel.sizeToFit()
		return captionLabel
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)

		alpha = 0.8
		backgroundColor = .black
		translatesAutoresizingMaskIntoConstraints = false
		bottomViewHeightAnchor = heightAnchor.constraint(equalToConstant: UIDevice.current.orientation.isLandscape ? 75 : 90)
		bottomViewHeightAnchor.isActive = true

		addSubview(captionLabel)
		if #available(iOS 11.0, *) {
			captionLabel.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
			captionLabel.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
			captionLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12).isActive = true
		} else {
			captionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
			captionLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
			captionLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
		}
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		bottomViewHeightAnchor.constant = UIDevice.current.orientation.isLandscape ? 75 : 90
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
