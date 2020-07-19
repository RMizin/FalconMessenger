//
//  OverlayNavigationBar.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/31/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class OverlayNavigationBar: UIView {

	fileprivate var navigationViewHeightAnchor: NSLayoutConstraint!

    var navigationBar: UINavigationBar = {
        var navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.barStyle = .black

        navigationBar.isTranslucent = false
        navigationBar.barStyle = .black
        navigationBar.barTintColor = .black

        if #available(iOS 13.0, *) {
            let coloredAppearance = UINavigationBarAppearance()
            coloredAppearance.configureWithOpaqueBackground()
            coloredAppearance.backgroundColor = .black
            coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBar.standardAppearance = coloredAppearance
            navigationBar.scrollEdgeAppearance = coloredAppearance
            navigationBar.compactAppearance = coloredAppearance
        }
        navigationBar.clipsToBounds = true
        navigationBar.sizeToFit()
        return navigationBar
    }()

	var navigationItem: UINavigationItem = {
		var navigationItem = UINavigationItem()
		return navigationItem
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)

		alpha = 0.8
		backgroundColor = .black
		translatesAutoresizingMaskIntoConstraints = false

		if #available(iOS 11.0, *) {
			let window = UIApplication.shared.keyWindow
			let topSafeArea = window?.safeAreaInsets.top ?? 0.0
			navigationViewHeightAnchor = heightAnchor.constraint(equalToConstant: topSafeArea + navigationBar.frame.height)
			navigationViewHeightAnchor.isActive = true
		} else {
			navigationViewHeightAnchor = heightAnchor.constraint(equalToConstant: navigationBar.frame.height)
			navigationViewHeightAnchor.isActive = true
		}

		addSubview(navigationBar)
		navigationBar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
		navigationBar.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
		navigationBar.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		UIView.performWithoutAnimation {
			navigationBar.invalidateIntrinsicContentSize()
			navigationBar.layoutIfNeeded()
		}
		super.layoutSubviews()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		if #available(iOS 11.0, *) {
			let window = UIApplication.shared.keyWindow
			let topSafeArea = window?.safeAreaInsets.top ?? 0.0
			navigationViewHeightAnchor.constant = topSafeArea + navigationBar.frame.height
		} else {
			navigationViewHeightAnchor.constant = navigationBar.frame.height
		}
	}
}
