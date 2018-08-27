//
//  ImagePickerAction.swift
//  ImagePickerTrayController
//
//  Created by Laurin Brandner on 22.11.16.
//  Copyright © 2016 Laurin Brandner. All rights reserved.
//

import UIKit

public struct ImagePickerAction {
  
    public typealias Callback = (ImagePickerAction) -> ()
    
    public var title: String
    public var image: UIImage
    public var callback: Callback
    
    public static func cameraAction(with callback: @escaping Callback) -> ImagePickerAction {
        let image = UIImage(bundledName: "ImagePickerAction-Camera")!
        
        return ImagePickerAction(title: NSLocalizedString("Camera", comment: "Image Picker Camera Action"), image: image, callback: callback)
    }
    
    public static func libraryAction(with callback: @escaping Callback) -> ImagePickerAction {
        let image = UIImage(bundledName: "ImagePickerAction-Library")!
        
        return ImagePickerAction(title: NSLocalizedString("Photos", comment: "Image Picker Photo Library Action"), image: image, callback: callback)
    }
    
    func call() {
      callback(self)
    }
    
}
