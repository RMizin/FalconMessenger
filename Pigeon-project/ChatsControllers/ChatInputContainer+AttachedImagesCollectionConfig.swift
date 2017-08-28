//
//  ChatInputContainer+AttachedImagesCollectionConfig.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos


private let selectedMediaCollectionCellID = "selectedMediaCollectionCellID"

private let selectedMediaCollectionCellHeight:CGFloat = 155

extension ChatInputContainerView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  
  
  func configureAttachedImagesCollection() {
    
    attachedImages.delegate = self
    
    attachedImages.dataSource = self
    
    attachedImages.showsVerticalScrollIndicator = false
    
    attachedImages.showsHorizontalScrollIndicator = false
    
    attachedImages.backgroundColor = inputTextView.backgroundColor
    
    attachedImages.register(SelectedMediaCollectionCell.self, forCellWithReuseIdentifier: selectedMediaCollectionCellID)
    
    centeredCollectionViewFlowLayout.minimumLineSpacing = 5
    
    centeredCollectionViewFlowLayout.minimumInteritemSpacing = 5
    
    centeredCollectionViewFlowLayout.estimatedItemSize = CGSize(width: 100, height: selectedMediaCollectionCellHeight)
    
    attachedImages.autoresizesSubviews = false
  }
  
  func removeButtonDidTap(sender: UIButton) {
    
    guard let cell = sender.superview as? SelectedMediaCollectionCell else {
      return
    }
    
    let indexPath = attachedImages.indexPath(for: cell)
    
    let row = indexPath!.row
  
    if selectedMedia[row].imageSource == imageSourcePhotoLibrary {
      
      if mediaPickerController!.customMediaPickerView.assets.contains(selectedMedia[row].phAsset!) {
        deselectAsset(row: row)
      }
      
    } else {
    
      if selectedMedia[row].phAsset != nil && mediaPickerController!.customMediaPickerView.assets.contains(selectedMedia[row].phAsset!) {
        deselectAsset(row: row)
      } else {
        
        selectedMedia.remove(at: row)
        attachedImages.deleteItems(at: [indexPath!])
        resetChatInputConntainerViewSettings()
      }
    }
  }
  
  func deselectAsset(row: Int) {
    
      let index = mediaPickerController!.customMediaPickerView.assets.index(of: selectedMedia[row].phAsset!)
    
      let indexPath = IndexPath(item: index!, section: 2)
      
      self.mediaPickerController?.customMediaPickerView.collectionView.deselectItem(at: indexPath , animated: false)
      
      self.mediaPickerController?.customMediaPickerView.delegate?.controller?(self.mediaPickerController!.customMediaPickerView,
                                                                              didDeselectAsset: self.selectedMedia[row].phAsset!,
                                                                              at: indexPath)
  }

 
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = attachedImages.dequeueReusableCell(withReuseIdentifier: selectedMediaCollectionCellID, for: indexPath) as! SelectedMediaCollectionCell
    
    DispatchQueue.main.async {
      cell.image.image = self.selectedMedia[indexPath.item].object?.asUIImage
    }
    
     cell.isVideo = selectedMedia[indexPath.item].phAsset?.mediaType == .video
    
    return cell
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    attachedImages.collectionViewLayout.invalidateLayout()
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return selectedMedia.count
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    print("selected")
    
    if selectedMedia[indexPath.item].phAsset?.mediaType == PHAssetMediaType.image || selectedMedia[indexPath.item].phAsset == nil {
      chatLogController?.presentPhotoEditor(forImageAt: indexPath)
    }
    
    if selectedMedia[indexPath.item].phAsset?.mediaType == PHAssetMediaType.video {
      chatLogController?.presentVideoPlayer(forUrlAt: indexPath)
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
      let oldHeight = self.selectedMedia[indexPath.row].object?.asUIImage!.size.height
    
      let scaleFactor = selectedMediaCollectionCellHeight / oldHeight!
      
      let newWidth = self.selectedMedia[indexPath.row].object!.asUIImage!.size.width * scaleFactor
    
      let newHeight = oldHeight! * scaleFactor
      
      return CGSize(width: newWidth , height: newHeight)
  }
}
