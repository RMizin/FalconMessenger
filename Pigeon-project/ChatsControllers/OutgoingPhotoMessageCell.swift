//
//  PhotoMessageCell.swift
//  Avalon-Print
//
//  Created by Roman Mizin on 7/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit



//class MediaDownloader: NSObject {
//
//  var url: String?
//  var message: Message?
//  var downloadingProgress: CGFloat?
//  //var imagePreview: UIImageView?
//
//  //, imagePreview: UIImageView?
//  init(message: Message, url: String?, downloadingProgress: CGFloat? ) {
//
//    self.url = url
//    self.message = message
//    self.downloadingProgress = downloadingProgress
//   // self.imagePreview = imagePreview
//
//  }
//}




class PhotoMessageCell: BaseMediaMessageCell {


//  
//  var currentDownload: MediaDownloader? {
//    didSet {
//      
//      guard let download = currentDownload else { return }
//      
//      
//      if mediaDownloader.contains(where: { $0.message == message }) {
//        print("mediaDownloader.contains(download)")
//      } else {
//        mediaDownloader.append(download)
//        print(" =( =( =( mediaDownloader NOT contains(download)")
//      }
//
//      
//    
//      
//     let downloadIndex = mediaDownloader.index { (downloadTask) -> Bool in
//        return downloadTask == download
//      }
//      print("Download index", downloadIndex ?? 9999.0)
//      guard let url = download.url else { return }
//      messageImageView.sd_setImage(with: URL(string: url),
//                                    placeholderImage: nil,
//                                    options: [.continueInBackground, .scaleDownLargeImages, .retryFailed],
//                                    progress: { (downloadedSize, expectedSize, url) in
//          
//            let progress = Double(100 * downloadedSize/expectedSize)
//            guard let unwrappedDownloadIndex = downloadIndex else { return }
//                                     
//        //    download.downloadingProgress =
//              
//              self.mediaDownloader[unwrappedDownloadIndex].downloadingProgress = CGFloat(progress)
//                                      
//         //   DispatchQueue.main.async {
//              self.progressView.percent = Double(self.mediaDownloader[unwrappedDownloadIndex].downloadingProgress ?? 0.0)
//           //   self.progressView.setNeedsLayout()
//           //   self.progressView.layoutIfNeeded()
//           // }
//          
//      }, completed: { (image, error, cacheType, url) in
//        self.progressView.isHidden = false
//        self.messageImageView.isUserInteractionEnabled = false
//        self.playButton.isHidden = self.currentDownload?.message?.videoUrl == nil && self.currentDownload?.message?.localVideoUrl == nil
//      })
//    }
//  }

  override func setupViews() {
    
    bubbleView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:))) )
  
    contentView.addSubview(bubbleView)
    
    bubbleView.addSubview(messageImageView)
    
    bubbleView.frame.size.width = 200
    
    bubbleView.image = blueBubbleImage
    
    progressView.progressColor =  UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    progressView.progressBackgroundColor =  UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
    
    contentView.addSubview(deliveryStatus)

    messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 4).isActive = true
    messageImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4).isActive = true
    messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 4).isActive = true
    messageImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -9).isActive = true
    
    bubbleView.addSubview(playButton)
    playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
    playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
    bubbleView.addSubview(progressView)
    progressView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
    progressView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
    progressView.widthAnchor.constraint(equalToConstant: 75).isActive = true
    progressView.heightAnchor.constraint(equalToConstant: 75).isActive = true
  }
  
  override func prepareViewsForReuse() {
    bubbleView.image = blueBubbleImage
    playButton.isHidden = true
  }
}
