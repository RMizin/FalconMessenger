//
//  INSPhotosOverlayView.swift
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

public protocol INSPhotosOverlayViewable: class {
	var photosViewController: INSPhotosViewController? { get set }
	var bottomView: OverlayDefaultBottomView { get }
	func populateWithPhoto(_ photo: INSPhotoViewable)
	func setHidden(_ hidden: Bool, animated: Bool)
	func view() -> UIView
}

extension INSPhotosOverlayViewable where Self: UIView {
	public func view() -> UIView {
		return self
	}
}

open class INSPhotosOverlayView: UIView, INSPhotosOverlayViewable {
	
		open weak var photosViewController: INSPhotosViewController?
		private var currentPhoto: INSPhotoViewable?

		var titleTextAttributes: [NSAttributedString.Key : AnyObject] = [:] {
			didSet {
				navigationView.navigationBar.titleTextAttributes = titleTextAttributes
			}
		}

		let navigationView: OverlayNavigationBar = {
			let navigationView = OverlayNavigationBar()
			navigationView.clipsToBounds = true
			navigationView.translatesAutoresizingMaskIntoConstraints = false
			return navigationView
		}()

			public var bottomView: OverlayDefaultBottomView = {
			let bottomView = OverlayDefaultBottomView()
			bottomView.translatesAutoresizingMaskIntoConstraints = false
			return bottomView
		}()

    override init(frame: CGRect) {
			super.init(frame: frame)
			addSubview(bottomView)
			addSubview(navigationView)
			navigationView.topAnchor.constraint(equalTo: topAnchor).isActive = true
			navigationView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
			navigationView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
			bottomView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
			bottomView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
			bottomView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
			setupNavigationItemActions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
    }

		fileprivate func setupNavigationItemActions() {
			navigationView.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
																																				target: self,
																																				action: #selector(closeButtonTapped(_:)))
			navigationView.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
																																				 target: self,
																																				 action: #selector(actionButtonTapped(_:)))
			navigationView.navigationBar.items = [navigationView.navigationItem]
		}

    // Pass the touches down to other views
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
			guard let hitView = super.hitTest(point, with: event) , hitView != self else { return nil }
			return hitView
    }

    open func setHidden(_ hidden: Bool, animated: Bool) {
			if isHidden == hidden { return }
			guard animated else { isHidden = hidden; return }
			isHidden = false
			alpha = hidden ? 1.0 : 0.0
			UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowAnimatedContent, .allowUserInteraction], animations: { [weak self] () -> Void in
				self?.alpha = hidden ? 0.0 : 1.0
				}, completion: { [weak self] result in
					self?.alpha = 1.0
					self?.isHidden = hidden
			})
    }
    
    open func populateWithPhoto(_ photo: INSPhotoViewable) {
			currentPhoto = photo
			if currentPhoto?.localVideoURL == nil && currentPhoto?.videoURL == nil {
				bottomView.insPhotoBottomView.isHidden = false
				bottomView.insVideoBottomView.isHidden = true
			} else {
				bottomView.insPhotoBottomView.isHidden = true
				bottomView.insVideoBottomView.isHidden = false
			}
			guard let photosViewController = photosViewController else { return }
			bottomView.insPhotoBottomView.captionLabel.attributedText = photo.attributedTitle
			guard let index = photosViewController.dataSource.indexOfPhoto(photo) else { return }
			navigationView.navigationItem.title = String(format: NSLocalizedString("%d of %d", comment: ""),
																									 index + 1,
																									 photosViewController.dataSource.numberOfPhotos)
    }
    
    @objc func closeButtonTapped(_ sender: UIBarButtonItem) {
			photosViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func actionButtonTapped(_ sender: UIBarButtonItem) {
      guard let currentPhoto = currentPhoto else { return }
      currentPhoto.loadImageWithCompletionHandler({ [weak self] (image, error) -> () in
        guard let image = (image ?? currentPhoto.thumbnailImage) else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = sender
        self?.photosViewController?.present(activityController, animated: true, completion: nil)
      })
    }
}
