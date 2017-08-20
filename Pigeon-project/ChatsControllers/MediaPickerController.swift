//
//  MediaPickerController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/19/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos


class MediaPickerController: UIViewController {
  
  let container = UIView()
  
  let customMediaPickerView = ImagePickerTrayController()
  
  weak var inputContainerView: ChatInputContainerView?
  
  var selectedImages = [PHAsset]()
  
  
  public init() {
    super.init(nibName: nil, bundle: nil)
    
    configureContainerView()
    
    configureCustomMediaPickerView()
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
      })
    
    customMediaPickerView.add(action: .libraryAction { _ in
      print("Show Library")
      })
  }
}


extension MediaPickerController: ImagePickerTrayControllerDelegate {
  
  
  func controller(_ controller: ImagePickerTrayController, didSelectAsset asset: PHAsset) {
    
    selectedImages.append(asset)
  
    self.inputContainerView?.inputTextView.textContainerInset = UIEdgeInsets(top: 110, left: 8, bottom: 8, right: 30)
    
    self.inputContainerView?.attachedImages.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
    
    inputContainerView?.separator.isHidden = false
    
    inputContainerView?.placeholderLabel.text = "Add comment or Send"
    
    inputContainerView?.sendButton.isEnabled = true
    
    inputContainerView?.invalidateIntrinsicContentSize()
  }
  
  
  func controller(_ controller: ImagePickerTrayController, didTakeImage image: UIImage) {
  }
  
  
  func controller(_ controller: ImagePickerTrayController, didDeselectAsset asset: PHAsset) {
    
    selectedImages.removeLast()
    
    if selectedImages.count == 0 {
      
      inputContainerView?.inputTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 8, right: 30)
      
      inputContainerView?.attachedImages.frame = CGRect(x: 0, y: 0, width: 300, height: 0)
      
      inputContainerView?.separator.isHidden = true
      
      inputContainerView?.placeholderLabel.text = "Message"
      
      if inputContainerView?.inputTextView.text == "" {
        
        inputContainerView?.sendButton.isEnabled = false
      }
     
      
      let textBeforeUpdate = inputContainerView!.inputTextView.text
      
      inputContainerView!.inputTextView.text = " "
      
      inputContainerView?.invalidateIntrinsicContentSize()
      
      inputContainerView!.inputTextView.text = textBeforeUpdate
    }
  }
  
}
