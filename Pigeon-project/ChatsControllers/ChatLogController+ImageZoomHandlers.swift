//
//  ChatLogController+ImageZoomHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/26/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit


private var inputContainerViewWasFirstResponder = false


extension ChatLogController {

  func performZoomInForVideo( url: URL) {
  
    let player = AVPlayer(url: url)
    
    let inBubblePlayerViewController = AVPlayerViewController()
  
    inBubblePlayerViewController.player = player
    
    inBubblePlayerViewController.modalTransitionStyle = .crossDissolve
    
    inBubblePlayerViewController.modalPresentationStyle = .overCurrentContext
    
    if self.inputContainerView.inputTextView.isFirstResponder {
      self.inputContainerView.inputTextView.resignFirstResponder()
    }
  
    present(inBubblePlayerViewController, animated: true, completion: nil)
  }
  
  
  func performZoomInForStartingImageView(_ initialImageView: UIImageView, indexPath: IndexPath) {
  
   setupPhotos(indexPath: indexPath)
  }
}
