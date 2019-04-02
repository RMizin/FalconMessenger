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

import UIKit
import SDWebImage
/*
 * This is marked as @objc because of Swift bug http://stackoverflow.com/questions/30100787/fatal-error-array-cannot-be-bridged-from-objective-c-why-are-you-even-trying when passing for example [INSPhoto] array
 * to INSPhotosViewController
 */
@objc public protocol INSPhotoViewable: class {
    var image: UIImage? { get }
    var thumbnailImage: UIImage? { get }
    var messageUID: String? { get }
    @objc optional var isDeletable: Bool { get }

		var videoURL: String? { get }
		var localVideoURL: String? { get }
		var imageURL: URL? { get }
    
    func loadImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ())
    func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ())
    
    var attributedTitle: NSAttributedString? { get }
}

@objc open class INSPhoto: NSObject, INSPhotoViewable {

	@objc public var videoURL: String?
	@objc public var localVideoURL: String?

	@objc open var image: UIImage?
	@objc open var thumbnailImage: UIImage?
	@objc open var messageUID: String?
	@objc open var isDeletable: Bool

//	  @objc open var videoURL: String?
//	  @objc open var localVideoURL: String?


	public var imageURL: URL?
	var thumbnailImageURL: URL?
 // var messageUID: String?

    @objc open var attributedTitle: NSAttributedString?

    
    public init(image: UIImage?, thumbnailImage: UIImage?, messageUID: String?, videoURL: String? = nil, localVideoURL: String? = nil) {
        self.image = image
        self.thumbnailImage = thumbnailImage
        self.messageUID = messageUID
        self.isDeletable = false
				self.videoURL = videoURL
				self.localVideoURL = localVideoURL
    }
    
	public init(imageURL: URL?, thumbnailImageURL: URL?, messageUID: String?, videoURL: String? = nil, localVideoURL: String? = nil) {
        self.imageURL = imageURL
        self.thumbnailImageURL = thumbnailImageURL
        self.messageUID = messageUID
        self.isDeletable = false
				self.videoURL = videoURL
				self.localVideoURL = localVideoURL
    }
    
    public init (imageURL: URL?, thumbnailImage: UIImage?, messageUID: String?, videoURL: String? = nil, localVideoURL: String? = nil)  {
        self.imageURL = imageURL
        self.thumbnailImage = thumbnailImage
        self.messageUID = messageUID
        self.isDeletable = false
				self.videoURL = videoURL
				self.localVideoURL = localVideoURL
    }
    
    @objc open func loadImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        if let image = image {
            completion(image, nil)
            return
        }

			SDWebImageManager.shared.loadImage(with: imageURL,
																				 options: [.scaleDownLargeImages, .continueInBackground],
																				 progress: nil) { (image, _, error, _, _, _) in
				completion(image, error)
			}
    }
	
    @objc open func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        if let thumbnailImage = thumbnailImage {
            completion(thumbnailImage, nil)
            return
        }

			SDWebImageManager.shared.loadImage(with: thumbnailImageURL,
																				 options: [.scaleDownLargeImages, .continueInBackground],
																				 progress: nil) { (image, _, error, _, _, _) in
				completion(image, error)
			}
    }
}

public func ==<T: INSPhoto>(lhs: T, rhs: T) -> Bool {
    return lhs === rhs
}
