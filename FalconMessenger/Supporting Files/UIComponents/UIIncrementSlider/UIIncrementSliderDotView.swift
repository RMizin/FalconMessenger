//
//  UIIncrementSliderDotView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 3/4/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class UIIncrementSliderDotView: UIView {

	static let dotSize: CGFloat = 6

	override init(frame: CGRect) {
		super.init(frame: frame)
		layer.masksToBounds = true
		layer.cornerRadius = UIIncrementSliderDotView.dotSize / 2
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
