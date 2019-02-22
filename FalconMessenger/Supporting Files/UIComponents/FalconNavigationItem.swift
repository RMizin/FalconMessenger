//
//  FalconNavigationItem.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 2/22/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

enum UINavigationItemTitle: String {
	case noInternet = "Waiting for network"
	case updating = "Updating..."
	case connecting = "Connecting..."
	case updatingUsers = "Syncing Falcon Users..."
}


class FalconNavigationItem: UINavigationItem {

	fileprivate var navigationItemActivityTitleView: FalconActivityTitleView?

	fileprivate var isActive = false

	override var titleView: UIView? {
		didSet {
			if titleView == nil {
				isActive = false
			} else {
				isActive = true
			}
		}
	}

	func showActivityView(with title: UINavigationItemTitle) {
		let isConnectedToInternet = navigationItemActivityTitleView?.titleLabel.text != UINavigationItemTitle.noInternet.rawValue

		if title == UINavigationItemTitle.noInternet {
			navigationItemActivityTitleView = FalconActivityTitleView(text: title)
			titleView = navigationItemActivityTitleView
			return
		}

		guard isConnectedToInternet, !isActive else { return }
		navigationItemActivityTitleView = FalconActivityTitleView(text: title)
		titleView = navigationItemActivityTitleView
	}

	func hideActivityView(with title: UINavigationItemTitle) {
		if navigationItemActivityTitleView?.titleLabel.text == title.rawValue {
			titleView = nil
			navigationItemActivityTitleView = nil
		}
	}
}
