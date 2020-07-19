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

	fileprivate let sectionTitles = ["Text size", "Preview", "Theme"]
	fileprivate let themesTitles = ["Default", "Dark", "Living Coral"]
	fileprivate let themes = [Theme.Default, Theme.Dark, Theme.LivingCoral]
	fileprivate let userDefaultsManager = UserDefaultsManager()

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = "Appearance"
		NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 10.0
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateAppearanceExampleTheme()
	}
	
	@objc fileprivate func changeTheme() {
		view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		tableView.backgroundColor = view.backgroundColor
		navigationItem.hidesBackButton = true
		navigationItem.hidesBackButton = false
		updateAppearanceExampleTheme()
	}

	fileprivate func updateAppearanceExampleTheme() {
		guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AppearanceExampleTableViewCell else { return }
		cell.appearanceExampleCollectionView.updateTheme()
		DispatchQueue.main.async { [weak self] in self?.tableView.reloadData() }
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? 1 : section == 1 ? 1 : themes.count
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0 {
			return 32
		} else if indexPath.section == 1 {
			return UITableView.automaticDimension
		} else {
			return ControlButton.cellHeight
		}
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sectionTitles[section]
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: appearanceTextSizeTableViewCellID,
																							 for: indexPath) as? AppearanceTextSizeTableViewCell ?? AppearanceTextSizeTableViewCell()
			cell.sliderView.delegate = self
			return cell
		} else if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: appearanceExampleTableViewCellID,
																							 for: indexPath) as? AppearanceExampleTableViewCell ?? AppearanceExampleTableViewCell()
			return cell
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: controlButtonCellID,
																						 for: indexPath) as? GroupAdminPanelTableViewCell ?? GroupAdminPanelTableViewCell()
		cell.selectionStyle = .none
		cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		cell.button.addTarget(self, action: #selector(controlButtonClicked(_:)), for: .touchUpInside)
		cell.button.setTitle(themesTitles[indexPath.row], for: .normal)
		cell.button.setTitleColor(ThemeManager.currentTheme().controlButtonTintColor, for: .normal)
		cell.button.backgroundColor = ThemeManager.currentTheme().controlButtonColor

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
        if let navigationBar = navigationController?.navigationBar {
            ThemeManager.setNavigationBarAppearance(navigationBar)
        }
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
		updateAppearanceExampleTheme()
	}
}
