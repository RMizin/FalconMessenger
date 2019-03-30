//
//  AppearanceExampleCollectionView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 3/16/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class AppearanceExampleCollectionView: ChatCollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

	fileprivate var messages = AppearanceExampleMessagesFactory.messages()

	required public init() {
		super.init()
		delegate = self
		dataSource = self
		backgroundColor = .clear
		isScrollEnabled = false
		isUserInteractionEnabled = false
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		reloadData()
	}

	func updateTheme() {
		messages = AppearanceExampleMessagesFactory.messages()
		DispatchQueue.main.async { [weak self] in self?.reloadData() }
	}

	func fullContentSize() -> CGSize {
		let indexPaths = [IndexPath(row: 0, section: 0), IndexPath(row: 1, section: 0)]
		var fullSize = CGSize(width: 0, height: 0)
		for indexPath in indexPaths {
			let itemSize = selectSize(indexPath: indexPath)
			fullSize.width += itemSize.width
			fullSize.height += itemSize.height
		}
		return fullSize
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return messages.count
	}

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return CGSize(width: frame.width, height: 25)
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let isOutgoingMessage = indexPath.row == 1
		let message = messages[indexPath.row]
		message.isCrooked.value = true

		switch isOutgoingMessage {
		case true:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: outgoingTextMessageCellID,
																										for: indexPath) as? OutgoingTextMessageCell ?? OutgoingTextMessageCell()
			cell.textView.font = MessageFontsAppearance.defaultMessageTextFont
			cell.setupData(message: message)

			return cell
		case false:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: incomingTextMessageCellID,
																										for: indexPath) as? IncomingTextMessageCell ?? IncomingTextMessageCell()
			cell.textView.font = MessageFontsAppearance.defaultMessageTextFont
			cell.setupData(message: message, isGroupChat: false)
			return cell
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return selectSize(indexPath: indexPath)
	}

	fileprivate func selectSize(indexPath: IndexPath) -> CGSize {
		let message = messages[indexPath.row]
		let isTextMessage = true
		let isOutgoingMessage = indexPath.row == 1

		guard !isTextMessage else {
			if UIDevice.current.orientation.isLandscape {
				return CGSize(width: frame.width,
											height: setupCellHeight(isGroupChat: false,
																							isOutgoingMessage: isOutgoingMessage,
																							frame: message.landscapeEstimatedFrameForText,
																							indexPath: indexPath))
			} else {
				return CGSize(width: frame.width,
											height: setupCellHeight(isGroupChat: false,
																							isOutgoingMessage: isOutgoingMessage,
																							frame: message.estimatedFrameForText,
																							indexPath: indexPath))
			}
		}
	}
}
