//
//  ChatLogController+PhotoEditor.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/23/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos
import AVKit

private let nibName = "PhotoEditorViewController"

extension ChatLogController: PhotoEditorDelegate {
  
  func doneEditing(image: UIImage, indexPath: IndexPath) {
    inputContainerView.selectedMedia[indexPath.row].object = UIImageJPEGRepresentation(image, 1)
    inputContainerView.attachedImages.reloadItems(at: [indexPath])
  }
  
  func canceledEditing() {
    print("Canceled")
  }
  
  func presentPhotoEditor(forImageAt indexPath: IndexPath) {
    let photoEditor = PhotoEditorViewController(nibName: nibName, bundle: Bundle(for: PhotoEditorViewController.self))
    
    photoEditor.photoEditorDelegate = self
    
    photoEditor.image = inputContainerView.selectedMedia[indexPath.row].object?.asUIImage
    
    photoEditor.hiddenControls = [.text]
    
    photoEditor.modalPresentationStyle = .overCurrentContext
    
    photoEditor.sentIndexPath = indexPath
    
    inputContainerView.inputTextView.resignFirstResponder()
    
    present(photoEditor, animated: true, completion: nil)
  }
  
  func presentVideoPlayer(forUrlAt indexPath: IndexPath) {
    
    guard let pathURL = inputContainerView.selectedMedia[indexPath.item].fileURL else { return }
    
    let videoURL = URL(string: pathURL)
    
    let player = AVPlayer(url: videoURL!)
    
    let playerViewController = AVPlayerViewController()
    
    playerViewController.modalPresentationStyle = .overCurrentContext
    
    playerViewController.player = player
    
    inputContainerView.inputTextView.resignFirstResponder()
    
    present(playerViewController, animated: true, completion: nil)
  }
}





