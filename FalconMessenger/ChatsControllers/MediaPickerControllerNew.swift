//
//  MediaPickerControllerNew.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos

protocol MediaPickerDelegate: class {
  func didSelectMedia(mediaObject: MediaObject)
  func didSelectMediaNameSensitive(mediaObject: MediaObject)
  func didTakePhoto(mediaObject: MediaObject)
  func didDeselectMedia(asset: PHAsset)
}

class MediaPickerControllerNew: ImagePickerTrayController {

  var imagePicker = UIImagePickerController()
  fileprivate let imageSourceCamera = globalVariables.imageSourceCamera
  fileprivate let imageSourcePhotoLibrary = globalVariables.imageSourcePhotoLibrary
  
  weak var mediaPickerDelegate: MediaPickerDelegate?

  override func loadView() {
    super.loadView()
    print("super LOAD VIEW ")
    collectionView.backgroundColor = .clear
    view.backgroundColor = .clear
    
    delegate = self
    imagePicker.delegate = self
    imagePicker.allowsEditing = false
    imagePicker.mediaTypes = ["public.image", "public.movie"]
    
    self.add(action: .cameraAction (with: {  [weak self]  _  in
      self?.openCamera()
    }))
    
    self.add(action: .libraryAction (with: { [weak self] _ in
      self?.openPhotoLibrary()
    }))
  }
}

extension MediaPickerControllerNew: ImagePickerTrayControllerDelegate {
  
  fileprivate typealias GetUrlCompletionHandler = (_ url: String, _ success: Bool) -> Void
  
