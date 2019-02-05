//
//  INSPhotosViewController.swift
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

public typealias INSPhotosViewControllerReferenceViewHandler = (_ photo: INSPhotoViewable) -> (UIView?)
public typealias INSPhotosViewControllerNavigateToPhotoHandler = (_ photo: INSPhotoViewable) -> ()
public typealias INSPhotosViewControllerDismissHandler = (_ viewController: INSPhotosViewController) -> ()
public typealias INSPhotosViewControllerLongPressHandler = (_ photo: INSPhotoViewable, _ gestureRecognizer: UILongPressGestureRecognizer) -> (Bool)
public typealias INSPhotosViewControllerDeletePhotoHandler = (_ photo: INSPhotoViewable) -> ()


open class INSPhotosViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    /* 
     * Returns the view from which to animate for object conforming to INSPhotoViewable 
     */
    open var referenceViewForPhotoWhenDismissingHandler: INSPhotosViewControllerReferenceViewHandler?
    
    /*
     * Called when a new photo is displayed through a swipe gesture.
     */
    open var navigateToPhotoHandler: INSPhotosViewControllerNavigateToPhotoHandler?
    
    /*
     * Called before INSPhotosViewController will start a user-initiated dismissal.
     */
    open var willDismissHandler: INSPhotosViewControllerDismissHandler?
    
    /*
     * Called after the INSPhotosViewController has been dismissed by the user.
     */
    open var didDismissHandler: INSPhotosViewControllerDismissHandler?
    
    /*
     * Called when a photo is long pressed.
     */
    open var longPressGestureHandler: INSPhotosViewControllerLongPressHandler?
    
    /*
     * Called when delete is tapped on a photo
     */
    open var deletePhotoHandler: INSPhotosViewControllerDeletePhotoHandler?
    
    /*
     * The overlay view displayed over photos, can be changed but must implement INSPhotosOverlayViewable
     */
    open var overlayView: INSPhotosOverlayViewable = INSPhotosOverlayView(frame: CGRect.zero) {
        willSet {
            overlayView.view().removeFromSuperview()
        }
        didSet {
            overlayView.photosViewController = self
            overlayView.view().autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlayView.view().frame = view.bounds
            view.addSubview(overlayView.view())
        }
    }

    /*
     * INSPhotoViewController is currently displayed by page view controller
     */
    open var currentPhotoViewController: INSPhotoViewController? {
        return pageViewController.viewControllers?.first as? INSPhotoViewController
    }
    
    /*
     * Photo object that is currently displayed by INSPhotoViewController
     */
    open var currentPhoto: INSPhotoViewable? {
        return currentPhotoViewController?.photo
    }
    
    // MARK: - Private
    private(set) var pageViewController: UIPageViewController!
    private(set) var dataSource: INSPhotosDataSource
    
    let interactiveAnimator: INSPhotosInteractionAnimator = INSPhotosInteractionAnimator()
    let transitionAnimator: INSPhotosTransitionAnimator = INSPhotosTransitionAnimator()
    
    private(set) lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(INSPhotosViewController.handleSingleTapGestureRecognizer(_:)))
    }()
    private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(INSPhotosViewController.handlePanGestureRecognizer(_:)))
    }()
    
    private var interactiveDismissal: Bool = false
    private var statusBarHidden = false
    private var shouldHandleLongPressGesture = false
    
    private func newCurrentPhotoAfterDeletion(currentPhotoIndex: Int) -> INSPhotoViewable? {
        let previousPhotoIndex = currentPhotoIndex - 1
        if let newCurrentPhoto = self.dataSource.photoAtIndex(currentPhotoIndex) {
            return newCurrentPhoto
        }else if let previousPhoto = self.dataSource.photoAtIndex(previousPhotoIndex) {
            return previousPhoto
        }
        return nil
    }
    
    // MARK: - Initialization
    
    deinit {
        pageViewController.delegate = nil
        pageViewController.dataSource = nil
    }
    
    required public init?(coder aDecoder: NSCoder) {
        dataSource = INSPhotosDataSource(photos: [])
        super.init(nibName: nil, bundle: nil)
        initialSetupWithInitialPhoto(nil)
    }
    
    public override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        dataSource = INSPhotosDataSource(photos: [])
        super.init(nibName: nil, bundle: nil)
        initialSetupWithInitialPhoto(nil)
    }
    
    /**
     The designated initializer that stores the array of objects implementing INSPhotoViewable
     
     - parameter photos:        An array of objects implementing INSPhotoViewable.
     - parameter initialPhoto:  The photo to display initially. Must be contained within the `photos` array.
     - parameter referenceView: The view from which to animate.
     
     - returns: A fully initialized object.
     */
    public init(photos: [INSPhotoViewable], initialPhoto: INSPhotoViewable? = nil, referenceView: UIView? = nil) {
        dataSource = INSPhotosDataSource(photos: photos)
        super.init(nibName: nil, bundle: nil)
        initialSetupWithInitialPhoto(initialPhoto)
        transitionAnimator.startingView = referenceView
        transitionAnimator.endingView = currentPhotoViewController?.scalingImageView.imageView
    }
    
    private func initialSetupWithInitialPhoto(_ initialPhoto: INSPhotoViewable? = nil) {
        overlayView.photosViewController = self
        setupPageViewControllerWithInitialPhoto(initialPhoto)

        modalPresentationStyle = .custom
        transitioningDelegate = self
      
       if #available(iOS 11.0, *) {
         modalPresentationCapturesStatusBarAppearance = false
       } else {
         modalPresentationCapturesStatusBarAppearance = true
      }
    
        setupOverlayViewInitialItems()
    }
 
    
    private func setupOverlayViewInitialItems() {
        let textColor = view.tintColor ?? UIColor.white
        if let overlayView = overlayView as? INSPhotosOverlayView {
            overlayView.photosViewController = self
            #if swift(>=4.0)
					overlayView.titleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor]
            #else
                overlayView.titleTextAttributes = [NSForegroundColorAttributeName: textColor]
            #endif
        }
    }
    
    // MARK: - View Life Cycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = UIColor.white
        view.backgroundColor = UIColor.black
        pageViewController.view.backgroundColor = UIColor.clear
        pageViewController.view.addGestureRecognizer(panGestureRecognizer)
        pageViewController.view.addGestureRecognizer(singleTapGestureRecognizer)
        
			addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			pageViewController.didMove(toParent: self)
        
        setupOverlayView()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // This fix issue that navigationBar animate to up
        // when presentingViewController is UINavigationViewController
        statusBarHidden = true
        UIView.animate(withDuration: 0.25) { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        }
        updateCurrentPhotosInformation()
    }
    
    private func setupOverlayView() {
        
        overlayView.view().autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.view().frame = view.bounds
        view.addSubview(overlayView.view())
        overlayView.setHidden(true, animated: false)
    }
    
    private func setupPageViewControllerWithInitialPhoto(_ initialPhoto: INSPhotoViewable? = nil) {
			pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [UIPageViewController.OptionsKey.interPageSpacing: 16.0])
        pageViewController.view.backgroundColor = UIColor.clear
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        if let photo = initialPhoto , dataSource.containsPhoto(photo) {
            changeToPhoto(photo, animated: false)
        } else if let photo = dataSource.photos.first {
            changeToPhoto(photo, animated: false)
        }
    }
    
    private func updateCurrentPhotosInformation() {
        if let currentPhoto = currentPhoto {
            overlayView.populateWithPhoto(currentPhoto)
        }
    }
    
    // MARK: - Public
    
    /**
     Displays the specified photo. Can be called before the view controller is displayed. Calling with a photo not contained within the data source has no effect.
     
     - parameter photo:    The photo to make the currently displayed photo.
     - parameter animated: Whether to animate the transition to the new photo.
     */
	open func changeToPhoto(_ photo: INSPhotoViewable, animated: Bool, direction: UIPageViewController.NavigationDirection = .forward) {
        if !dataSource.containsPhoto(photo) {
            return
        }
        let photoViewController = initializePhotoViewControllerForPhoto(photo)
        pageViewController.setViewControllers([photoViewController], direction: direction, animated: animated, completion: nil)
        updateCurrentPhotosInformation()
    }
    
    // MARK: - Gesture Recognizers
    
    @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            interactiveDismissal = true
            dismiss(animated: true, completion: nil)
        } else {
            interactiveDismissal = false
            interactiveAnimator.handlePanWithPanGestureRecognizer(gestureRecognizer, viewToPan: pageViewController.view, anchorPoint: CGPoint(x: view.bounds.midX, y: view.bounds.midY))
        }
    }
    
    @objc private func handleSingleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        overlayView.setHidden(!overlayView.view().isHidden, animated: true)
    }
    
    // MARK: - Target Actions
    
    open func handleDeleteButtonTapped(){
        if let currentPhoto = self.currentPhoto {
            if let currentPhotoIndex = self.dataSource.indexOfPhoto(currentPhoto) {
                self.dataSource.deletePhoto(currentPhoto)
                self.deletePhotoHandler?(currentPhoto)
                if let photo = newCurrentPhotoAfterDeletion(currentPhotoIndex: currentPhotoIndex) {
                    if currentPhotoIndex == self.dataSource.numberOfPhotos {
                        self.changeToPhoto(photo, animated: true, direction: .reverse)
                    }else{
                        self.changeToPhoto(photo, animated: true)
                    }
                }else{
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - View Controller Dismissal
    
    open override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        if presentedViewController != nil {
            super.dismiss(animated: flag, completion: completion)
            return
        }
        var startingView: UIView?
        if currentPhotoViewController?.scalingImageView.imageView.image != nil {
            startingView = currentPhotoViewController?.scalingImageView.imageView
        }
        transitionAnimator.startingView = startingView
        
        if let currentPhoto = currentPhoto {
            transitionAnimator.endingView = referenceViewForPhotoWhenDismissingHandler?(currentPhoto)
        } else {
            transitionAnimator.endingView = nil
        }
        let overlayWasHiddenBeforeTransition = overlayView.view().isHidden
        overlayView.setHidden(true, animated: true)
        
        willDismissHandler?(self)
        
        super.dismiss(animated: flag) { () -> Void in
            let isStillOnscreen = self.view.window != nil
            if isStillOnscreen && !overlayWasHiddenBeforeTransition {
                self.overlayView.setHidden(false, animated: true)
            }
            
            if !isStillOnscreen {
                self.didDismissHandler?(self)
            }
            completion?()
        }
    }
    
    // MARK: - UIPageViewControllerDataSource / UIPageViewControllerDelegate

    private func initializePhotoViewControllerForPhoto(_ photo: INSPhotoViewable) -> INSPhotoViewController {
        let photoViewController = INSPhotoViewController(photo: photo)
        singleTapGestureRecognizer.require(toFail: photoViewController.doubleTapGestureRecognizer)
        photoViewController.longPressGestureHandler = { [weak self] gesture in
            guard let weakSelf = self else {
                return
            }
            weakSelf.shouldHandleLongPressGesture = false
            
            if let gestureHandler = weakSelf.longPressGestureHandler {
                weakSelf.shouldHandleLongPressGesture = gestureHandler(photo, gesture)
            }
            weakSelf.shouldHandleLongPressGesture = !weakSelf.shouldHandleLongPressGesture
            
            if weakSelf.shouldHandleLongPressGesture {
                guard let view = gesture.view else {
                    return
                }
                let menuController = UIMenuController.shared
                var targetRect = CGRect.zero
                targetRect.origin = gesture.location(in: view)
                menuController.setTargetRect(targetRect, in: view)
                menuController.setMenuVisible(true, animated: true)
            }
        }
        return photoViewController
    }
    
    @objc open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let photoViewController = viewController as? INSPhotoViewController,
           let photoIndex = dataSource.indexOfPhoto(photoViewController.photo),
           let newPhoto = dataSource[photoIndex-1] else {
            return nil
        }
        return initializePhotoViewControllerForPhoto(newPhoto)
    }
    
    @objc open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let photoViewController = viewController as? INSPhotoViewController,
            let photoIndex = dataSource.indexOfPhoto(photoViewController.photo),
            let newPhoto = dataSource[photoIndex+1] else {
                return nil
        }
        return initializePhotoViewControllerForPhoto(newPhoto)
    }
    
    @objc open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            updateCurrentPhotosInformation()
            if let currentPhotoViewController = currentPhotoViewController {
                navigateToPhotoHandler?(currentPhotoViewController.photo)
            }
        }
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.dismissing = false
        return transitionAnimator
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.dismissing = true
        return transitionAnimator
    }

    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if interactiveDismissal {
            transitionAnimator.endingViewForAnimation = transitionAnimator.endingView?.ins_snapshotView()
            interactiveAnimator.animator = transitionAnimator
            interactiveAnimator.shouldAnimateUsingAnimator = transitionAnimator.endingView != nil
            interactiveAnimator.viewToHideWhenBeginningTransition = transitionAnimator.startingView != nil ? transitionAnimator.endingView : nil
            
            return interactiveAnimator
        }
        return nil
    }
    
    // MARK: - UIResponder
    
    open override func copy(_ sender: Any?) {
        UIPasteboard.general.image = currentPhoto?.image ?? currentPhotoViewController?.scalingImageView.image
    }
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let _ = currentPhoto?.image ?? currentPhotoViewController?.scalingImageView.image , shouldHandleLongPressGesture && action == #selector(NSObject.copy) {
            return true
        }
        return false
    }
    
    // MARK: - Status Bar
    
    open override var prefersStatusBarHidden: Bool {
        if let parentStatusBarHidden = presentingViewController?.prefersStatusBarHidden , parentStatusBarHidden == true {
            return parentStatusBarHidden
        }
        return statusBarHidden
    }
    
//    open override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
//
//    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
//        return .fade
//    }
}

