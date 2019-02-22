//
//  FalconActivityTitleView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 2/22/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class FalconActivityTitleView: UIView {

	fileprivate let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)
	let titleLabel = UILabel()

	convenience init(text: UINavigationItemTitle) {
		self.init()

		NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)

		activityIndicatorView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
		activityIndicatorView.color = ThemeManager.currentTheme().generalTitleColor//color
		activityIndicatorView.startAnimating()

		titleLabel.text = text.rawValue
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor//color

		let fittingSize = titleLabel.sizeThatFits(CGSize(width: 200.0, height: activityIndicatorView.frame.size.height))

		titleLabel.frame = CGRect(x: activityIndicatorView.frame.origin.x + activityIndicatorView.frame.size.width + 8,
															y: activityIndicatorView.frame.origin.y,
															width: fittingSize.width,
															height: fittingSize.height)

		let viewFrame = CGRect(x: (activityIndicatorView.frame.size.width + 8 + titleLabel.frame.size.width) / 2,
													 y: activityIndicatorView.frame.size.height / 2,
													 width: activityIndicatorView.frame.size.width + 8 + titleLabel.frame.size.width,
													 height: activityIndicatorView.frame.size.height)
		self.frame = viewFrame
		addSubview(activityIndicatorView)
		addSubview(titleLabel)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc fileprivate func changeTheme() {
		activityIndicatorView.color = ThemeManager.currentTheme().generalTitleColor
		titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
	}
}
