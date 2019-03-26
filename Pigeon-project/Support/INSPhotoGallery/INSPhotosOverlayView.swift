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

public protocol INSPhotosOverlayViewable:class {
    var photosViewController: INSPhotosViewController? { get set }
    
    func populateWithPhoto(_ photo: INSPhotoViewable)
    func setHidden(_ hidden: Bool, animated: Bool)
    func view() -> UIView
}

extension INSPhotosOverlayViewable where Self: UIView {
    public func view() -> UIView {
        return self
    }
}

open class INSPhotosOverlayView: UIView , INSPhotosOverlayViewable {
    open private(set) var navigationBar: UINavigationBar!
    open private(set) var captionLabel: UILabel!
    open private(set) var deleteToolbar: UIToolbar!
    
    open private(set) var navigationItem: UINavigationItem!
    open weak var photosViewController: INSPhotosViewController?
    private var currentPhoto: INSPhotoViewable?
    
    private var topShadow: CAGradientLayer!
    private var bottomShadow: CAGradientLayer!
    
    var leftBarButtonItem: UIBarButtonItem? {
        didSet {
            navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }
    var rightBarButtonItem: UIBarButtonItem? {
        didSet {
            navigationItem.rightBarButtonItem = rightBarButtonItem
        }
    }
    
    #if swift(>=4.0)
	var titleTextAttributes: [NSAttributedString.Key : AnyObject] = [:] {
        didSet {
            navigationBar.titleTextAttributes = titleTextAttributes
        }
    }
    #else
    var titleTextAttributes: [String : AnyObject] = [:] {
        didSet {
            navigationBar.titleTextAttributes = titleTextAttributes
        }
    }
    #endif
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShadows()
        setupNavigationBar()
        setupCaptionLabel()
        setupDeleteButton()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Pass the touches down to other views
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) , hitView != self {
            return hitView
        }
        return nil
    }
    
    open override func layoutSubviews() {
        // The navigation bar has a different intrinsic content size upon rotation, so we must update to that new size.
        // Do it without animation to more closely match the behavior in `UINavigationController`
        UIView.performWithoutAnimation { () -> Void in
            self.navigationBar.invalidateIntrinsicContentSize()
            self.navigationBar.layoutIfNeeded()
        }
        super.layoutSubviews()
        self.updateShadowFrames()
    }
    
    open func setHidden(_ hidden: Bool, animated: Bool) {
        if self.isHidden == hidden {
            return
        }
        
        if animated {
            self.isHidden = false
            self.alpha = hidden ? 1.0 : 0.0
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowAnimatedContent, .allowUserInteraction], animations: { () -> Void in
                self.alpha = hidden ? 0.0 : 1.0
                }, completion: { result in
                    self.alpha = 1.0
                    self.isHidden = hidden
            })
        } else {
            self.isHidden = hidden
        }
    }
    
    open func populateWithPhoto(_ photo: INSPhotoViewable) {
        self.currentPhoto = photo

        if let photosViewController = photosViewController {
            if let index = photosViewController.dataSource.indexOfPhoto(photo) {
                navigationItem.title = String(format:NSLocalizedString("%d of %d",comment:""), index+1, photosViewController.dataSource.numberOfPhotos)
            }
            captionLabel.attributedText = photo.attributedTitle
        }
        self.deleteToolbar.isHidden = photo.isDeletable != true
    }
    
    @objc private func closeButtonTapped(_ sender: UIBarButtonItem) {
        photosViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func actionButtonTapped(_ sender: UIBarButtonItem) {
      guard let currentPhoto = currentPhoto else { return }
      currentPhoto.loadImageWithCompletionHandler({ [weak self] (image, error) -> () in
        guard let image = (image ?? currentPhoto.thumbnailImage) else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = sender
        self?.photosViewController?.present(activityController, animated: true, completion: nil)
      })
    }
    
    @objc private func deleteButtonTapped(_ sender: UIBarButtonItem) {
        photosViewController?.handleDeleteButtonTapped()
    }
    
    private func setupNavigationBar() {
        navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.alpha = 0.8
        navigationBar.barTintColor = .black
        navigationBar.barStyle = .blackTranslucent
        navigationItem = UINavigationItem(title: "")
        navigationBar.items = [navigationItem]
        addSubview(navigationBar)
      var topConstraint: NSLayoutConstraint!
      if #available(iOS 11.0, *) {
				topConstraint = NSLayoutConstraint(item: navigationBar as Any, attribute: .top, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0.0)
      } else {
				topConstraint = NSLayoutConstraint(item: navigationBar as Any, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
      }
			let widthConstraint = NSLayoutConstraint(item: navigationBar as Any, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
			let horizontalPositionConstraint = NSLayoutConstraint(item: navigationBar as Any, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        self.addConstraints([topConstraint,widthConstraint,horizontalPositionConstraint])
        
        if let bundlePath = Bundle(for: type(of: self)).path(forResource: "INSPhotoGallery", ofType: "bundle") {
            let bundle = Bundle(path: bundlePath)
            leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "INSPhotoGalleryClose", in: bundle, compatibleWith: nil), landscapeImagePhone: UIImage(named: "INSPhotoGalleryCloseLandscape", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(INSPhotosOverlayView.closeButtonTapped(_:)))
        } else {
            leftBarButtonItem = UIBarButtonItem(title: "CLOSE".uppercased(), style: .plain, target: self, action: #selector(INSPhotosOverlayView.closeButtonTapped(_:)))
        }
        
        rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(INSPhotosOverlayView.actionButtonTapped(_:)))
    }
    
    private func setupCaptionLabel() {
        captionLabel = UILabel()
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.backgroundColor = UIColor.clear
        captionLabel.numberOfLines = 0
        addSubview(captionLabel)
      
      var bottomSafeArea: CGFloat = 0.0
      
      if #available(iOS 11.0, *) {
        let window = UIApplication.shared.keyWindow
        bottomSafeArea = window?.safeAreaInsets.bottom ?? 0.0
      }
        
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: captionLabel, attribute: .bottom, multiplier: 1.0, constant: 8.0 + bottomSafeArea)
			let leadingConstraint = NSLayoutConstraint(item: captionLabel as Any, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 15.0)
			let trailingConstraint = NSLayoutConstraint(item: captionLabel as Any, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 8.0 + bottomSafeArea)
        self.addConstraints([bottomConstraint,leadingConstraint,trailingConstraint])
    }
    
    private func setupShadows() {
        let startColor = UIColor.black.withAlphaComponent(0.8)
        let endColor = UIColor.black.withAlphaComponent(0.8)
        
        self.topShadow = CAGradientLayer()
        topShadow.colors = [startColor.cgColor, endColor.cgColor]
        self.layer.insertSublayer(topShadow, at: 0)
        
        self.bottomShadow = CAGradientLayer()
        bottomShadow.colors = [endColor.cgColor, startColor.cgColor]
        self.layer.insertSublayer(bottomShadow, at: 0)
        
        self.updateShadowFrames()
    }
    
    private func updateShadowFrames(){
      
      if #available(iOS 11.0, *) {
        
        let window = UIApplication.shared.keyWindow
        let bottomSafeArea = window?.safeAreaInsets.bottom ?? 0.0
        bottomShadow.frame = CGRect(x: 0, y: self.frame.height - 60 - bottomSafeArea, width: self.frame.width, height: 60 + bottomSafeArea)
        topShadow.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: UIApplication.shared.statusBarFrame.size.height )
      } else {
         bottomShadow.frame = CGRect(x: 0, y: self.frame.height - 60 , width: self.frame.width, height: 60)
        topShadow.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 60)
      }
    }
    
    private func setupDeleteButton() {
        deleteToolbar = UIToolbar()
        deleteToolbar.backgroundColor = .black
        deleteToolbar.alpha = 0.8
        deleteToolbar.translatesAutoresizingMaskIntoConstraints = false
       // deleteToolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
       // deleteToolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        deleteToolbar.isTranslucent = true
        let item = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(INSPhotosOverlayView.deleteButtonTapped(_:)))
        deleteToolbar.setItems([item], animated: false)
        addSubview(deleteToolbar)
        
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: deleteToolbar, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        let trailingConstraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: deleteToolbar, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        
			let widthConstraint = NSLayoutConstraint(item: deleteToolbar as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 65)
			let heightConstraint = NSLayoutConstraint(item: deleteToolbar as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
        self.addConstraints([bottomConstraint,trailingConstraint,widthConstraint, heightConstraint])
    }
}
