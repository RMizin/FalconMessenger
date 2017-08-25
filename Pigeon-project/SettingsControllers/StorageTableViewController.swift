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
        return 2
    }

  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    print("appear")
    tableView.reloadData()
    
  }
  
  func clearDocumentsAndData() {
    let fileManager = FileManager.default
    let documentsUrl =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! as NSURL
    let documentsPath = documentsUrl.path
    
    do {
      if let documentPath = documentsPath
      {
        let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
        print("all files in cache: \(fileNames)")
        for fileName in fileNames {
          
         // if (fileName.hasSuffix(".png"))
          //{
            let filePathName = "\(documentPath)/\(fileName)"
            try fileManager.removeItem(atPath: filePathName)
          //}
        }
        
        let files = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
        print("all files in cache after deleting images: \(files)")
      }
      
    } catch {
      print("Could not clear temp folder: \(error)")
    }
  }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let identifier = "cell"
      
      let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
      
      
      if indexPath.row == 0 {
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
      }
      
      if indexPath.row == 1 {
       cell.textLabel?.text = "Clear app's Documents and Data"
      }
      
     
  
        return cell
    }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      let oversizeAlert = UIAlertController(title: "Are you shure?", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
      
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
    if indexPath.row == 1 {
       let alert = UIAlertController(title: "Ary you shure?", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
      let okAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
        
        self.clearDocumentsAndData()
        tableView.reloadData()
        ARSLineProgress.showSuccess()
        
      }
      
      alert.addAction(okAction)
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
      self.present(alert, animated: true, completion: nil)
      tableView.deselectRow(at: indexPath, animated: true)
      

    }
    
     }
  
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 65
  }
}
