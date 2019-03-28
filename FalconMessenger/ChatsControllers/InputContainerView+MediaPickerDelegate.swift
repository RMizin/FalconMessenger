//
//  InputContainerView+MediaPickerDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/21/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Photos

extension InputContainerView: MediaPickerDelegate {
  
  func didSelectMedia(mediaObject: MediaObject) {
    attachedMedia.append(mediaObject)
    
    if attachedMedia.count - 1 >= 0 {
      insertItemsToCollectionViewAnimated(at: [IndexPath(item: attachedMedia.count - 1, section: 0)])
    } else {
      insertItemsToCollectionViewAnimated(at: [IndexPath(item: 0, section: 0)])
    }
  }
  
  func didSelectMediaNameSensitive(mediaObject: MediaObject) {
		if let _ = attachedMedia.firstIndex(where: { (item) -> Bool in
      return item.filename == mediaObject.filename!
    }) {
      return
    }
    
    attachedMedia.append(mediaObject)
    
    if attachedMedia.count - 1 >= 0 {
      insertItemsToCollectionViewAnimated(at: [IndexPath(item: attachedMedia.count - 1, section: 0)])
    } else {
      insertItemsToCollectionViewAnimated(at: [IndexPath(item: 0, section: 0)])
    }
  }
  
  func didTakePhoto(mediaObject: MediaObject) {
    attachedMedia.append(mediaObject)
    
    if attachedMedia.count - 1 >= 0 {
      if libraryAccessChecking() {
        insertItemsToCollectionViewAnimated(at: [IndexPath(item: attachedMedia.count - 1, section: 0)])
      } else {
        DispatchQueue.main.async {
          self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: self.attachedMedia.count - 1, section: 0)])
        }
      }
    } else {
      insertItemsToCollectionViewAnimated(at: [IndexPath(item: 0, section: 0)])
    }
  }
  
  func didDeselectMedia(asset: PHAsset) {
		guard let index = attachedMedia.firstIndex(where: { (item) -> Bool in
      return item.filename == asset.originalFilename
    }) else {
      print("returning1")
      return
    }
    
    deleteItemsToCollectionViewAnimated(at: IndexPath(item: index, section: 0), index: index)
  }
  
  fileprivate func deleteItemsToCollectionViewAnimated(at indexPath: IndexPath, index: Int) {
    if attachCollectionView.cellForItem(at: indexPath) == nil || !attachedMedia.indices.contains(index) {
      print("returning2")
      attachedMedia.remove(at: index)
      attachCollectionView.reloadData()
      return
    }
    
    attachedMedia.remove(at: index)
    attachCollectionView.deleteItems(at: [indexPath])
    resetChatInputConntainerViewSettings()
  }

  fileprivate func insertItemsToCollectionViewAnimated(at indexPath: [IndexPath]) {
    expandCollection()
    attachCollectionView.performBatchUpdates ({
      attachCollectionView.insertItems(at: indexPath)
    }, completion: nil)
    attachCollectionView.scrollToItem(at: IndexPath(item: attachedMedia.count - 1, section: 0),
                                      at: .right, animated: true)
  }
  
  func checkAuthorisationStatus() {
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .authorized:
      break
    case .denied, .restricted:
      break
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization { status in
        switch status {
        case .authorized:
          self.mediaPickerController?.imageManager = PHCachingImageManager()
          self.mediaPickerController?.fetchAssets()
					DispatchQueue.main.async { [weak self] in
						self?.mediaPickerController?.collectionView.reloadData()
					}

        case .denied, .restricted, .notDetermined:
          break
				@unknown default:
					fatalError()
				}
      }
		@unknown default:
			fatalError()
		}
  }
}
