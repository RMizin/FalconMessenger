//
//  ChatLogViewController+PreviewingDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/19/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import AVKit

extension ChatLogViewController: UIViewControllerPreviewingDelegate {
  func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
    guard let indexPath = collectionView.indexPathForItem(at: location) else { return nil }
    guard let cell = collectionView.cellForItem(at: indexPath) as? BaseMediaMessageCell else { return nil }
		guard cell.loadButton.isHidden == true && cell.progressView.isHidden == true else { return nil}
    let sourcePoint = cell.bubbleView.convert(cell.messageImageView.frame.origin, to: collectionView)
    let sourceRect = CGRect(x: sourcePoint.x, y: sourcePoint.y,
                            width: cell.messageImageView.frame.width, height: cell.messageImageView.frame.height)
    previewingContext.sourceRect = sourceRect
    if let viewController = openSelectedPhoto(at: indexPath) as? INSPhotosViewController {
      viewController.view.backgroundColor = .clear
			viewController.overlayView.setHidden(true, animated: false)
			viewController.currentPhotoViewController?.playerController.player?.play()
      let imageView = viewController.currentPhotoViewController?.scalingImageView.imageView
      let radius = (imageView?.image?.size.width ?? 20) * 0.05
      viewController.currentPhotoViewController?.scalingImageView.imageView.layer.cornerRadius = radius
      viewController.currentPhotoViewController?.scalingImageView.imageView.layer.masksToBounds = true
      return viewController
    }
		return nil
  }
  
  func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    if let viewController = viewControllerToCommit as? INSPhotosViewController {
      viewController.view.backgroundColor = .black
      viewController.currentPhotoViewController?.scalingImageView.imageView.layer.cornerRadius = 0
      viewController.currentPhotoViewController?.scalingImageView.imageView.layer.masksToBounds = false
			viewController.overlayView.setHidden(false, animated: false)
      present(viewController, animated: true)
    } else if let viewController = viewControllerToCommit as? AVPlayerViewController {
      present(viewController, animated: true)
    }
  }
}
