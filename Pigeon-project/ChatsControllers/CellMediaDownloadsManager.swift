//
//  CellMediaDownloadsManager.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 2/17/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage


extension ChatLogController {
  
}
protocol DownloadDelegate: class {
  func downloadProgressUpdate(for cell: RevealableCollectionViewCell, progress: Float)
}


final class DownloadTask {
  
  weak var delegate: DownloadDelegate?
  
  // Other properties
  var cell: RevealableCollectionViewCell!
  var progress: Float = 0.0 {
    didSet {
      updateProgress()
    }
  }
  
  // Gives float for download progress - for delegate
  
  private func updateProgress() {
    delegate?.downloadProgressUpdate(for: cell, progress: progress)
  }
  
  // Initialization
}

extension ChatLogController: DownloadDelegate {
  func downloadProgressUpdate(for cell: RevealableCollectionViewCell, progress: Float) {
  //  cell.progres
//    DispatchQueue.main.async {
//      self.progressView.progress += progress
//      self.downloadProgressLabel.text =  String(format: "%.1f%%", progress * 100)
//    }
  }
  

}
