//
//  ControlButton.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 2/2/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class ControlButton: UIButton {

	override var isHighlighted: Bool {
		didSet {
			backgroundColor = isHighlighted ? UIColor.lightGray : ThemeManager.currentTheme().controlButtonsColor
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		layer.cornerRadius = 25
		setTitleColor(tintColor, for: .normal)
		backgroundColor = ThemeManager.currentTheme().controlButtonsColor
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setAction(_ selector: Selector) {
		addTarget(self, action: selector, for: .touchUpInside)
	}
}
