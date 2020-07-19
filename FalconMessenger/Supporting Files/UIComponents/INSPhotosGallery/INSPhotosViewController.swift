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
import AVFoundation

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
  public private(set) var pageViewController: UIPageViewController!
  public private(set) var dataSource: INSPhotosDataSource
  
  let interactiveAnimator: INSPhotosInteractionAnimator = INSPhotosInteractionAnimator()
  let transitionAnimator: INSPhotosTransitionAnimator = INSPhotosTransitionAnimator()
  
  public private(set) lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
    return UITapGestureRecognizer(target: self, action: #selector(INSPhotosViewController.handleSingleTapGestureRecognizer(_:)))
  }()
  public private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = {
    return UIPanGestureRecognizer(target: self, action: #selector(INSPhotosViewController.handlePanGestureRecognizer(_:)))
  }()
  
  private var interactiveDismissal: Bool = false
  private var statusBarHidden = false
  private var shouldHandleLongPressGesture = false
  
  private func newCurrentPhotoAfterDeletion(currentPhotoIndex: Int) -> INSPhotoViewable? {
    let previousPhotoIndex = currentPhotoIndex - 1
    if let newCurrentPhoto = self.dataSource.photoAtIndex(currentPhotoIndex) {
      return newCurrentPhoto
    } else if let previousPhoto = self.dataSource.photoAtIndex(previousPhotoIndex) {
      return previousPhoto
    }
    return nil
  }
  
  private func orientationMaskSupportsOrientation(mask: UIInterfaceOrientationMask, orientation: UIInterfaceOrientation) -> Bool {
    return (mask.rawValue & (1 << orientation.rawValue)) != 0
  }
  
  // MARK: - Initialization
  
  deinit {
    pageViewController.delegate = nil
    pageViewController.dataSource = nil
		NotificationCenter.default.removeObserver(self)
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
    modalPresentationCapturesStatusBarAppearance = true
    setupOverlayViewInitialItems()
  }
  
  private func setupOverlayViewInitialItems() {
    let textColor = view.tintColor ?? UIColor.white
    if let overlayView = overlayView as? INSPhotosOverlayView {
      overlayView.photosViewController = self
			overlayView.titleTextAttributes = [NSAttributedString.Key.foregroundColor: textColor]
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
		overlayView.bottomView.insVideoBottomView.playButton.addTarget(self, action: #selector(playPauseAction), for: .touchUpInside)
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
		if currentPhotoViewController?.playerController.player?.timeControlStatus != .playing {
			 updateCurrentPhotosInformation()
		}
		setCurrentVideoPlayerPlayButtonState()
  }
  
  private func setupOverlayView() {
    overlayView.view().autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlayView.view().frame = view.bounds
    view.addSubview(overlayView.view())
		overlayView.setHidden(false, animated: false)
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

	//MARK: Video player time labels
	fileprivate func setupPlaybackTime(time: Float64) {
		overlayView.bottomView.insVideoBottomView.minimumRate.text = getDurations(from: time)
	}

	fileprivate func setupPlayerTime() {
		let timeInSeconds	= CMTimeGetSeconds(currentPhotoViewController?.playerController.player?.currentItem?.duration ?? CMTime.zero)
		overlayView.bottomView.insVideoBottomView.minimumRate.text = "00:00"
		overlayView.bottomView.insVideoBottomView.maximumRate.text = getDurations(from: timeInSeconds)
	}

	fileprivate func resetPlayerTime() {
		overlayView.bottomView.insVideoBottomView.maximumRate.text = "--:--"
		overlayView.bottomView.insVideoBottomView.minimumRate.text = "--:--"
	}

	fileprivate func getDurations(from seconds: Float64) -> String {
		guard !seconds.isNaN else { return "--:--" }
		let secs = Int(seconds)
		let hours = secs / 3600
		let minutes = (secs % 3600) / 60
		let seconds = (secs % 3600) % 60

		let hoursString = hours < 10 ? "0\(hours)": "\(hours)"
		let minutesString = minutes < 10 ? "0\(minutes)": "\(minutes)"
		let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"

		if hours > 0 {
			return hoursString + ":" + minutesString + ":" + secondsString
		} else {
			return minutesString + ":" + secondsString
		}
	}

	//MARK: Video player play button

	fileprivate func setCurrentVideoPlayerPlayButtonState() {
		overlayView.bottomView.insVideoBottomView.playButton.isSelected = currentPhotoViewController?.playerController.player?.timeControlStatus == .playing
	}
	@objc fileprivate func playPauseAction() {
		overlayView.bottomView.insVideoBottomView.playButton.isSelected = !overlayView.bottomView.insVideoBottomView.playButton.isSelected

		if !overlayView.bottomView.insVideoBottomView.playButton.isSelected {
			currentPhotoViewController?.playerController.player?.pause()
		} else {
			currentPhotoViewController?.playerController.player?.play()
		}
	}

	//MARK: General video player actions
	@objc fileprivate func playerDidFinishPlaying() {
		overlayView.bottomView.insVideoBottomView.playButton.isSelected = false
		currentPhotoViewController?.playerController.player?.seek(to: .zero)
	}


	//MARK: Video player slider

	fileprivate var readyToPlayObserver: NSKeyValueObservation?
	fileprivate var playbackObserver: NSKeyValueObservation?
	fileprivate var isPlayingObserver: NSKeyValueObservation?

	fileprivate func configureVideoPlayerSlider() {
		let timeInSeconds	= CMTimeGetSeconds(currentPhotoViewController?.playerController.player?.currentItem?.duration ?? CMTime.zero)
		overlayView.bottomView.insVideoBottomView.seekSlider.minimumValue = 0

		overlayView.bottomView.insVideoBottomView.seekSlider.maximumValue = Float(timeInSeconds).isNaN ? 0 : Float(timeInSeconds)
		overlayView.bottomView.insVideoBottomView.seekSlider.isUserInteractionEnabled = true
		overlayView.bottomView.insVideoBottomView.seekSlider.addTarget(self, action: #selector(onSliderValueChanged(slider:event:)), for: .valueChanged)
	}

	fileprivate func updateVideoPlayerSliderCurrentValue(with time: CMTime) {
		setupPlaybackTime(time: CMTimeGetSeconds(time))
		if CMTimeGetSeconds(time) > 0 {
			UIView.animate(withDuration: 0.1, animations: { [weak self] in
				self?.overlayView.bottomView.insVideoBottomView.seekSlider.setValue(Float(CMTimeGetSeconds(time)), animated: true)
			})
		} else {
			overlayView.bottomView.insVideoBottomView.seekSlider.setValue(Float(CMTimeGetSeconds(time)), animated: false)
		}
	}

	@objc fileprivate func onSliderValueChanged(slider: UISlider, event: UIEvent) {
		if let touchEvent = event.allTouches?.first {
			switch touchEvent.phase {
			case .began: break
			case .moved:
				currentPhotoViewController?.playerController.player?.seek(to: CMTime(seconds: Double(slider.value),
																																						 preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
				break
			case .ended: break
			default: break
			}
		}
	}

	//MARK: Video player observers
	fileprivate func setupVideoPlayerObservers() {
		readyToPlayObserver = currentPhotoViewController?.playerController.player?.currentItem?.observe(\.status, options: NSKeyValueObservingOptions.new, changeHandler: { [weak self] (item, change) in
			if item.status == .readyToPlay {
				self?.setupPlayerTime()
				self?.configureVideoPlayerSlider()
			}
		})

		isPlayingObserver = currentPhotoViewController?.playerController.player?.observe(\.timeControlStatus, options:  [.old, .new], changeHandler: { [weak self] (item, change) in
			guard let unwrappedSelf = self else { return }
			if unwrappedSelf.currentPhotoViewController?.playerController.player?.timeControlStatus == .playing {
				unwrappedSelf.overlayView.bottomView.insVideoBottomView.playButton.isSelected = true
				for subview in unwrappedSelf.view.subviews where subview is INSScalingImageView {
					DispatchQueue.main.async {
						subview.removeFromSuperview()
					}
				}
			} else {
				unwrappedSelf.overlayView.bottomView.insVideoBottomView.playButton.isSelected = false
			}
		})

		playbackObserver = currentPhotoViewController?.playerController.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { [weak self] (time) in
			self?.updateVideoPlayerSliderCurrentValue(with: time)
		}) as? NSKeyValueObservation

		NotificationCenter.default.addObserver(self,
																					 selector: #selector(playerDidFinishPlaying),
																					 name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
																					 object: currentPhotoViewController?.playerController.player?.currentItem)
	}

	fileprivate func invalidateVideoPlayerObservers() {
		playerDidFinishPlaying()
		resetPlayerTime()
		NotificationCenter.default.removeObserver(self)
		readyToPlayObserver?.invalidate()
		isPlayingObserver?.invalidate()
		if let observer = playbackObserver {
			currentPhotoViewController?.playerController.player?.removeTimeObserver(observer)
			playbackObserver?.invalidate()
		}
	}

  // MARK: - Public
  
  /**
   Displays the specified photo. Can be called before the view controller is displayed. Calling with a photo not contained within the data source has no effect.
   
   - parameter photo:    The photo to make the currently displayed photo.
   - parameter animated: Whether to animate the transition to the new photo.
   */

	fileprivate func prefetchNearbyPhotos(photo: INSPhotoViewable) {
		if let index = dataSource.indexOfPhoto(photo) {
			let nextPhoto = dataSource.photoAtIndex(index - 1)
			let photoAfterNext = dataSource.photoAtIndex(index - 2)
			let previousPhoto = dataSource.photoAtIndex(index + 1)
			let photoAfterPrevious = dataSource.photoAtIndex(index + 2)
			let urls = [previousPhoto?.imageURL, nextPhoto?.imageURL , photoAfterPrevious?.imageURL, photoAfterNext?.imageURL].compactMap({$0})
			prefetchThumbnail(from: urls)
		}
	}
	
	open func changeToPhoto(_ photo: INSPhotoViewable, animated: Bool, direction: UIPageViewController.NavigationDirection = .forward) {
    if !dataSource.containsPhoto(photo) {
      return
    }




    let photoViewController = initializePhotoViewControllerForPhoto(photo)
    pageViewController.setViewControllers([photoViewController], direction: direction, animated: animated, completion: nil)
    updateCurrentPhotosInformation()
  }

	fileprivate func updateCurrentPhotosInformation() {
		if let currentPhoto = currentPhoto {
			overlayView.populateWithPhoto(currentPhoto)
		}

		invalidateVideoPlayerObservers()

		if currentPhotoViewController?.playerController.player?.status == .readyToPlay {
			setupPlayerTime()
			configureVideoPlayerSlider()
		}

		setupVideoPlayerObservers()
	}
  
  // MARK: - Gesture Recognizers
  
  @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
    
    // if current orientation is different from supported orientations of presenting vc, disable flick-to-dismiss
    if let presentingViewController = presentingViewController {
      if !orientationMaskSupportsOrientation(mask: presentingViewController.supportedInterfaceOrientations, orientation: UIApplication.shared.statusBarOrientation) {
        return
      }
    }
    
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
  
  open func handleDeleteButtonTapped() {
    if let currentPhoto = self.currentPhoto {
      if let currentPhotoIndex = self.dataSource.indexOfPhoto(currentPhoto) {
        self.dataSource.deletePhoto(currentPhoto)
        self.deletePhotoHandler?(currentPhoto)
        if let photo = newCurrentPhotoAfterDeletion(currentPhotoIndex: currentPhotoIndex) {
          if currentPhotoIndex == self.dataSource.numberOfPhotos {
            self.changeToPhoto(photo, animated: true, direction: .reverse)
          } else {
            self.changeToPhoto(photo, animated: true)
          }
        } else {
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
  public func initializePhotoViewControllerForPhoto(_ photo: INSPhotoViewable) -> INSPhotoViewController {
    let photoViewController = INSPhotoViewController(photo: photo)
		prefetchNearbyPhotos(photo: photo)
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
  
  open override var preferredStatusBarStyle: UIStatusBarStyle {
    return .default
  }
  
  open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
    return .fade
  }
}
