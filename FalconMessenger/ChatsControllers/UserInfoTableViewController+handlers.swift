//
//  UserInfoTableViewController+handlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 10/18/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

extension UserInfoTableViewController {
	
 @objc func openPhoto() {
		let overlay = INSPhotosOverlayView()
		overlay.bottomView.isHidden = true
		guard let urlString = user?.photoURL else { return }
		var photo: INSPhoto!

		let cacheKey = SDWebImageManager.shared.cacheKey(for: URL(string: urlString))

		SDImageCache.shared.containsImage(forKey: cacheKey, cacheType: .disk) { (cacheType) in
			if cacheType == SDImageCacheType.disk {
				SDWebImageManager.shared.loadImage(with: URL(string: urlString),
																					 options: [.scaleDownLargeImages, .continueInBackground],
																					 progress: nil, completed:
					{ (image, _, _, _, _, _) in
						photo = INSPhoto(image: image, thumbnailImage: image, messageUID: nil)
						self.presentPhoto(photo: photo, overlay: overlay)
				})
			} else {
				if let thumbnailURLString = self.user?.thumbnailPhotoURL {
					photo = INSPhoto(imageURL: URL(string: urlString), thumbnailImageURL: URL(string: thumbnailURLString), messageUID: nil)
				} else {
					photo = INSPhoto(imageURL: URL(string: urlString), thumbnailImageURL: URL(string: urlString), messageUID: nil)
				}
				self.presentPhoto(photo: photo, overlay: overlay)
			}
		}
  }

	fileprivate func presentPhoto(photo: INSPhoto, overlay: INSPhotosOverlayView) {
		let photos: [INSPhotoViewable] = [photo]

		let indexPath = IndexPath(row: 0, section: 0)
		let cell = tableView.cellForRow(at: indexPath) as? UserinfoHeaderTableViewCell ?? UserinfoHeaderTableViewCell()
		let currentPhoto = photos[indexPath.row]
		let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: cell.icon)

		galleryPreview.overlayView = overlay
		galleryPreview.overlayView.setHidden(true, animated: false)

		galleryPreview.referenceViewForPhotoWhenDismissingHandler = {  photo in
			return cell.icon
		}
		galleryPreview.modalPresentationStyle = .overFullScreen
		galleryPreview.modalPresentationCapturesStatusBarAppearance = true
		present(galleryPreview, animated: true, completion: nil)
	}
}
