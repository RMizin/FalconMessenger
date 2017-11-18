//
//  MediaPickerController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/19/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos


public let imageSourcePhotoLibrary = "imageSourcePhotoLibrary"

public let imageSourceCamera = "imageSourceCamera"


class MediaPickerController: UIViewController {
  
  var container:UIView! = nil
  
  var customMediaPickerView: ImagePickerTrayController! = nil
  
  var imagePicker: UIImagePickerController! = UIImagePickerController()
  
  weak var inputContainerView: ChatInputContainerView?
  
  
  public init() {
    super.init(nibName: nil, bundle: nil)
    print("MEDIA PICKER CONTROLLER INIT")
    
    if customMediaPickerView == nil {
      customMediaPickerView = ImagePickerTrayController()
    }
    
    configureCustomMediaPickerView()
    
    imagePicker.delegate = self
    
    imagePicker.allowsEditing = false
    
    imagePicker.mediaTypes = ["public.image", "public.movie"]
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  deinit {
    print("\nMEDIA PICKER CONTROLLER DE INIT\n")
    imagePicker = nil
  }
  
  
  fileprivate func configureCustomMediaPickerView() {
    
    if container == nil {
      container = UIView()
    }
    
    view.addSubview(container)
    container.translatesAutoresizingMaskIntoConstraints = false
    container.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    container.heightAnchor.constraint(equalToConstant: 216).isActive = true
    container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    
    
    addChildViewController(customMediaPickerView)
    container.addSubview(customMediaPickerView.view)
    customMediaPickerView.didMove(toParentViewController: self)
    customMediaPickerView.view.translatesAutoresizingMaskIntoConstraints = false
    customMediaPickerView.view.topAnchor.constraint(equalTo: container.topAnchor, constant: 0).isActive = true
    customMediaPickerView.view.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
    customMediaPickerView.view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0).isActive = true
    customMediaPickerView.view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0).isActive = true
    
    customMediaPickerView.delegate = self
    
    customMediaPickerView.add(action: .cameraAction { _ in
      self.openCamera()
      })
    
    customMediaPickerView.add(action: .libraryAction { _ in
      self.openPhotoLibrary()
      })
  }
}


extension MediaPickerController: ImagePickerTrayControllerDelegate {
  
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
  
  
  func controller(_ controller: ImagePickerTrayController, didSelectAsset asset: PHAsset, at indexPath: IndexPath) {
    
    let image = uiImageFromAsset(phAsset: asset)
    
    let filename = asset.originalFilename!
    
    let imageData = compressImage(image: image!)
    
    if asset.mediaType == .image {
      
      self.handleAssetSelection(imageData: imageData,  videoData: nil, indexPath: indexPath, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
      
    } else if asset.mediaType == .video {
      
      let manager = PHImageManager.default()
      
      manager.requestAVAsset(forVideo: asset, options: nil, resultHandler: { (avasset, audio, info) in
        
        if let avassetURL = avasset as? AVURLAsset {
          
          guard let video = try? Data(contentsOf: avassetURL.url) else {
            return
          }
          
          self.handleAssetSelection(imageData: imageData, videoData: video, indexPath: indexPath, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
          
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
                  
                  self.handleAssetSelection(imageData: imageData, videoData: video, indexPath: indexPath, imageSource: imageSourcePhotoLibrary, asset: asset, filename: filename)
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
        
        if let _ = self.inputContainerView?.selectedMedia.index(where: { (item) -> Bool in
          return item.filename == filename
        }) {
          return
        }
        
        self.inputContainerView?.selectedMedia.append(MediaObject(dictionary: mediaObject))
        
        if self.inputContainerView!.selectedMedia.count - 1 >= 0 {
          self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ], mediaObject: mediaObject)
          
        } else {
          
          self.insertItemsToCollectionViewAnimated(at: [ IndexPath(item: 0 , section: 0) ], mediaObject: mediaObject)
        }
      }
    }
  }
  
  
  func expandCollection() {
    
    inputContainerView?.inputTextView.textContainerInset = UIEdgeInsets(top: 175, left: 8, bottom: 8, right: 30)

    inputContainerView?.attachedImages.frame = CGRect(x: 0, y: 0, width: inputContainerView!.inputTextView.frame.width, height: 165)
    
    inputContainerView?.invalidateIntrinsicContentSize()
    
    inputContainerView?.separator.isHidden = false
    
    inputContainerView?.sendButton.isEnabled = true
    
    inputContainerView?.placeholderLabel.text = "Add comment or Send"
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
  
  func deleteItemsToCollectionViewAnimated(at indexPath: [IndexPath]?, index: Int?) {
    if self.inputContainerView?.attachedImages.cellForItem(at: indexPath![0]) == nil || self.inputContainerView?.selectedMedia[index!] == nil {
      return
    }
    self.inputContainerView?.selectedMedia.remove(at: index!)
    self.inputContainerView?.attachedImages.deleteItems(at: indexPath!)
    self.inputContainerView?.resetChatInputConntainerViewSettings()
  }
  
  func controller(_ controller: ImagePickerTrayController, didDeselectAsset asset: PHAsset, at indexPath: IndexPath) {
    
    guard let index = self.inputContainerView?.selectedMedia.index(where: { (item) -> Bool in
      return item.filename == asset.originalFilename
    }) else {
      return
    }
    
    deleteItemsToCollectionViewAnimated(at: [IndexPath(item: index, section: 0)], index: index)
  }
}
