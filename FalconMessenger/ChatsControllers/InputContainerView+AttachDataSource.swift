//
//  InputContainerView+AttachDataSource.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos

private let attachCollectionViewCellID = "attachCollectionViewCellID"

extension InputContainerView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  
  func configureAttachCollectionView() {
    attachCollectionView.delegate = self
    attachCollectionView.dataSource = self
    attachCollectionView.register(AttachCollectionViewCell.self, forCellWithReuseIdentifier: attachCollectionViewCellID)
  }
  
 @objc func removeButtonDidTap(sender: UIButton) {
    guard let cell = sender.superview as? AttachCollectionViewCell,
      let indexPath = attachCollectionView.indexPath(for: cell) else { return }
		let row = indexPath.row

		guard let asset = attachedMedia[row].phAsset,	let picker = mediaPickerController else {
			attachedMedia.remove(at: row)
			attachCollectionView.deleteItems(at: [indexPath])
			resetChatInputConntainerViewSettings()
			return
		}

		if picker.assets.contains(asset) {
			deselectAsset(row: row)
		} else {
			attachedMedia.remove(at: row)
			attachCollectionView.deleteItems(at: [indexPath])
			resetChatInputConntainerViewSettings()
		}
  }
  
  func deselectAsset(row: Int) {
		guard let picker = mediaPickerController,
			attachedMedia.indices.contains(row),
			let asset = attachedMedia[row].phAsset,
			let index = picker.assets.firstIndex(of: asset) else { return }

		let indexPath = IndexPath(item: index, section: ImagePickerTrayController.librarySectionIndex)
		picker.collectionView.deselectItem(at: indexPath, animated: true)
		picker.delegate?.controller?(picker, didDeselectAsset: asset, at: indexPath)
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = attachCollectionView.dequeueReusableCell(withReuseIdentifier: attachCollectionViewCellID,
                                                        for: indexPath) as? AttachCollectionViewCell ?? AttachCollectionViewCell()
    
    cell.chatInputContainerView = self
  
    cell.isVideo = attachedMedia[indexPath.item].phAsset?.mediaType == .video
   
    guard let image = self.attachedMedia[indexPath.item].object?.asUIImage else { // it is voice message
      let data = attachedMedia[indexPath.row].audioObject!
      let duration = getAudioDurationInHours(from: data)
      cell.image.contentMode = .scaleAspectFit
      cell.image.image = UIImage(named: "VoiceMemo")
      cell.playerViewHeightAnchor.constant = 20
      cell.playerView.timerLabel.text = duration
      cell.playerView.startingTime = getAudioDurationInSeconds(from: data)!
      cell.playerView.seconds = getAudioDurationInSeconds(from: data)!
   
      return cell
    }
    
    cell.image.image = image
    
    return cell
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return attachedMedia.count
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if attachedMedia[indexPath.item].audioObject != nil {
      return
    }
    
    if attachedMedia[indexPath.item].phAsset?.mediaType == PHAssetMediaType.image || attachedMedia[indexPath.item].phAsset == nil {
      chatLogController?.presentPhotoEditor(forImageAt: indexPath)
    }
    
    if attachedMedia[indexPath.item].phAsset?.mediaType == PHAssetMediaType.video {
      chatLogController?.presentVideoPlayer(forUrlAt: indexPath)
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    guard attachedMedia.indices.contains(indexPath.row) else { return CGSize(width: 0, height: 0) }
    
    guard attachedMedia[indexPath.row].audioObject != nil else {
      let oldHeight = self.attachedMedia[indexPath.row].object?.asUIImage!.size.height
      let scaleFactor = AttachCollectionView.cellHeight / oldHeight!
      let newWidth = self.attachedMedia[indexPath.row].object!.asUIImage!.size.width * scaleFactor
      let newHeight = oldHeight! * scaleFactor
      
      return CGSize(width: newWidth, height: newHeight)
    }

    let oldHeight = UIImage(named: "VoiceMemo")!.size.height
    let scaleFactor = AttachCollectionView.cellHeight / oldHeight
    let newWidth = UIImage(named: "VoiceMemo")!.size.width * scaleFactor
    let newHeight = oldHeight * scaleFactor

    return CGSize(width: newWidth, height: newHeight)
  }
  
 private func getAudioDurationInHours(from data: Data) -> String? {
    do {
      audioPlayer = try AVAudioPlayer(data: data)
      let duration = Int(audioPlayer!.duration)
      let hours = Int(duration) / 3600
      let minutes = Int(duration) / 60 % 60
      let seconds = Int(duration) % 60
      return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    } catch {
      print("error playing")
      return String(format: "%02i:%02i:%02i", 0, 0, 0)
    }
  }
  
  private func getAudioDurationInSeconds(from data: Data) -> Int? {
    do {
      audioPlayer = try AVAudioPlayer(data: data)
      let duration = Int(audioPlayer!.duration)
      return duration
    } catch {
      print("error playing")
      return nil
    }
  }
}
