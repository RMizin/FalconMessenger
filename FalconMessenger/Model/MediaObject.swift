//
//  MediaObject.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/21/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Photos

final class MediaObject: NSObject {
  var object: Data?
  var videoObject: Data?
  var audioObject: Data?
  var indexPath: IndexPath?
  var imageSource: String?
  var phAsset: PHAsset?
  var filename: String?
  var fileURL: String?
	var localVideoURL: String?
	var localVideoIdentifier: String?
  
  init(dictionary: [String: AnyObject]) {
    super.init()

    object = dictionary["object"] as? Data
    videoObject = dictionary["videoObject"] as? Data
    audioObject = dictionary["audioObject"] as? Data
    indexPath = dictionary["indexPath"] as? IndexPath
    imageSource = dictionary["imageSource"] as? String
    phAsset = dictionary["phAsset"] as? PHAsset
    filename = dictionary["filename"] as? String
    fileURL = dictionary["fileURL"] as? String
		localVideoURL = dictionary["localVideoUrl"] as? String
		localVideoIdentifier = dictionary["localVideoIdentifier"] as? String
  }
}
