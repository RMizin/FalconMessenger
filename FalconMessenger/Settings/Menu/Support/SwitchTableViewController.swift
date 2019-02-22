//
//  SwitchTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/17/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SwitchTableViewController: UITableViewController {

  override func viewDidLoad() {
      super.viewDidLoad()
    configureController()
  }
  
  fileprivate func configureController() {
    
    tableView = UITableView(frame: self.tableView.frame, style: .grouped)
    tableView.separatorStyle = .none
    extendedLayoutIncludesOpaqueBars = true
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  func setTitle(_ title: String) {
    self.title = title
  }
  
  func registerCell(for id: String) {
    tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: id)
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 10
  }
}
