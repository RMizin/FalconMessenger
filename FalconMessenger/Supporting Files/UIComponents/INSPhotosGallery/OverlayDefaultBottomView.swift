//
//  OverlayDefaultBottomView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/31/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

public class OverlayDefaultBottomView: UIView {

	let insPhotoBottomView: OverlayPhotoBottomView = {
		let insPhotoBottomView = OverlayPhotoBottomView()
		insPhotoBottomView.isHidden = true
		insPhotoBottomView.translatesAutoresizingMaskIntoConstraints = false
		return insPhotoBottomView
	}()

	let insVideoBottomView: OverlayVideoBottomView = {
		let insVideoBottomView = OverlayVideoBottomView()

		insVideoBottomView.isHidden = true
		insVideoBottomView.translatesAutoresizingMaskIntoConstraints = false
		return insVideoBottomView
	}()


	override init(frame: CGRect) {
		super.init(frame: frame)
		addSubview(insVideoBottomView)
		addSubview(insPhotoBottomView)

		NSLayoutConstraint.activate([
			insPhotoBottomView.topAnchor.constraint(equalTo: topAnchor),
			insPhotoBottomView.bottomAnchor.constraint(equalTo: bottomAnchor),
			insPhotoBottomView.leftAnchor.constraint(equalTo: leftAnchor),
			insPhotoBottomView.rightAnchor.constraint(equalTo: rightAnchor),

			insVideoBottomView.topAnchor.constraint(equalTo: topAnchor),
			insVideoBottomView.bottomAnchor.constraint(equalTo: bottomAnchor),
			insVideoBottomView.leftAnchor.constraint(equalTo: leftAnchor),
			insVideoBottomView.rightAnchor.constraint(equalTo: rightAnchor)
		])
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
