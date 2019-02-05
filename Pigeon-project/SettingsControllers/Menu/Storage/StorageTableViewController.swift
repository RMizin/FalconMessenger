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

extension Double {
  func round(to places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return Darwin.round(self * divisor) / divisor
  }
}

class StorageTableViewController: UITableViewController {

  deinit {
    print("STORAGE DID DEINIT")
  }
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
      title = "Data and Storage"
      tableView = UITableView(frame: self.tableView.frame, style: .grouped)
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      tableView.backgroundColor = view.backgroundColor
      tableView.separatorStyle = .none
      extendedLayoutIncludesOpaqueBars = true
    }
  
    override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
    }
  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let identifier = "cell"
      
      let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
      
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
      cell.backgroundColor = view.backgroundColor
      
      if indexPath.row == 0 {
        let cachedSize = SDImageCache.shared.totalDiskSize()
        
        let cachedSizeInMegabyes = (Double(cachedSize) * 0.000001).round(to: 1)
        
        print(cachedSize, cachedSizeInMegabyes)
        
        if cachedSize > 0 {
          
          cell.textLabel?.text = "Clear Cache"
          cell.isUserInteractionEnabled = true
          cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
          
        } else {
          
          cell.textLabel?.text = "Cache is Empty"
          cell.isUserInteractionEnabled = false
          cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        }
      }
      
      if indexPath.row == 1 {
       cell.textLabel?.text = "Clear Temporary Docs and Data"
       cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
      }
      return cell
    }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      let oversizeAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
      oversizeAlert.popoverPresentationController?.sourceView = self.view
      oversizeAlert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y:  view.bounds.maxY, width: 0, height: 0)
      
      let cachedSize = SDImageCache.shared.totalDiskSize()
      
      let cachedSizeInMegabyes = (Double(cachedSize) * 0.000001).round(to: 1)
      
      let okAction = UIAlertAction(title: "Clear \(cachedSizeInMegabyes) MB", style: .default) { (action) in
        
        SDImageCache.shared.clearDisk(onCompletion: {
          SDImageCache.shared.clearMemory()
          tableView.reloadData()
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
      let okAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
        FileManager.default.clearTemp()
        tableView.reloadData()
        ARSLineProgress.showSuccess()
      }
      
      alert.addAction(okAction)
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
      self.present(alert, animated: true, completion: nil)
      tableView.deselectRow(at: indexPath, animated: true)
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 65
  }
}
