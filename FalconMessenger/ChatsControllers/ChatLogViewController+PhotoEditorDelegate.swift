//
//  ChatLogController+PhotoEditorDelegate.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/23/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos
import AVKit
import CropViewController

private let nibName = "PhotoEditorViewController"
private var selectedPhotoIndexPath: IndexPath!

extension ChatLogViewController: CropViewControllerDelegate {
  
  func presentPhotoEditor(forImageAt indexPath: IndexPath) {
    guard let image = inputContainerView.attachedMedia[indexPath.row].object?.asUIImage else { return }
    inputContainerView.resignAllResponders()
    let cropController = CropViewController(croppingStyle: .default, image: image)
    cropController.delegate = self
    selectedPhotoIndexPath = indexPath
    self.present(cropController, animated: true, completion: nil)
  }

  func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
    guard selectedPhotoIndexPath != nil else { return }
    self.inputContainerView.attachedMedia[selectedPhotoIndexPath.row].object = image.jpegData(compressionQuality: 1)
    self.inputContainerView.attachCollectionView.reloadItems(at: [selectedPhotoIndexPath])
    dismissCropController(cropViewController: cropViewController)
  }
  
  func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
    dismissCropController(cropViewController: cropViewController)
  }
  
  func dismissCropController(cropViewController: CropViewController) {
    selectedPhotoIndexPath = nil
    cropViewController.dismiss(animated: true, completion: nil)
    cropViewController.delegate = nil //to avoid memory leaks
    updateContainerViewLayout()
  }
  
  func updateContainerViewLayout() {
    inputContainerView.handleRotation()
    //needed to update input container layout if device was rotated during the image editing
  }
  
  func presentVideoPlayer(forUrlAt indexPath: IndexPath) {
    guard let pathURL = inputContainerView.attachedMedia[indexPath.item].fileURL else { return }
    let videoURL = URL(string: pathURL)
    let player = AVPlayer(url: videoURL!)
    let playerViewController = AVPlayerViewController()
    if DeviceType.isIPad {
      playerViewController.modalPresentationStyle = .overFullScreen
    } else {
      playerViewController.modalPresentationStyle = .overCurrentContext
    }
 
    playerViewController.player = player
    inputContainerView.resignAllResponders()
    present(playerViewController, animated: true, completion: nil)
  }
}
