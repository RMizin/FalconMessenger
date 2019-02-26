//
//  StorageTableViewController.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import ARSLineProgress

class StorageTableViewController: MenuControlsTableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = "Data and Storage"
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: controlButtonCellID,
																						 for: indexPath) as? GroupAdminPanelTableViewCell ?? GroupAdminPanelTableViewCell()
		cell.selectionStyle = .none
		cell.button.addTarget(self, action: #selector(controlButtonClicked(_:)), for: .touchUpInside)

		if indexPath.row == 0 {
			let cachedSize = SDImageCache.shared.totalDiskSize()

			if cachedSize > 0 {
				cell.button.setTitle("Clear Cache", for: .normal)
				cell.button.isEnabled = true
			} else {
				cell.button.setTitle("Cache is Empty", for: .normal)
				cell.button.isEnabled = false
			}
		}

		if indexPath.row == 1 {
			FileManager.default.getTempSize(completion: { (size) in
				if size <= 0 {
					cell.button.setTitle("Temp is Empty", for: .normal)
					cell.button.isEnabled = false
				} else {
					cell.button.setTitle("Clear App's Temporary Data", for: .normal)
					cell.button.isEnabled = true
				}
			})
		}
		return cell
	}

	@objc fileprivate func controlButtonClicked(_ sender: UIButton) {
		guard let superview = sender.superview else { return }
		let point = tableView.convert(sender.center, from: superview)
		guard let indexPath = tableView.indexPathForRow(at: point) else {
			return
		}

		if indexPath.row == 0 {
			let oversizeAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			oversizeAlert.popoverPresentationController?.sourceView = self.view
			oversizeAlert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y:  view.bounds.maxY, width: 0, height: 0)

			let cachedSize = SDImageCache.shared.totalDiskSize()
			let cachedSizeInMegabyes = (Double(cachedSize) * 0.000001).round(to: 1)
			let okAction = UIAlertAction(title: "Clear \(cachedSizeInMegabyes) MB", style: .default) { [weak self] (action) in
				SDImageCache.shared.clearDisk(onCompletion: {
					SDImageCache.shared.clearMemory()
					self?.tableView.reloadData()
				})
			}

			oversizeAlert.addAction(okAction)
			oversizeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			self.present(oversizeAlert, animated: true, completion: nil)
			tableView.deselectRow(at: indexPath, animated: true)
		}

		if indexPath.row == 1 {
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			alert.popoverPresentationController?.sourceView = self.view
			alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y:  view.bounds.maxY, width: 0, height: 0)
			FileManager.default.getTempSize(completion: { (size) in
				let cachedSizeInMegabyes = (Double(size) * 0.000001).round(to: 1)
				let okAction = UIAlertAction(title: "Clear \(cachedSizeInMegabyes) MB", style: .default) { [weak self] (action) in
					FileManager.default.clearTemp()
					self?.tableView.reloadData()
					ARSLineProgress.showSuccess()
				}

				alert.addAction(okAction)
				alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
				self.present(alert, animated: true, completion: nil)
				tableView.deselectRow(at: indexPath, animated: true)
			})
		}
	}
}
