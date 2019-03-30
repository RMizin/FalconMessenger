//
//  SharedMediaController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import ARSLineProgress
import AVKit

private let sharedMediaCellID = "sharedMediaCellID"
private let sharedMediaSupplementaryID = "sharedMediaSupplementaryID"

class SharedMediaController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

	fileprivate var isLoading = false
	fileprivate var viewable = [INSPhotoViewable]()
	fileprivate var sharedMediaHistoryFetcher: SharedMediaHistoryFetcher? = SharedMediaHistoryFetcher()
	fileprivate let viewPlaceholder = ViewPlaceholder()
	var conversation: Conversation?

	fileprivate var sharedMedia = [[SharedMedia]]() {
		didSet {
			DispatchQueue.global(qos: .utility).async { [unowned self] in
				self.configureViewable()
			}
		}
	}

	var fetchingData: (userID: String, chatID: String)? {
		didSet {
			ARSLineProgress.ars_showOnView(view)
			DispatchQueue.global(qos: .userInteractive).async {
				self.fetchPhotos()
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		collectionView?.register(SharedMediaCell.self, forCellWithReuseIdentifier: sharedMediaCellID)
		collectionView?.register(ChatLogViewControllerSupplementaryView.self,
														 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
														 withReuseIdentifier: sharedMediaSupplementaryID)
		configureController()
	}

	deinit {
		sharedMediaHistoryFetcher = nil
	}

	fileprivate func configureController() {
		navigationItem.title = "Shared Media"
		collectionView?.alwaysBounceVertical = true
		view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		collectionView?.backgroundColor = view.backgroundColor
		collectionView.contentInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
		extendedLayoutIncludesOpaqueBars = true
		if #available(iOS 11.0, *) {
			navigationItem.largeTitleDisplayMode = .never
		}
		configureCollectionViewLayout()
	}

	fileprivate func configureCollectionViewLayout() {
		guard let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else { return }
		layout.minimumLineSpacing = 1
		layout.minimumInteritemSpacing = 1
		layout.sectionHeadersPinToVisibleBounds = true

		if #available(iOS 11.0, *) {
			collectionView?.contentInsetAdjustmentBehavior = .always
		}
	}

	fileprivate func configureViewable() {
		_ = sharedMedia.map({$0.map({ (element) in
			guard let urlString = element.imageURL else { return }
			var viewableElement: INSPhotoViewable!
			let cacheKey = SDWebImageManager.shared.cacheKey(for: URL(string: urlString))

			SDImageCache.shared.containsImage(forKey: cacheKey, cacheType: .disk) { (cacheType) in
				if cacheType == SDImageCacheType.disk {
					SDWebImageManager.shared.loadImage(with: URL(string: urlString),
																						 options: [.scaleDownLargeImages, .continueInBackground],
																						 progress: nil, completed:
						{ (image, _, _, _, _, _) in
							viewableElement = INSPhoto(image: image,
																				 thumbnailImage: image,
																				 messageUID: element.id,
																				 videoURL: element.videoURL,
																				 localVideoURL: element.videoURL)
							self.updateViewables(element: element, viewableElement: viewableElement)
					})
				} else {
					if let thumbnailURLString = element.thumbnailImageUrl {
						viewableElement = INSPhoto(imageURL: URL(string: urlString),
																			 thumbnailImageURL: URL(string: thumbnailURLString),
																			 messageUID: element.id, videoURL: element.videoURL, localVideoURL: element.videoURL)
					} else {
						viewableElement = INSPhoto(imageURL: URL(string: urlString),
																			 thumbnailImageURL: URL(string: urlString),
																			 messageUID: element.id, videoURL: element.videoURL, localVideoURL: element.videoURL)
					}
					self.updateViewables(element: element, viewableElement: viewableElement)
				}
			}
		})})
	}

	fileprivate func updateViewables(element: SharedMedia, viewableElement: INSPhotoViewable) {
		if !self.viewable.contains(where: { (viewable) -> Bool in
			return viewable.messageUID == viewableElement.messageUID
		}) {
			let index = self.viewable.insertionIndexOf(elem: viewableElement, isOrderedBefore: { (viewable1, viewable2) -> Bool in
				return viewable1.messageUID ?? "" > viewable2.messageUID ?? ""
			})
			self.viewable.insert(viewableElement, at: index)
		}
	}

	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let isScrollViewAtBottom = (((scrollView.contentOffset.y + scrollView.frame.size.height) > scrollView.contentSize.height))
		guard isScrollViewAtBottom && !isLoading else { return }
		isLoading = true
		sharedMediaHistoryFetcher?.loadPreviousMedia(fetchingData)
	}

	// MARK: Helpers
	fileprivate func fetchPhotos() {
		sharedMediaHistoryFetcher?.delegate = self
		sharedMediaHistoryFetcher?.loadPreviousMedia(fetchingData)
	}

	fileprivate func setViewPlaceholder(enabled: Bool) {
		if enabled {
			guard !view.subviews.contains(viewPlaceholder) else { return }
			viewPlaceholder.add(for: view, title: .emptySharedMedia, subtitle: .emptyString, priority: .medium, position: .center)
			ARSLineProgress.hide()
			return
		} else {
			guard view.subviews.contains(viewPlaceholder) else { return }
			viewPlaceholder.remove(from: view, priority: .medium)
		}
	}

	fileprivate func updated(_ media: [[SharedMedia]], with data: [SharedMedia]) -> [[SharedMedia]] {
		var flattenMedia = Array(media.joined())
		for data in data where !flattenMedia.contains(data) {
			flattenMedia.append(data)
		}
		return SharedMedia.groupedSharedMedia(flattenMedia)
	}

	// MARK: UICollectionViewDataSource
	override func collectionView(_ collectionView: UICollectionView,
															 viewForSupplementaryElementOfKind kind: String,
															 at indexPath: IndexPath) -> UICollectionReusableView {
		if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sharedMediaSupplementaryID,
																																		for: indexPath) as? ChatLogViewControllerSupplementaryView {
			header.label.text = sharedMedia[indexPath.section][indexPath.row].shortConvertedTimestamp
			return header
		}
		return UICollectionReusableView()
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return CGSize(width: 0, height: 0) }
		let screenSize: CGFloat = UIDevice.current.orientation.isLandscape ? ScreenSize.maxLength : ScreenSize.minLength
		let numberOfItemsInARow: CGFloat = UIDevice.current.orientation.isLandscape ? 8 : 4
		let sideLength = UIDevice.current.orientation.isLandscape ? screenSize / numberOfItemsInARow : (screenSize / numberOfItemsInARow) - ((numberOfItemsInARow - 2.5) * layout.minimumLineSpacing)

		return CGSize(width: sideLength, height: sideLength)
	}

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return sharedMedia.count
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return sharedMedia[section].count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sharedMediaCellID,
																									for: indexPath) as? SharedMediaCell ?? SharedMediaCell()
		let sharedElement = sharedMedia[indexPath.section][indexPath.row]
		cell.configureCell(sharedElement: sharedElement)

		return cell
	}

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: false)
		guard let cell = collectionView.cellForItem(at: indexPath) as? SharedMediaCell else { return }
		guard cell.sharedPhotoImageView.image != UIImage(named: "imagePlaceholder") else { return }
		let currentElement = sharedMedia[indexPath.section][indexPath.row]
		guard let initialPhotoIndex = viewable.firstIndex(where: {$0.messageUID == currentElement.id }) else { return }
		let currentPhoto = viewable[initialPhotoIndex]
		let galleryPreview = INSPhotosViewController(photos: viewable,
																								 initialPhoto: currentPhoto,
																								 referenceView: cell)
		galleryPreview.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
			guard let indexPath = SharedMedia.get(indexPathOf: photo,
																						in: self?.sharedMedia ?? [[SharedMedia]]()) else { return nil }
			guard let cellForDismiss = self?.collectionView?.cellForItem(at: indexPath) as? SharedMediaCell else { return nil }
			return cellForDismiss.sharedPhotoImageView
		}
		present(galleryPreview, animated: true, completion: nil)
	}

	func collectionView(_ collectionView: UICollectionView,
											layout collectionViewLayout: UICollectionViewLayout,
											referenceSizeForHeaderInSection section: Int) -> CGSize {
		return CGSize(width: collectionView.bounds.width, height: 40)
	}
}

