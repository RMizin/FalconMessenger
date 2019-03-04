//
//  UIIncrementSliderView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 3/4/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class UIIncrementSliderView: UIView {

	let slider: UIIncrementSlider = {
		let slider = UIIncrementSlider()
		slider.translatesAutoresizingMaskIntoConstraints = false
		return slider
	}()

	fileprivate let title: UILabel = {
		let title = UILabel()
		title.text = "Text size"
		title.sizeToFit()
		title.textColor = ThemeManager.currentTheme().generalTitleColor
		title.translatesAutoresizingMaskIntoConstraints = false
		return title
	}()

	fileprivate let minimumValueImage: UIImageView = {
		let minimumValueImage = UIImageView()
		minimumValueImage.image =  UIImage(named: "FontMinIcon")?.withRenderingMode(.alwaysTemplate)
		minimumValueImage.tintColor = ThemeManager.currentTheme().generalTitleColor
		minimumValueImage.translatesAutoresizingMaskIntoConstraints = false
		return minimumValueImage
	}()

	fileprivate let maximumValueImage: UIImageView = {
		let maximumValueImage = UIImageView()
		maximumValueImage.image = UIImage(named: "FontMaxIcon")?.withRenderingMode(.alwaysTemplate)
		maximumValueImage.tintColor = ThemeManager.currentTheme().generalTitleColor
		maximumValueImage.translatesAutoresizingMaskIntoConstraints = false
		return maximumValueImage
	}()


	init(values: [Float], currentValue: Float? = 0) {
		super.init(frame: .zero)
		addSubview(slider)
		addSubview(minimumValueImage)
		addSubview(maximumValueImage)
		addSubview(title)
		NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)

		if #available(iOS 11.0, *) {
			NSLayoutConstraint.activate([
				title.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 25),
				title.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 15),
				minimumValueImage.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 15),
				maximumValueImage.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -15)
			])
		} else {
			NSLayoutConstraint.activate([
				title.topAnchor.constraint(equalTo: topAnchor, constant: 15),
				title.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
				minimumValueImage.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
				maximumValueImage.rightAnchor.constraint(equalTo: rightAnchor, constant: -15)
			])
		}

		NSLayoutConstraint.activate([
			slider.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
			slider.leftAnchor.constraint(equalTo: minimumValueImage.rightAnchor, constant: 10),
			slider.rightAnchor.constraint(equalTo: maximumValueImage.leftAnchor, constant: -10),

			minimumValueImage.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
			minimumValueImage.widthAnchor.constraint(equalToConstant: (minimumValueImage.image?.size.width ?? 0)),
			minimumValueImage.heightAnchor.constraint(equalToConstant: (minimumValueImage.image?.size.height ?? 0)),

			maximumValueImage.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
			maximumValueImage.widthAnchor.constraint(equalToConstant: (maximumValueImage.image?.size.width ?? 0)),
			maximumValueImage.heightAnchor.constraint(equalToConstant: (maximumValueImage.image?.size.height ?? 0))
		])
		slider.initializeSlider(with: values, currentValue: currentValue ?? 0)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc fileprivate func changeTheme() {
		title.textColor = ThemeManager.currentTheme().generalTitleColor
		minimumValueImage.tintColor = ThemeManager.currentTheme().generalTitleColor
		maximumValueImage.tintColor = ThemeManager.currentTheme().generalTitleColor
		slider.changeTheme()
	}
}
