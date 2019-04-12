//
//  VoiceRecorderRespondingButton.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 12/28/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class VoiceRecorderRespondingButton: RespondingButton {

	var controller: VoiceRecordingViewController? {
		didSet {
			reloadInputViews()
			changeTheme()
		}
	}

	override init() {
		super.init()
		setupAppearance()
	}

	override func setupAppearance() {
		super.setupAppearance()

		setImage(UIImage(named: "microphone")?
			.withRenderingMode(.alwaysTemplate)
			.sd_tintedImage(with: ThemeManager.currentTheme().unselectedButtonTintColor), for: .normal)
		
		setImage(UIImage(named: "microphoneSelected")?
			.withRenderingMode(.alwaysTemplate)
			.sd_tintedImage(with: ThemeManager.currentTheme().selectedButtonTintColor), for: .selected)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override var inputView: UIView? {
		get {
			return controller?.view
		}
	}

	override func resignFirstResponder() -> Bool {
		resetVoice()
		return super.resignFirstResponder()
	}

	func reset() {
		guard controller?.recorder != nil else { return }
		controller?.stop()
		controller?.deleteAllRecordings()
	}

	fileprivate func resetVoice() {
		print("resetting voice")
		//		guard let voiceController = mediaInputViewController as? VoiceRecordingViewController else { return }
		guard controller?.recorder != nil else { return }
		controller?.stop()
	}
}
