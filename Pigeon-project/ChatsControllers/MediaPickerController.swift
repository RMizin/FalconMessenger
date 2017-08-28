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
  
  let container = UIView()
  
  let customMediaPickerView = ImagePickerTrayController()
  
  weak var inputContainerView: ChatInputContainerView?
  
  let imagePicker = UIImagePickerController()

  
  public init() {
    super.init(nibName: nil, bundle: nil)
    
    configureContainerView()
    
    configureCustomMediaPickerView()
    
    imagePicker.delegate = self
    
    imagePicker.allowsEditing = false
    
    imagePicker.mediaTypes = ["public.image", "public.movie"]
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  fileprivate func configureContainerView() {
    
    view.addSubview(container)
    container.translatesAutoresizingMaskIntoConstraints = false
    container.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    container.heightAnchor.constraint(equalToConstant: 216).isActive = true
    container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
  }
  
  
  fileprivate func configureCustomMediaPickerView() {
    
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
      print("Show Camera")
      self.openCamera()
      })
    
    customMediaPickerView.add(action: .libraryAction { _ in
      print("Show Library")
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
          DispatchQueue.main.async {
            
            self.inputContainerView?.attachedImages.insertItems(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ])
          }
        } else {
          DispatchQueue.main.async {
            self.inputContainerView?.attachedImages.insertItems(at: [ IndexPath(item: 0 , section: 0)])
          }
        }
        
        DispatchQueue.main.async {
          self.expandCollection()
        }
      }
    }
  }
  
  
  func controller(_ controller: ImagePickerTrayController, didSelectAsset asset: PHAsset, at indexPath: IndexPath) {

    let image = uiImageFromAsset(phAsset: asset)
    
    let filename = asset.originalFilename!
    
    let data = compressImage(image: image!)
  
    var fileURL = String()
    
    getUrlFor(asset: asset) { (url, completed) in
      if completed {
        fileURL = url
        
        print("after  ", fileURL)
        
        let mediaObject = ["object": data,
                           "indexPath": indexPath,
                           "imageSource": imageSourcePhotoLibrary,
                           "phAsset": asset,
                           "filename": filename,
                           "fileURL" : fileURL] as [String: AnyObject]
        
        self.inputContainerView?.selectedMedia.append(MediaObject(dictionary: mediaObject))
        
        if self.inputContainerView!.selectedMedia.count - 1 >= 0 {
          
          self.inputContainerView?.attachedImages.insertItems(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ])
          
        } else {
          
          self.inputContainerView?.attachedImages.insertItems(at: [ IndexPath(item: 0 , section: 0)])
        }
        
        self.expandCollection()
      }
    }
  }
  
  
  func expandCollection() {
  
      inputContainerView?.attachedImages.scrollToItem(at: IndexPath(item: inputContainerView!.selectedMedia.count - 1 , section: 0), at: .right, animated: true)
      
      inputContainerView?.inputTextView.textContainerInset = UIEdgeInsets(top: 175, left: 8, bottom: 8, right: 30)
      
      inputContainerView?.attachedImages.frame = CGRect(x: 0, y: 0, width: inputContainerView!.inputTextView.frame.width, height: 165)
      
      inputContainerView?.separator.isHidden = false
      
      inputContainerView?.placeholderLabel.text = "Add comment or Send"
      
      inputContainerView?.sendButton.isEnabled = true
      
      inputContainerView?.invalidateIntrinsicContentSize()   
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
          DispatchQueue.main.async {
            
            self.inputContainerView?.attachedImages.insertItems(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ])
          }
        } else {
          DispatchQueue.main.async {
            self.inputContainerView?.attachedImages.insertItems(at: [ IndexPath(item: 0 , section: 0)])
          }
        }
        DispatchQueue.main.async {
          self.expandCollection()
        }
      }
    }
  }
  
  
  func controller(_ controller: ImagePickerTrayController, didTakeImage image: UIImage) {
    
    let data = compressImage(image: image)
    
    let mediaObject = ["object": data as AnyObject,
                       "imageSource": imageSourceCamera] as [String: AnyObject]
    
    inputContainerView?.selectedMedia.append(MediaObject(dictionary: mediaObject))
    
    if inputContainerView!.selectedMedia.count - 1 >= 0 {
      
       self.inputContainerView?.attachedImages.insertItems(at: [ IndexPath(item: self.inputContainerView!.selectedMedia.count - 1 , section: 0) ])
      
    } else {
      
      self.inputContainerView?.attachedImages.insertItems(at: [ IndexPath(item: 0 , section: 0) ])
    }
    
    expandCollection()
  }
 
  
  func controller(_ controller: ImagePickerTrayController, didDeselectAsset asset: PHAsset, at indexPath: IndexPath) {
    
    if self.inputContainerView!.selectedMedia.count - 1 >= 0 {
    
        for index in 0...self.inputContainerView!.selectedMedia.count - 1 {
          
          if self.inputContainerView!.selectedMedia[index].filename == asset.originalFilename {
            
            print("equals")
            self.inputContainerView?.selectedMedia.remove(at: index)
            self.inputContainerView?.attachedImages.deleteItems(at: [IndexPath(item: index, section: 0)])
            break
          }
        }
    } else {
      self.inputContainerView?.selectedMedia.remove(at: 0)
      self.inputContainerView?.attachedImages.deleteItems(at: [IndexPath(item: 0, section: 0)])
    }
    
    inputContainerView?.resetChatInputConntainerViewSettings()
  }
}

