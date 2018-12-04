//
//  SnapshotLockerView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 12/3/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SnapshotLockerView: UIView {

	let blurEffectView: UIVisualEffectView = {
		let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light))
		blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		blurEffectView.translatesAutoresizingMaskIntoConstraints = false
		return blurEffectView
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		addSubview(blurEffectView)
		blurEffectView.topAnchor.constraint(equalTo: topAnchor).isActive = true
		blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
		blurEffectView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
		blurEffectView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		fatalError("init(coder:) has not been implemented")
	}

	func add(to window: UIWindow?) {
		frame = window?.bounds ?? CGRect.zero
		window?.addSubview(self)
	}

	func remove(from window: UIWindow?) {
		guard let window = window else { return }
		for view in window.subviews where view == self {
			view.removeFromSuperview()
		}
	}
}
