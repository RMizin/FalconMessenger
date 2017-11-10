//
//  AboutTableViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/9/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class AboutTableViewController: UITableViewController {

  
  let cellData = ["Privacy Policy", "Terms", "Open Source Libraries"]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureController()
  }
  
  fileprivate func configureController() {
    
    tableView = UITableView(frame: self.tableView.frame, style: .grouped)
    tableView.separatorStyle = .none
    
    title = "About"
    extendedLayoutIncludesOpaqueBars = true
    view.backgroundColor = .white
    navigationController?.navigationBar.backgroundColor = .white
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
    
    let identifier = "cell"
    
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
    cell.accessoryType = .disclosureIndicator
    cell.textLabel?.text = cellData[indexPath.row]
    cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
    
    return cell
  }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 65
  }
}
