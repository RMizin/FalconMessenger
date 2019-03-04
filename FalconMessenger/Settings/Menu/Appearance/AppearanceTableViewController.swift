//
//  AppearanceTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 3/1/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

enum DefaultMessageTextFontSize: Float {
	case extraSmall = 14
	case small = 15
	case medium = 16
	case regular = 17
	case large = 19
	case extraLarge = 23
	case extraLargeX2 = 26

	static func allFontSizes() -> [Float] {
		return [DefaultMessageTextFontSize.extraSmall.rawValue,
						DefaultMessageTextFontSize.small.rawValue,
						DefaultMessageTextFontSize.medium.rawValue,
						DefaultMessageTextFontSize.regular.rawValue,
						DefaultMessageTextFontSize.large.rawValue,
						DefaultMessageTextFontSize.extraLarge.rawValue,
						DefaultMessageTextFontSize.extraLargeX2.rawValue]
	}
}

class AppearanceTableViewController: MenuControlsTableViewController {

	let themesTitles = ["Default", "Dark", "Living Coral"]
	let themes = [Theme.Default, Theme.Dark, Theme.LivingCoral]
	let userDefaultsManager = UserDefaultsManager()

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = "Appearance"
		NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)

		let currentValue = userDefaultsManager.currentFloatObjectState(for: userDefaultsManager.chatLogDefaultFontSizeID)
		let sliderView = UIIncrementSliderView(values: DefaultMessageTextFontSize.allFontSizes(),
																			 currentValue: currentValue)
		sliderView.slider.delegate = self
		sliderView.frame.size.height = 100
		tableView.tableHeaderView = sliderView
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc fileprivate func changeTheme() {
		view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		tableView.backgroundColor = view.backgroundColor
		tableView.reloadData()
		navigationItem.hidesBackButton = true
		navigationItem.hidesBackButton = false
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return themes.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: controlButtonCellID,
																						 for: indexPath) as? GroupAdminPanelTableViewCell ?? GroupAdminPanelTableViewCell()
		cell.selectionStyle = .none
		cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		cell.button.addTarget(self, action: #selector(controlButtonClicked(_:)), for: .touchUpInside)
		cell.button.setTitle(themesTitles[indexPath.row], for: .normal)
		cell.button.setTitleColor(ThemeManager.currentTheme().controlButtonTintColor, for: .normal)
		cell.button.backgroundColor = ThemeManager.currentTheme().controlButtonsColor

		if themes[indexPath.row] == ThemeManager.currentTheme() {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}

		return cell
	}

	@objc fileprivate func controlButtonClicked(_ sender: UIButton) {
		guard let superview = sender.superview else { return }
		let point = tableView.convert(sender.center, from: superview)
		guard let indexPath = tableView.indexPathForRow(at: point) else { return }
		ThemeManager.applyTheme(theme: themes[indexPath.row])
	}
}

extension AppearanceTableViewController: UIIncrementSliderUpdateDelegate {
	func incrementSliderDidUpdate(to value: CGFloat) {

		autoreleasepool {
			try! RealmKeychain.defaultRealm.safeWrite {
				for object in RealmKeychain.defaultRealm.objects(Conversation.self) {
					object.shouldUpdateRealmRemotelyBeforeDisplaying.value = true
				}
			}
		}

		userDefaultsManager.updateObject(for: userDefaultsManager.chatLogDefaultFontSizeID, with: Float(value))
	}
}
