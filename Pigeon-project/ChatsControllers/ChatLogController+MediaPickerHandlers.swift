//
//  ChatLogController+MediaPickerHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/16/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


extension ChatLogController {
  
  func toggleTextView () {
    
    inputContainerView.inputTextView.inputView = nil
    
    inputContainerView.inputTextView.reloadInputViews()
    
    inputContainerView.attachButton.isSelected = false
  }
  
  
  func togglePhoto () {
    
    inputContainerView.attachButton.isSelected = !inputContainerView.attachButton.isSelected
    
    if inputContainerView.attachButton.isSelected {
      
      mediaPickerController.inputContainerView = inputContainerView
      
      inputContainerView.inputTextView.inputView = mediaPickerController.view
      
      inputContainerView.inputTextView.reloadInputViews()
      
      inputContainerView.inputTextView.becomeFirstResponder()
      
      inputContainerView.inputTextView.addGestureRecognizer(inputTextViewTapGestureRecognizer)
    
    } else {
     
      inputContainerView.inputTextView.inputView = nil
      
      inputContainerView.inputTextView.reloadInputViews()

      inputContainerView.inputTextView.removeGestureRecognizer(inputTextViewTapGestureRecognizer)
    }
  }
  
  
  
//  func handleUploadTap() {
//
//    let imagePickerController = ImagePickerTrayController()
//
//   // imagePickerController.allowsEditing = true
//    imagePickerController.delegate = self
//   // imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
//    
//    
//    imagePickerController.add(action: .cameraAction { _ in
//      print("Show Camera")
//      })
//    imagePickerController.add(action: .libraryAction { _ in
//      print("Show Library")
//      })
//    imagePickerController.show(<#T##vc: UIViewController##UIViewController#>, sender: <#T##Any?#>) show(in: self)
//   // imagePickerTrayController = controller
//
//    
//    present(imagePickerController, animated: true, completion: nil)
//  }
//  
//  
//  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//    
//    if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
//      //we selected a video
//     // handleVideoSelectedForUrl(videoUrl)
//    } else {
//      //we selected an image
//      handleImageSelectedForInfo(info as [String : AnyObject])
//    }
//    
//    dismiss(animated: true, completion: nil)
//  }
//  
//  
////  fileprivate func handleVideoSelectedForUrl(_ url: URL) {
////    let filename = UUID().uuidString + ".mov"
////    let uploadTask = Storage.storage().reference().child("message_movies").child(filename).putFile(from: url, metadata: nil, completion: { (metadata, error) in
////      
////      if error != nil {
////        print("Failed upload of video:", error as Any)
////        return
////      }
////      
////      if let videoUrl = metadata?.downloadURL()?.absoluteString {
////        if let thumbnailImage = self.thumbnailImageForFileUrl(url) {
////          
////          self.uploadToFirebaseStorageUsingImage(thumbnailImage, completion: { (imageUrl) in
////            let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight": thumbnailImage.size.height as AnyObject, "videoUrl": videoUrl as AnyObject]
////            self.sendMessageWithProperties(properties)
////            
////          })
////        }
////      }
////    })
////    
////    uploadTask.observe(.progress) { (snapshot) in
////      if let completedUnitCount = snapshot.progress?.completedUnitCount {
////        self.navigationItem.title = String(completedUnitCount)
////      }
////    }
////    
////    uploadTask.observe(.success) { (snapshot) in
////      self.navigationItem.title = self.user?.name
////    }
////  }
//  
//  
////  fileprivate func thumbnailImageForFileUrl(_ fileUrl: URL) -> UIImage? {
////    let asset = AVAsset(url: fileUrl)
////    let imageGenerator = AVAssetImageGenerator(asset: asset)
////    
////    do {
////      
////      let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
////      return UIImage(cgImage: thumbnailCGImage)
////      
////    } catch let err {
////      print(err)
////    }
////    
////    return nil
////  }
//  
//  
//  fileprivate func handleImageSelectedForInfo(_ info: [String: AnyObject]) {
//    var selectedImageFromPicker: UIImage?
//    
//    if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
//      selectedImageFromPicker = editedImage
//    } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
//      
//      selectedImageFromPicker = originalImage
//    }
//    
//    if let selectedImage = selectedImageFromPicker {
//      //here handle sending
//      
////      uploadToFirebaseStorageUsingImage(selectedImage, completion: { (imageUrl) in
////        
////        self.sendMessageWithImageUrl(imageUrl, image: selectedImage)
////      })
//    }
//  }
//  
//  
////  fileprivate func uploadToFirebaseStorageUsingImage(_ image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
////    let imageName = UUID().uuidString
////    let ref = Storage.storage().reference().child("message_images").child(imageName)
////    
////    if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
////      ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
////        
////        if error != nil {
////          print("Failed to upload image:", error as Any)
////          return
////        }
////        
////        if let imageUrl = metadata?.downloadURL()?.absoluteString {
////          completion(imageUrl)
////        }
////        
////      })
////    }
////  }
//  
//  
//  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//    dismiss(animated: true, completion: nil)
//  }
  

}