  fileprivate func getUrlFor(asset: PHAsset, completion: @escaping GetUrlCompletionHandler) {
    
    asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions(), completionHandler: { (contentEditingInput, dictInfo) in
      
      if asset.mediaType == .image {
        if let strURL = contentEditingInput?.fullSizeImageURL?.absoluteString {
          completion(strURL, true)
        }
      } else {
        if let strURL = (contentEditingInput!.audiovisualAsset as? AVURLAsset)?.url.absoluteString {
          completion(strURL, true)
        }
      }
    })
  }

  func controller(_ controller: ImagePickerTrayController, didRecordVideoAsset asset: PHAsset) {

    let filename = asset.originalFilename!
    
    let data = dataFromAsset(asset: asset)

    let manager = PHImageManager.default()
    
    manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avasset, _, _) in
      
      if let avassetURL = avasset as? AVURLAsset {

        guard let video = try? Data(contentsOf: avassetURL.url) else {
          return
        }

        self.getUrlFor(asset: asset) { (url, completed) in
          guard completed else { return }
         // if completed {

            let mediaObject = ["object": data!,
                               "videoObject": video,
                               "imageSource": self.imageSourceCamera,
                               "phAsset": asset,
                               "filename": filename,
                               "fileURL": url] as [String: AnyObject]
            self.mediaPickerDelegate?.didSelectMedia(mediaObject: MediaObject(dictionary: mediaObject))
        }
      }
    })
  }

  fileprivate func handleOlderAssetSelection(imageData: Data, videoData: Data?, imageSource: String, asset: PHAsset, filename: String) {

    getUrlFor(asset: asset) { (url, completed) in
      guard completed else { return }

        var mediaObject = [String: AnyObject]()
        
        if videoData == nil {
          
          mediaObject = ["object": imageData,
                  
                         "imageSource": imageSource,
                         "phAsset": asset,
                         "filename": filename,
                         "fileURL": url] as [String: AnyObject]
        } else {

          mediaObject = ["object": imageData,
                         "videoObject": videoData!,
                         "imageSource": imageSource,
                         "phAsset": asset,
                         "filename": filename,
                         "fileURL": url] as [String: AnyObject]
        }

        self.mediaPickerDelegate?.didSelectMediaNameSensitive(mediaObject: MediaObject(dictionary: mediaObject))
    }
  }
  
  func controller(_ controller: ImagePickerTrayController, didSelectAsset asset: PHAsset, at indexPath: IndexPath?) {
    let image = uiImageFromAsset(phAsset: asset)
    let filename = asset.originalFilename!
		var imageData = Data()
		if let assetImage = image {
			imageData = compressImage(image: assetImage)
		}
    
    if asset.mediaType == .image {
      guard let unwrappedIndexPath = indexPath else {
        self.handleOlderAssetSelection(imageData: imageData, videoData: nil, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
        return
      }
      self.handleAssetSelection(imageData: imageData, videoData: nil, indexPath: unwrappedIndexPath, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)

    } else if asset.mediaType == .video {

      let manager = PHImageManager.default()

      manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avasset, _, _) in

        if let avassetURL = avasset as? AVURLAsset {
          guard let video = try? Data(contentsOf: avassetURL.url) else {
            return
          }

          guard let unwrappedIndexPath = indexPath else {
            self.handleOlderAssetSelection(imageData: imageData, videoData: video, imageSource: self.imageSourcePhotoLibrary, asset: asset, filename: filename)
            return
          }

          self.handleAssetSelection(imageData: imageData, videoData: video, indexPath: unwrappedIndexPath, imageSource: self.imageSourcePhotoLibrary, asset: asset, filename: filename)

        } else if avasset is AVComposition {

          let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
          
          let documentsDirectory: NSString? = paths.first as NSString?

          if documentsDirectory != nil {

            let random = Int(arc4random() % 1000)
            let pathToAppend = String(format: "mergeSlowMoVideo-%d.mov", random)
            let myPathDocs = documentsDirectory!.strings(byAppendingPaths: [pathToAppend])
            let myPath = myPathDocs.first

            if myPath != nil {

              let url = URL(fileURLWithPath: myPath!)
              let exporter = AVAssetExportSession(asset: avasset!, presetName: AVAssetExportPresetHighestQuality)

              if exporter != nil {

                exporter!.outputURL = url
                exporter!.outputFileType = AVFileType.mov
                exporter!.shouldOptimizeForNetworkUse = true

                exporter!.exportAsynchronously(completionHandler: {

                  guard let url = exporter!.outputURL else {
                    return
                  }

                  guard let video = try? Data(contentsOf: url) else {
                    return
                  }

                  guard let unwrappedIndexPath = indexPath else {
                    self.handleOlderAssetSelection(imageData: imageData, videoData: video, imageSource: self.imageSourcePhotoLibrary, asset: asset, filename: filename)
                    return
                  }

                  self.handleAssetSelection(imageData: imageData, videoData: video, indexPath: unwrappedIndexPath, imageSource: self.imageSourcePhotoLibrary, asset: asset, filename: filename)
                })
              }
            }
          }
        }
      })
    }
  }

  fileprivate func handleAssetSelection(imageData: Data, videoData: Data?, indexPath: IndexPath, imageSource: String, asset: PHAsset, filename: String) {

    getUrlFor(asset: asset) { (url, completed) in
      if completed {

        var mediaObject = [String: AnyObject]()

        if videoData == nil {

          mediaObject = ["object": imageData,
                         "indexPath": indexPath,
                         "imageSource": imageSource,
                         "phAsset": asset,
                         "filename": filename,
                         "fileURL": url] as [String: AnyObject]
        } else {

          mediaObject = ["object": imageData,
                         "videoObject": videoData! ,
                         "indexPath": indexPath,
                         "imageSource": imageSource,
                         "phAsset": asset,
                         "filename": filename,
                         "fileURL": url] as [String: AnyObject]
        }
          self.mediaPickerDelegate?.didSelectMediaNameSensitive(mediaObject: MediaObject(dictionary: mediaObject))
      }
    }
  }

  func controller(_ controller: ImagePickerTrayController, didTakeImage image: UIImage, with asset: PHAsset) {
    let filename = asset.originalFilename!
    let data = dataFromAsset(asset: asset)
    var fileURL = String()

    getUrlFor(asset: asset) { (url, completed) in
      if completed {
        fileURL = url
        let mediaObject = ["object": data!,
                           "imageSource": self.imageSourceCamera,
                           "phAsset": asset,
                           "filename": filename,
                           "fileURL": fileURL] as [String: AnyObject]
          self.mediaPickerDelegate?.didSelectMedia(mediaObject: MediaObject(dictionary: mediaObject))
      }
    }
  }

  func controller(_ controller: ImagePickerTrayController, didTakeImage image: UIImage) {
    let data = compressImage(image: image)
    let mediaObject = ["object": data as AnyObject,
                       "imageSource": imageSourceCamera] as [String: AnyObject]

    self.mediaPickerDelegate?.didTakePhoto(mediaObject: MediaObject(dictionary: mediaObject))
  }

  func controller(_ controller: ImagePickerTrayController, didDeselectAsset asset: PHAsset, at indexPath: IndexPath) {
    mediaPickerDelegate?.didDeselectMedia(asset: asset)
  }
}
