//
//  ChatInputContainer+AttachedImagesCollectionConfig.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


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
    
    let row = indexPath?.row
  
    if selectedMedia[row!].imageSource == imageSourcePhotoLibrary {
      
      if let selectedIndexPath = selectedMedia[row!].indexPath {
        
          self.mediaPickerController?.customMediaPickerView.collectionView.deselectItem(at: selectedIndexPath , animated: false)
        
          self.mediaPickerController?.customMediaPickerView.delegate?.controller?(self.mediaPickerController!.customMediaPickerView,
                                                                                  didDeselectAsset: self.selectedMedia[row!].phAsset!,
                                                                                  at: selectedIndexPath)
        }
       
    } else {
      
        selectedMedia.remove(at: row!)
        attachedImages.deleteItems(at: [indexPath!])
        resetChatInputConntainerViewSettings()
    }
   
  }

 
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = attachedImages.dequeueReusableCell(withReuseIdentifier: selectedMediaCollectionCellID, for: indexPath) as! SelectedMediaCollectionCell
    
    DispatchQueue.main.async {
      cell.image.image = self.selectedMedia[indexPath.item].object?.asUIImage
    }
    
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
    
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
      let oldHeight = self.selectedMedia[indexPath.row].object?.asUIImage!.size.height
    
      let scaleFactor = selectedMediaCollectionCellHeight / oldHeight!
      
      let newWidth = self.selectedMedia[indexPath.row].object!.asUIImage!.size.width * scaleFactor
    
      let newHeight = oldHeight! * scaleFactor
      
      return CGSize(width: newWidth , height: newHeight)
  }
}
