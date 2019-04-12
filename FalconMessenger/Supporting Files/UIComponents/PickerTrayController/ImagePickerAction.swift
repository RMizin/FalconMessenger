//
//  ImagePickerAction.swift
//  ImagePickerTrayController
//
//  Created by Laurin Brandner on 22.11.16.
//  Copyright © 2016 Laurin Brandner. All rights reserved.
//

import UIKit

struct ImagePickerAction {

	typealias Callback = (ImagePickerAction) -> ()

	var title: String
	var image: UIImage
	var callback: Callback

	static func cameraAction(with callback: @escaping Callback) -> ImagePickerAction {
		let image = UIImage(named: "ImagePickerAction-Camera")!

		return ImagePickerAction(title: NSLocalizedString("Camera", comment: "Image Picker Camera Action"), image: image, callback: callback)
	}

	static func libraryAction(with callback: @escaping Callback) -> ImagePickerAction {
		let image = UIImage(named: "ImagePickerAction-Library")!

		return ImagePickerAction(title: NSLocalizedString("Photos", comment: "Image Picker Photo Library Action"), image: image, callback: callback)
	}

	func call() {
		callback(self)
	}
}