extension SharedMediaController: SharedMediaHistoryDelegate {
	func sharedMediaHistory(allLoaded: Bool, allMedia: [SharedMedia]) {
		if allMedia.count > sharedMedia.joined().count {
			sharedMediaHistory(updated: allMedia)
		} else if allMedia.count == 0 {
			setViewPlaceholder(enabled: allMedia.count == 0)
			isLoading = false
			ARSLineProgress.hide()
		}
	}

	func sharedMediaHistory(isEmpty: Bool) {
		setViewPlaceholder(enabled: isEmpty)
	}

	func sharedMediaHistory(updated olderMedia: [SharedMedia]) {
		guard olderMedia.count > 0 else { isLoading = false; return }
		let numberOfSectionsBeforeUpdate = collectionView.numberOfSections
		sharedMedia = updated(sharedMedia, with: olderMedia)
		let numberOfSectionsAfterUpdate = sharedMedia.count
		isLoading = false
		setViewPlaceholder(enabled: sharedMedia.count == 0)

		UIView.performWithoutAnimation {
			collectionView?.performBatchUpdates({
				var indexSet = IndexSet()
				for index in numberOfSectionsBeforeUpdate..<numberOfSectionsAfterUpdate { indexSet.insert(index) }
				if collectionView.numberOfSections > 0 {
				let lastSection = collectionView.numberOfSections - 1
					collectionView?.reloadSections([lastSection])
				}
				collectionView?.insertSections(indexSet)
			}, completion: { (_) in
				ARSLineProgress.hide()
			})
		}
	}
}
