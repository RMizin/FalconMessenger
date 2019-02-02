//
//  GroupAdminControlsTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class GroupAdminPanelTableViewCell: UITableViewCell {

	var button: ControlButton = {
		var button = ControlButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    selectionColor = .clear

		addSubview(button)
    button.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
    button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true

    if #available(iOS 11.0, *) {
      button.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
      button.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
    } else {
      button.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
      button.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
  }
}
