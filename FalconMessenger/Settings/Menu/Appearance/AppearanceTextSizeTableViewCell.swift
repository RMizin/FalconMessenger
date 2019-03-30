//
//  AppearanceTextSizeTableViewCell.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 3/30/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class AppearanceTextSizeTableViewCell: UITableViewCell {

	var sliderView: UIIncrementSliderView!

	fileprivate let userDefaultsManager = UserDefaultsManager()
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .default, reuseIdentifier: reuseIdentifier)
		backgroundColor = .clear
		selectionStyle = .none

		let currentValue = userDefaultsManager.currentFloatObjectState(for: userDefaultsManager.chatLogDefaultFontSizeID)
		sliderView = UIIncrementSliderView(values: DefaultMessageTextFontSize.allFontSizes(), currentValue: currentValue)
		sliderView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(sliderView)
		sliderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
		if #available(iOS 11.0, *) {
			sliderView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
			sliderView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
		} else {
			sliderView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
			sliderView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
		}
		sliderView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
