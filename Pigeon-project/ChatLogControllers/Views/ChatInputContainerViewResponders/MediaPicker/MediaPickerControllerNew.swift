//
//  MediaPickerControllerNew.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos


public let imageSourcePhotoLibrary = "imageSourcePhotoLibrary"
public let imageSourceCamera = "imageSourceCamera"


class MediaPickerControllerNew: ImagePickerTrayController {
  
  var imagePicker: UIImagePickerController! = UIImagePickerController()
  weak var inputContainerView: ChatInputContainerView?


  override func loadView() {
    super.loadView()
    
    collectionView.backgroundColor = ThemeManager.currentTheme().mediaPickerControllerBackgroundColor
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
  
  deinit {
    print("\nNEW TRAY DE INIT\n")
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
    
    manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avasset, audio, info) in
      
      if let avassetURL = avasset as? AVURLAsset {
        
        guard let video = try? Data(contentsOf: avassetURL.url) else {
          return
        }
        
        self.getUrlFor(asset: asset) { (url, completed) in
          
          if completed {
            
            let mediaObject = ["object": data!,
                               "videoObject": video,
                               "imageSource": imageSourceCamera,
                               "phAsset": asset,
                               "filename": filename,
                               "fileURL" : url] as [String: AnyObject]
            
            self.inputContainerView?.selectedMedia.append(MediaObject(dictionary: mediaObject))
            
            if self.inputContainerView!.selectedMedia.count - 1 >= 0 {
              self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
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
        
				if let _ = self.inputContainerView?.selectedMedia.firstIndex(where: { (item) -> Bool in
          return item.filename == filename
        }) {
          return
        }
        
        self.inputContainerView?.selectedMedia.append(MediaObject(dictionary: mediaObject))
        
        if self.inputContainerView!.selectedMedia.count - 1 >= 0 {
          self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0)], mediaObject: mediaObject)
          
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
            self.handleOlderAssetSelection(imageData: imageData, videoData: video, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
            return
          }
          
          self.handleAssetSelection(imageData: imageData, videoData: video, indexPath: unwrappedIndexPath, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
          
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
                    self.handleOlderAssetSelection(imageData: imageData, videoData: video, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
                    return
                  }
                  
                  self.handleAssetSelection(imageData: imageData, videoData: video, indexPath: unwrappedIndexPath, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
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
        
				if let _ = self.inputContainerView?.selectedMedia.firstIndex(where: { (item) -> Bool in
          return item.filename == filename
        }) {
          return
        }
        
        self.inputContainerView?.selectedMedia.append(MediaObject(dictionary: mediaObject))
        
        if self.inputContainerView!.selectedMedia.count - 1 >= 0 {
          self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0)], mediaObject: mediaObject)
          
        } else {
          
          self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: 0 , section: 0)], mediaObject: mediaObject)
        }
      }
    }
  }
  
  func expandCollection() {
    inputContainerView?.separator.isHidden = false
    inputContainerView?.sendButton.isEnabled = true
    inputContainerView?.placeholderLabel.text = "Add comment or Send"
    inputContainerView?.attachedImages.frame = CGRect(x: 0, y: 0, width: inputContainerView!.inputTextView.frame.width, height: 165)
    inputContainerView?.inputTextView.textContainerInset = InputContainerViewConstants.containerInsetsWithAttachedImages
    
    let maxTextViewHeightRelativeToOrientation: CGFloat! = getInputTextViewMaxHeight()
    if inputContainerView!.inputTextView.contentSize.height <= maxTextViewHeightRelativeToOrientation {
      inputContainerView?.invalidateIntrinsicContentSize()
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
                           "imageSource": imageSourceCamera,
                           "phAsset": asset,
                           "filename": filename,
                           "fileURL" : fileURL] as [String: AnyObject]
        self.inputContainerView?.selectedMedia.append(MediaObject(dictionary: mediaObject))
        
        if self.inputContainerView!.selectedMedia.count - 1 >= 0 {
          self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
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
    
    self.inputContainerView?.selectedMedia.append(MediaObject(dictionary: mediaObject))
    
    if inputContainerView!.selectedMedia.count - 1 >= 0 {
      
      if status {
        self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
      } else {
        DispatchQueue.main.async {
          self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
        }
      }
    } else {
      self.insertItemsToCollectionViewAnimated(at: [IndexPath(item: 0 , section: 0)], mediaObject: mediaObject )
    }
  }
  
  
  
  func insertItemsToCollectionViewAnimated(at indexPath: [IndexPath], mediaObject: [String: AnyObject]) {
    
    self.expandCollection()
    self.inputContainerView?.attachedImages.performBatchUpdates ({
      self.inputContainerView?.attachedImages.insertItems(at: indexPath)
    }, completion: nil)
    
    self.inputContainerView?.attachedImages.scrollToItem(at: IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0), at: .right, animated: true)
  }
  
  func deleteItemsToCollectionViewAnimated(at indexPath: IndexPath, index: Int) {
    if self.inputContainerView?.attachedImages.cellForItem(at: indexPath) == nil || self.inputContainerView?.selectedMedia[index] == nil {
       print("returning2")
      self.inputContainerView?.selectedMedia.remove(at: index)
      self.inputContainerView?.attachedImages.reloadData()
      return
    }
 
    self.inputContainerView?.selectedMedia.remove(at: index)
    self.inputContainerView?.attachedImages.deleteItems(at: [indexPath])
    self.inputContainerView?.resetChatInputConntainerViewSettings()
  }
  

  func controller(_ controller: ImagePickerTrayController, didDeselectAsset asset: PHAsset, at indexPath: IndexPath) {
    
		guard let index = self.inputContainerView?.selectedMedia.firstIndex(where: { (item) -> Bool in
      return item.filename == asset.originalFilename
    }) else {
      print("returning1")
      return
    }
    
    deleteItemsToCollectionViewAnimated(at: IndexPath(item: index, section: 0), index: index)
  }
}
