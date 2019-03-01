//
//  RespondingButton.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 12/28/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class RespondingButton: UIButton, UIKeyInput {

	var hasText: Bool = true
	func insertText(_ text: String) {}
	func deleteBackward() {}

	init() {
		super.init(frame: .zero)
		changeTheme()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setupAppearance() {
		translatesAutoresizingMaskIntoConstraints = false
	}

	override var canBecomeFirstResponder: Bool {
		return true
	}

	override func resignFirstResponder() -> Bool {
		NotificationCenter.default.post(name: .inputViewResigned, object: nil)
		isSelected = false
		return super.resignFirstResponder()
	}

	override func becomeFirstResponder() -> Bool {
		NotificationCenter.default.post(name: .inputViewResponded, object: nil)
		isSelected = true
		return super.becomeFirstResponder()
	}

	func changeTheme() {
		tintColor = ThemeManager.currentTheme().tintColor
		inputView?.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
	}
}
