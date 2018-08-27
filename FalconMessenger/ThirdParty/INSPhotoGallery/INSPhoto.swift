//
//  INSPhoto.swift
//  INSPhotoViewer
//
//  Created by Michal Zaborowski on 28.02.2016.
//  Copyright © 2016 Inspace Labs Sp z o. o. Spółka Komandytowa. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this library except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation
import UIKit

/*
 * This is marked as @objc because of Swift bug http://stackoverflow.com/questions/30100787/fatal-error-array-cannot-be-bridged-from-objective-c-why-are-you-even-trying when passing for example [INSPhoto] array
 * to INSPhotosViewController
 */
@objc public protocol INSPhotoViewable: class {
    var image: UIImage? { get }
    var thumbnailImage: UIImage? { get }
    var messageUID: String? { get }
    @objc optional var isDeletable: Bool { get }
    
    func loadImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ())
    func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ())
    
    var attributedTitle: NSAttributedString? { get }
}

@objc open class INSPhoto: NSObject, INSPhotoViewable {
    @objc open var image: UIImage?
    @objc open var thumbnailImage: UIImage?
    @objc open var messageUID: String?
    @objc open var isDeletable: Bool
  
    
    var imageURL: URL?
    var thumbnailImageURL: URL?
   // var messageUID: String?
    
    @objc open var attributedTitle: NSAttributedString?

    
    public init(image: UIImage?, thumbnailImage: UIImage?, messageUID: String?) {
        self.image = image
        self.thumbnailImage = thumbnailImage
        self.messageUID = messageUID
        self.isDeletable = false
    }
    
    public init(imageURL: URL?, thumbnailImageURL: URL?, messageUID: String?) {
        self.imageURL = imageURL
        self.thumbnailImageURL = thumbnailImageURL
        self.messageUID = messageUID
        self.isDeletable = false
    }
    
    public init (imageURL: URL?, thumbnailImage: UIImage?, messageUID: String?)  {
        self.imageURL = imageURL
        self.thumbnailImage = thumbnailImage
        self.messageUID = messageUID
        self.isDeletable = false
    }
    
    @objc open func loadImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        if let image = image {
            completion(image, nil)
            return
        }
        loadImageWithURL(imageURL, completion: completion)
    }
    @objc open func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        if let thumbnailImage = thumbnailImage {
            completion(thumbnailImage, nil)
            return
        }
        loadImageWithURL(thumbnailImageURL, completion: completion)
    }
    
    open func loadImageWithURL(_ url: URL?, completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        let session = URLSession(configuration: URLSessionConfiguration.default)

      
        if let imageURL = url {
            session.dataTask(with: imageURL, completionHandler: { (response, data, error) in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        completion(nil, error)
                    } else if let response = response, let image = UIImage(data: response) {
                        completion(image, nil)
                    } else {
                        completion(nil, NSError(domain: "INSPhotoDomain", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Couldn't load image"]))
                    }
                    session.finishTasksAndInvalidate()
                })
            }).resume()
        } else {
            completion(nil, NSError(domain: "INSPhotoDomain", code: -2, userInfo: [ NSLocalizedDescriptionKey: "Image URL not found."]))
        }
    }
}

public func ==<T: INSPhoto>(lhs: T, rhs: T) -> Bool {
    return lhs === rhs
}
