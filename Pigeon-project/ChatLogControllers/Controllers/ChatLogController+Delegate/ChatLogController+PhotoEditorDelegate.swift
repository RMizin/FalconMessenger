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
import CropViewController

private let nibName = "PhotoEditorViewController"
private var selectedPhotoIndexPath: IndexPath!

extension ChatLogController: CropViewControllerDelegate {
  
  func presentPhotoEditor(forImageAt indexPath: IndexPath) {
    guard let image = inputContainerView.selectedMedia[indexPath.row].object?.asUIImage else { return }
    inputContainerView.inputTextView.resignFirstResponder()
    let cropController = CropViewController(croppingStyle: .default, image: image)
    cropController.delegate = self
    selectedPhotoIndexPath = indexPath
    self.present(cropController, animated: true, completion: nil)
  }

  func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
    guard selectedPhotoIndexPath != nil else { return }
    self.inputContainerView.selectedMedia[selectedPhotoIndexPath.row].object = image.jpegData(compressionQuality: 1)
    self.inputContainerView.attachedImages.reloadItems(at: [selectedPhotoIndexPath])
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
    //needed to update input container layout if device was rotated during the image editing
    inputContainerView.inputTextView.invalidateIntrinsicContentSize()
    inputContainerView.invalidateIntrinsicContentSize()
    DispatchQueue.main.async {
      self.inputContainerView.attachedImages.frame.size.width = self.inputContainerView.inputTextView.frame.width
    }
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
