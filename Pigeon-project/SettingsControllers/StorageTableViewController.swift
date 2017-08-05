//
//  StorageTableViewController.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

extension Double {
  
  func round(to places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
    return Darwin.round(self * divisor) / divisor
  }
  
}

class StorageTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
      
      self.title = "Data and storage"
      tableView = UITableView(frame: self.tableView.frame, style: .grouped)
      tableView.backgroundColor = UIColor.white
    }
  
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    print("appear")
    tableView.reloadData()
    
  }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let identifier = "cell"
      
      let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
      
      
      let cachedSize = SDImageCache.shared().getSize()
      
      let cachedSizeInMegabyes = (Double(cachedSize) * 0.000001).round(to: 1)
      
      print(cachedSize, cachedSizeInMegabyes)

      cell.accessoryType = .disclosureIndicator
      
      if cachedSize > 0 {
        
        cell.textLabel?.text = "Clear cache"
        cell.isUserInteractionEnabled = true
        cell.textLabel?.textColor = UIColor.black
        
      } else {
        
       cell.textLabel?.text = "Cache is empty"
       cell.isUserInteractionEnabled = false
       cell.textLabel?.textColor = UIColor.lightGray
      }
  
        return cell
    }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    let oversizeAlert = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
    
    let cachedSize = SDImageCache.shared().getSize()
    
    let cachedSizeInMegabyes = (Double(cachedSize) * 0.000001).round(to: 1)
    
    let okAction = UIAlertAction(title: "Clear (\(cachedSizeInMegabyes) MB)", style: .default) { (action) in
      
    
      SDImageCache.shared().clearDisk(onCompletion: {
        SDImageCache.shared().clearMemory()
        tableView.reloadData()
      })
    }

    oversizeAlert.addAction(okAction)
    oversizeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
     self.present(oversizeAlert, animated: true, completion: nil)
     tableView.deselectRow(at: indexPath, animated: true)
  }
  
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 65
  }
}
