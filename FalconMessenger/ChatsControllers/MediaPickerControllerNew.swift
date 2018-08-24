//
//  MediaPickerControllerNew.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos


class MediaPickerControllerNew: ImagePickerTrayController {
  
  var imagePicker: UIImagePickerController! = UIImagePickerController()
  weak var inputContainerView: InputContainerView?
  
  fileprivate let imageSourceCamera = globalDataStorage.imageSourceCamera
  fileprivate let imageSourcePhotoLibrary = globalDataStorage.imageSourcePhotoLibrary

  override func loadView() {
    super.loadView()
    collectionView.backgroundColor = .clear
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
  
  fileprivate typealias getUrlCompletionHandler = (_ url: String, _ success: Bool) -> Void
  
  fileprivate func getUrlFor(asset: PHAsset, completion: @escaping getUrlCompletionHandler) {
    
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
    
    manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avasset, audio, info) in
      
      if let avassetURL = avasset as? AVURLAsset {
        
        guard let video = try? Data(contentsOf: avassetURL.url) else {
          return
        }
        
        self.getUrlFor(asset: asset) { (url, completed) in
          
          if completed {
            
            let mediaObject = ["object": data!,
                               "videoObject": video,
                               "imageSource": self.imageSourceCamera,
                               "phAsset": asset,
                               "filename": filename,
                               "fileURL" : url] as [String: AnyObject]
            
            self.inputContainerView?.attachedMedia.append(MediaObject(dictionary: mediaObject))
            
            if self.inputContainerView!.attachedMedia.count - 1 >= 0 {
              self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.attachedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
            } else {
              self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: 0 , section: 0) ], mediaObject: mediaObject)
            }
          }
        }
      }
    })
  }
  
  fileprivate func handleOlderAssetSelection(imageData: Data, videoData: Data?, imageSource: String, asset: PHAsset, filename: String) {
    
    getUrlFor(asset: asset) { (url, completed) in
      if completed {
        
        var mediaObject = [String: AnyObject]()
        
        if videoData == nil {
          
          mediaObject = ["object": imageData,
                  
                         "imageSource": imageSource,
                         "phAsset": asset,
                         "filename": filename,
                         "fileURL" : url] as [String: AnyObject]
        } else {
          
          mediaObject = ["object": imageData,
                         "videoObject": videoData! ,
                        
                         "imageSource": imageSource,
                         "phAsset": asset,
                         "filename": filename,
                         "fileURL" : url] as [String: AnyObject]
        }
        
        if let _ = self.inputContainerView?.attachedMedia.index(where: { (item) -> Bool in
          return item.filename == filename
        }) {
          return
        }
        
        self.inputContainerView?.attachedMedia.append(MediaObject(dictionary: mediaObject))
        
        if self.inputContainerView!.attachedMedia.count - 1 >= 0 {
          self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: self.inputContainerView!.attachedMedia.count - 1 , section: 0)], mediaObject: mediaObject)
          
        } else {
          
          self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: 0 , section: 0)], mediaObject: mediaObject)
        }
      }
    }
  }
  
  func controller(_ controller: ImagePickerTrayController, didSelectAsset asset: PHAsset, at indexPath: IndexPath?) {
    
    let image = uiImageFromAsset(phAsset: asset)
    
    let filename = asset.originalFilename!
    
    let imageData = compressImage(image: image!)
    
    if asset.mediaType == .image {
      guard let unwrappedIndexPath = indexPath else {
        self.handleOlderAssetSelection(imageData: imageData, videoData: nil, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
        return
      }
      self.handleAssetSelection(imageData: imageData,  videoData: nil, indexPath: unwrappedIndexPath, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
      
    } else if asset.mediaType == .video {
      
      let manager = PHImageManager.default()
      
      manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avasset, audio, info) in
        
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
                         "fileURL" : url] as [String: AnyObject]
        } else {
          
          mediaObject = ["object": imageData,
                         "videoObject": videoData! ,
                         "indexPath": indexPath,
                         "imageSource": imageSource,
                         "phAsset": asset,
                         "filename": filename,
                         "fileURL" : url] as [String: AnyObject]
        }
        
        if let _ = self.inputContainerView?.attachedMedia.index(where: { (item) -> Bool in
          return item.filename == filename
        }) {
          return
        }
        
        self.inputContainerView?.attachedMedia.append(MediaObject(dictionary: mediaObject))
        
        if self.inputContainerView!.attachedMedia.count - 1 >= 0 {
          self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: self.inputContainerView!.attachedMedia.count - 1 , section: 0)], mediaObject: mediaObject)
          
        } else {
          
          self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: 0 , section: 0)], mediaObject: mediaObject)
        }
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
        
        print("after  ", fileURL)
        
        let mediaObject = ["object": data!,
                           "imageSource": self.imageSourceCamera,
                           "phAsset": asset,
                           "filename": filename,
                           "fileURL" : fileURL] as [String: AnyObject]
        self.inputContainerView?.attachedMedia.append(MediaObject(dictionary: mediaObject))
        
        if self.inputContainerView!.attachedMedia.count - 1 >= 0 {
          self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.attachedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
        } else {
          self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: 0 , section: 0) ], mediaObject: mediaObject)
        }
      }
    }
  }
  
  
  func controller(_ controller: ImagePickerTrayController, didTakeImage image: UIImage) {
    
    let data = compressImage(image: image)
    let status = libraryAccessChecking()
    
    let mediaObject = ["object": data as AnyObject,
                       "imageSource": imageSourceCamera] as [String: AnyObject]
    
    self.inputContainerView?.attachedMedia.append(MediaObject(dictionary: mediaObject))
    
    if inputContainerView!.attachedMedia.count - 1 >= 0 {
      
      if status {
        self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.attachedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
      } else {
        DispatchQueue.main.async {
          self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.attachedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
        }
      }
    } else {
      self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: 0 , section: 0)], mediaObject: mediaObject )
    }
  }
  
  
  
  func insertItemsToCollectionViewAnimated(at indexPath: [IndexPath], mediaObject: [String: AnyObject]) {
    
    inputContainerView?.expandCollection()
    self.inputContainerView?.attachCollectionView.performBatchUpdates ({
      self.inputContainerView?.attachCollectionView.insertItems(at: indexPath)
    }, completion: nil)
    
    self.inputContainerView?.attachCollectionView.scrollToItem(at: IndexPath(item: self.inputContainerView!.attachedMedia.count - 1 , section: 0), at: .right, animated: true)
  }
  
  func deleteItemsToCollectionViewAnimated(at indexPath: IndexPath, index: Int) {
    if self.inputContainerView?.attachCollectionView.cellForItem(at: indexPath) == nil || self.inputContainerView?.attachedMedia[index] == nil {
       print("returning2")
      self.inputContainerView?.attachedMedia.remove(at: index)
      self.inputContainerView?.attachCollectionView.reloadData()
      return
    }
 
    self.inputContainerView?.attachedMedia.remove(at: index)
    self.inputContainerView?.attachCollectionView.deleteItems(at: [indexPath])
    self.inputContainerView?.resetChatInputConntainerViewSettings()
  }
  

  func controller(_ controller: ImagePickerTrayController, didDeselectAsset asset: PHAsset, at indexPath: IndexPath) {
    
    guard let index = self.inputContainerView?.attachedMedia.index(where: { (item) -> Bool in
      return item.filename == asset.originalFilename
    }) else {
      print("returning1")
      return
    }
    
    deleteItemsToCollectionViewAnimated(at: IndexPath(item: index, section: 0), index: index)
  }
}
