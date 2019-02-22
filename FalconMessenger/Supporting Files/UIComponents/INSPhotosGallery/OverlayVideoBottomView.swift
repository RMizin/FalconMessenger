//
//  OverlayVideoBottomView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/31/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class OverlayVideoBottomView: UIView {

	fileprivate var bottomViewHeightAnchor: NSLayoutConstraint!

	let minimumRate: UILabel = {
		let minimumRate = UILabel()
		minimumRate.translatesAutoresizingMaskIntoConstraints = false
		minimumRate.backgroundColor = UIColor.clear
		minimumRate.numberOfLines = 1
		minimumRate.sizeToFit()
		minimumRate.font = UIFont.systemFont(ofSize: 10)
		minimumRate.textColor = .white
		minimumRate.text = "--:--"

		return minimumRate
	}()
	let maximumRate: UILabel = {
		let maximumRate = UILabel()
		maximumRate.translatesAutoresizingMaskIntoConstraints = false
		maximumRate.backgroundColor = UIColor.clear
		maximumRate.numberOfLines = 1
		maximumRate.sizeToFit()
		maximumRate.font = UIFont.systemFont(ofSize: 10)
		maximumRate.textColor = .white
		maximumRate.text = "--:--"

		return maximumRate
	}()

	let seekSlider: FalconUISlider = {
		let seekSlider = FalconUISlider()
		seekSlider.isUserInteractionEnabled = false
		seekSlider.sizeToFit()
		return seekSlider
	}()

	let playButton: UIButton = {
		let playButton = UIButton()
		playButton.translatesAutoresizingMaskIntoConstraints = false
		playButton.setImage(UIImage(named: "playVideo"), for: .normal)
		playButton.setImage(UIImage(named: "pauseVideo"), for: .selected)
		return playButton
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)

		alpha = 0.8
		backgroundColor = .black
		translatesAutoresizingMaskIntoConstraints = false
		bottomViewHeightAnchor = heightAnchor.constraint(equalToConstant: UIDevice.current.orientation.isLandscape ? 75 : 90)
		bottomViewHeightAnchor.isActive = true


		addSubview(minimumRate)
		addSubview(maximumRate)
		addSubview(seekSlider)
		addSubview(playButton)

		seekSlider.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
		if #available(iOS 11.0, *) {
			seekSlider.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 15).isActive = true
			seekSlider.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
		} else {
			seekSlider.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
			seekSlider.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
		}
		minimumRate.leftAnchor.constraint(equalTo: seekSlider.leftAnchor).isActive = true
		minimumRate.topAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: 5).isActive = true

		maximumRate.rightAnchor.constraint(equalTo: seekSlider.rightAnchor).isActive = true
		maximumRate.topAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: 5).isActive = true

		playButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
		playButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		bottomViewHeightAnchor.constant = UIDevice.current.orientation.isLandscape ? 75 : 90
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
