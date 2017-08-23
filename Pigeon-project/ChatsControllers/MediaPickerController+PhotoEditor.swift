//
//  MediaPickerController+PhotoEditor.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/23/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


extension ChatLogController: PhotoEditorDelegate {
  
  func doneEditing(image: UIImage, indexPath: IndexPath) {
    inputContainerView.selectedMedia[indexPath.row].setValue(UIImageJPEGRepresentation(image, 1), forKey: "object")
    inputContainerView.attachedImages.reloadItems(at: [indexPath])
  }
  
  func canceledEditing() {
    print("Canceled")
  }
  

  func presentPhotoEditor(forImageAt indexPath: IndexPath) {
    let photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))
    
    photoEditor.photoEditorDelegate = self
    
    photoEditor.image = inputContainerView.selectedMedia[indexPath.row].object?.asUIImage
    
    photoEditor.hiddenControls = [.text]
    
    photoEditor.modalTransitionStyle = .coverVertical
    
    photoEditor.sentIndexPath = indexPath
    
    inputContainerView.inputTextView.resignFirstResponder()
    
    present(photoEditor, animated: true, completion: nil)
  }
}





