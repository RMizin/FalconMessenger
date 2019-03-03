//
//  MenuControlsTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 2/26/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit


class MenuControlsTableViewController: UITableViewController {

	let switchCellID = "switchCellID"
	let controlButtonCellID = "controlButtonCellID"

	override func viewDidLoad() {
		super.viewDidLoad()
		configureController()
	}

	fileprivate func configureController() {
		extendedLayoutIncludesOpaqueBars = true
		definesPresentationContext = true
		edgesForExtendedLayout = UIRectEdge.top
		view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
		tableView.sectionIndexBackgroundColor = view.backgroundColor
		tableView.backgroundColor = view.backgroundColor
		tableView.separatorStyle = .none

		tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: switchCellID)
		tableView.register(GroupAdminPanelTableViewCell.self, forCellReuseIdentifier: controlButtonCellID)
	}


	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return ControlButton.cellHeight
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 { return " " }
		guard section == 1 else { return "" }
		return " "
	}

	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == 0 { return " " }
		return ""
	}

	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if section == 0 { return 20 }
		return 0
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 { return 20 }
		guard section == 1 else { return 0 }
		return 8
	}

	override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		view.tintColor = .clear
		guard section == 1 else { return }
		view.tintColor = ThemeManager.currentTheme().inputTextViewColor
	}

	override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
		view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
	}
}
