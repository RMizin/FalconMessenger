//
//  FalconTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 2/22/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class FalconTableViewController: UITableViewController {

	fileprivate let falconNavigationItem = FalconNavigationItem()

	override var navigationItem: FalconNavigationItem {
		return falconNavigationItem
	}
}
