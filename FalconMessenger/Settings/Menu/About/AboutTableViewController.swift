//
//  AboutTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/9/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SafariServices

class AboutTableViewController: MenuControlsTableViewController {

  fileprivate let cellData = ["Privacy Policy", "Terms And Conditions", "Open Source Libraries"]
  fileprivate let legalData = ["https://docs.google.com/document/d/1r365Yan3Ng4l0T4o7UXqLid8BKm4N4Z3cSGTnzzA7Fg/edit?usp=sharing", /*PRIVACY POLICY*/
    "https://docs.google.com/document/d/19PQFh9LzXz1HO2Zq6U7ysCESIbGoodY6rBJbOeCyjkc/edit?usp=sharing", /*TERMS AND CONDITIONS*/
    "https://docs.google.com/document/d/12u1ZmTDV79NwcOqLXHnPVPFfmAHZzibEoJNKyWEKHME/edit?usp=sharing" /*OPEN SOURCE LIBRARIES*/]
  
  override func viewDidLoad() {
    super.viewDidLoad()
		navigationItem.title = "About"
  }

  deinit {
    print("About DID DEINIT")
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 3
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: controlButtonCellID,
																						 for: indexPath) as? GroupAdminPanelTableViewCell ?? GroupAdminPanelTableViewCell()
		cell.selectionStyle = .none
		cell.button.addTarget(self, action: #selector(controlButtonClicked(_:)), for: .touchUpInside)
		cell.button.setTitle(cellData[indexPath.row], for: .normal)

    return cell
  }

	@objc fileprivate func controlButtonClicked(_ sender: UIButton) {
		guard let superview = sender.superview else { return }
		let point = tableView.convert(sender.center, from: superview)
		guard let indexPath = tableView.indexPathForRow(at: point) else { return }
		
		guard let url = URL(string: legalData[indexPath.row]) else { return }
		var safariViewController = SFSafariViewController(url: url)

		if #available(iOS 11.0, *) {
			let configuration = SFSafariViewController.Configuration()
			configuration.entersReaderIfAvailable = true
			safariViewController = SFSafariViewController(url: url, configuration: configuration)
		}

		safariViewController.preferredControlTintColor = view.tintColor
		safariViewController.preferredBarTintColor = ThemeManager.currentTheme().generalBackgroundColor
		present(safariViewController, animated: true, completion: nil)
	}
}
