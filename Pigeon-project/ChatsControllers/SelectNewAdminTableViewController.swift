////
////  SelectNewAdminTableViewController.swift
////  Pigeon-project
////
////  Created by Roman Mizin on 3/27/18.
////  Copyright © 2018 Roman Mizin. All rights reserved.
////
//
//import UIKit
//
//let falconUsersCellID = "falconUsersCellID"
//
//
//class SelectNewAdminTableViewController: UITableViewController {
//
//
//  
//  var filteredUsers = [User]() {
//    didSet {
//      configureSections()
//    }
//  }
//
//
//  var users = [User]()
//  var sortedFirstLetters = [String]()
//  var sections = [[User]]()
//  var selectedFalconUsers = [User]()
//  var searchBar: UISearchBar?
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//      tableView.register(ParticipantTableViewCell.self, forCellReuseIdentifier: falconUsersCellID)
//      tableView.separatorStyle = .none
//      setupSearchController()
//      setupMainView()
//
//      setupTableView()
//    }
//
// override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//    return sortedFirstLetters[section]
//  }
//
//  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
//    return sortedFirstLetters
//  }
//
// override func numberOfSections(in tableView: UITableView) -> Int {
//    return sections.count
//  }
//
// override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return sections[section].count
//  }
//
// override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//    return 65
//  }
//
// override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//    view.tintColor = ThemeManager.currentTheme().inputTextViewColor
//    if let headerTitle = view as? UITableViewHeaderFooterView {
//      headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 10)
//    }
//  }
//
// override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//    return 20
//  }
//
//override  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    return selectCell(for: indexPath)!
//  }
//
//  fileprivate func selectCell(for indexPath: IndexPath) -> UITableViewCell? {
//    let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID, for: indexPath) as! ParticipantTableViewCell
//    cell.selectParticipantsViewController = self
//
//    let backgroundView = UIView()
//    backgroundView.backgroundColor = cell.backgroundColor
//    cell.selectedBackgroundView = backgroundView
//
//    let user = sections[indexPath.section][indexPath.row]
//
//    DispatchQueue.main.async {
//      cell.isSelected = user.isSelected
//    }
//
//    if let name = user.name {
//      cell.title.text = name
//    }
//
//    if let statusString = user.onlineStatus as? String {
//      if statusString == statusOnline {
//        cell.subtitle.textColor = FalconPalette.defaultBlue
//        cell.subtitle.text = statusString
//      } else {
//        cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
//        let date = Date(timeIntervalSince1970: TimeInterval(statusString)!)
//        let subtitle = "Last seen " + timeAgoSinceDate(date)
//        cell.subtitle.text = subtitle
//      }
//    } else if let statusTimeinterval = user.onlineStatus as? TimeInterval {
//      cell.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
//      let date = Date(timeIntervalSince1970: statusTimeinterval/1000)
//      let subtitle = "Last seen " + timeAgoSinceDate(date)
//      cell.subtitle.text = subtitle
//    }
//
//    guard let url = user.thumbnailPhotoURL else { return cell }
//    cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.progressiveDownload, .continueInBackground], completed: { (image, error, cacheType, url) in
//      guard image != nil else { return }
//      guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
//        cell.icon.alpha = 1
//        return
//      }
//      cell.icon.alpha = 0
//      UIView.animate(withDuration: 0.25, animations: { cell.icon.alpha = 1 })
//    })
//
//    return cell
//  }
//}
//
