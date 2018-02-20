//
//  CellMediaDownloadsManager.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 2/17/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//
//

/*
 
import UIKit
import SDWebImage

var downloadTask:[DownloadTask] = []

extension ChatLogController {
 
  func handleMediaDownload(for message: Message) {
    
    guard let index = downloadTask.index(where: { (task) -> Bool in
      return task.id == message.messageUID
    }) else {
      return
    }
    
    guard let url = downloadTask[index].url else { return }
  
    downloadTask[index].imageView.sd_setImage(with: url, placeholderImage: nil, options: [.scaleDownLargeImages, .continueInBackground], progress: { (downloaded, expected, url) in
      
      downloadTask[index].progress = downloadTask[index].imageView.sd_imageProgress.fractionCompleted
      
    }, completed: { (image, error, cacheType, url) in
      downloadTask[index].finished = true
      downloadTask[index].downloading = false
    })
  }
}// ext


class DownloadTask {
  
  var id: String?
  var url: URL?
  var imageView = UIImageView()
  var progress: Double = 0.0 {
    didSet {
      if progress >= 100 {
        finished = true
        downloading = false
      } else {
        finished = false
        downloading = true
      }
    }
  }
  
  var finished = false
  var downloading = false
  
  init(dictionary: [String: AnyObject]) {
    self.id = dictionary["id"] as? String
    self.url = dictionary["url"] as? URL
  }
}
 
*/


