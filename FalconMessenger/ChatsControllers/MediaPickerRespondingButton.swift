//
//  MediaPickerRespondingButton.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 12/28/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class MediaPickerRespondingButton: RespondingButton {

	var controller: MediaPickerControllerNew? {
		didSet {
			reloadInputViews()
			changeTheme()
		}
	}

	override init() {
		super.init()
		setupAppearance()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var inputView: UIView? {
		get {
			return controller?.view
		}
	}

	func reset() {
		controller?.collectionView.deselectAllItems()
	}

	override func setupAppearance() {
		super.setupAppearance()

		setImage(UIImage(named: "ConversationAttach")?
			.withRenderingMode(.alwaysTemplate)
			.sd_tintedImage(with: ThemeManager.currentTheme().unselectedButtonTintColor), for: .normal)
		setImage(UIImage(named: "SelectedModernConversationAttach")?
			.withRenderingMode(.alwaysTemplate)
			.sd_tintedImage(with: ThemeManager.currentTheme().selectedButtonTintColor), for: .selected)
	}
}
