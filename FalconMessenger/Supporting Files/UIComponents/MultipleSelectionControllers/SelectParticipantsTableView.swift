//
//  SelectParticipantsTableView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

extension SelectParticipantsViewController: UITableViewDelegate, UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return sectionTitles.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredUsersWithSection[section].count
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 65
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sectionTitles[section]
  }
  
  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    return sectionTitles
  }
  
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
		if let headerTitle = view as? UITableViewHeaderFooterView {
			headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
			headerTitle.textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
		}
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 25
	}
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return selectCell(for: indexPath)!
  }
  
  fileprivate func selectCell(for indexPath: IndexPath) -> UITableViewCell? {
    let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID, for: indexPath) as! ParticipantTableViewCell
    cell.selectParticipantsViewController = self
    
    let backgroundView = UIView()
    backgroundView.backgroundColor = cell.backgroundColor
    cell.selectedBackgroundView = backgroundView
    
     let user = filteredUsersWithSection[indexPath.section][indexPath.row]
    
    DispatchQueue.main.async {
      cell.isSelected = user.isSelected
    }
    
    if let name = user.name {
      cell.title.text = name
    }

		cell.subtitle.text =  user.onlineStatusString
		if user.onlineStatusString == statusOnline {
			cell.subtitle.textColor = view.tintColor
		} else {
			cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
		}

    guard let url = user.thumbnailPhotoURL else { return cell }
    cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.continueInBackground], completed: { (image, error, cacheType, url) in
      guard image != nil else { return }
      guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
        cell.icon.alpha = 1
        return
      }
      cell.icon.alpha = 0
      UIView.animate(withDuration: 0.25, animations: { cell.icon.alpha = 1 })
    })
    
    return cell
  }
}
