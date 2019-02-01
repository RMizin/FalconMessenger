//
//  SharedMediaController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage
import AVFoundation
import AVKit

private let sharedMediaCellID = "sharedMediaCellID"
private let sharedMediaSupplementaryID = "sharedMediaSupplementaryID"

class SharedMediaController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

	fileprivate var sharedMedia = [[SharedMedia]]() {
		didSet {
			DispatchQueue.global(qos: .utility).async { [unowned self] in
				self.configureViewable()
			}
		}
	}

	fileprivate var isLoading = false
	fileprivate var viewable = [INSPhotoViewable]()
	fileprivate let sharedMediaHistoryFetcher = SharedMediaHistoryFetcher()
	fileprivate let viewPlaceholder = ViewPlaceholder()

	var fetchingData: (userID: String, chatID: String)? {
		didSet {
			fetchPhotos()
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

	fileprivate func configureController() {
		navigationItem.title = "Shared Media"
		collectionView?.alwaysBounceVertical = true
		view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		collectionView?.backgroundColor = view.backgroundColor
		extendedLayoutIncludesOpaqueBars = true
		if #available(iOS 11.0, *) {
			navigationItem.largeTitleDisplayMode = .never
		}

		let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
		layout.minimumLineSpacing = 1
		layout.minimumInteritemSpacing = 1

		let collectionViewSize = collectionView!.frame.size
		let nrOfCellsPerRow: CGFloat = 4
		
		let itemWidth = UIDevice.current.orientation.isLandscape ? collectionViewSize.height/nrOfCellsPerRow : collectionViewSize.width/nrOfCellsPerRow
		layout.itemSize = CGSize(width: itemWidth - 2, height: itemWidth - 2)

		if #available(iOS 11.0, *) {
			collectionView?.contentInsetAdjustmentBehavior = .always
		}

		collectionView?.addRefreshFooter { [weak self] (footer) in
			guard self?.isLoading == false else { return }
			self?.isLoading = true
			self?.sharedMediaHistoryFetcher.loadPreviousMedia(self?.fetchingData)
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
				return viewable1.messageUID! > viewable2.messageUID!
			})
			self.viewable.insert(viewableElement, at: index)
		}
	}

	fileprivate func fetchPhotos() {
		sharedMediaHistoryFetcher.delegate = self
		ARSLineProgress.ars_showOnView(view)
		sharedMediaHistoryFetcher.loadPreviousMedia(fetchingData)
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
		guard let initialPhotoIndex = viewable.index(where: {$0.messageUID == currentElement.id }) else { return }
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

	func sharedMediaHistory(allLoaded: Bool) {
		DispatchQueue.main.async {
			self.collectionView?.removeRefreshFooter()
		}
		isLoading = false
		ARSLineProgress.hide()
	}

	func sharedMediaHistory(isEmpty: Bool) {
		if isEmpty {
			viewPlaceholder.add(for: view, title: .emptySharedMedia, subtitle: .emptyString, priority: .medium, position: .center)
			ARSLineProgress.hide()
			return
		} else {
			viewPlaceholder.remove(from: view, priority: .medium)
		}
	}

	func sharedMediaHistory(updated sharedMedia: [SharedMedia]) {
		let numberOfSectionsBeforeUpdate = self.sharedMedia.count
		let lastSectionIndexBeforeUpdate = self.sharedMedia.count - 1 >= 0 ? self.sharedMedia.count - 1 : 0
		var flattenArray = Array(self.sharedMedia.joined())
		flattenArray.append(contentsOf: sharedMedia)
		let newSharedMedia = SharedMedia.groupedSharedMedia(flattenArray)

		self.sharedMedia = newSharedMedia
		let numberOfSectionsAfterUpdate = self.sharedMedia.count

		self.collectionView?.refreshFooter?.stopLoading()
		isLoading = false

		UIView.performWithoutAnimation {
			collectionView?.performBatchUpdates({
				var indexSet = IndexSet()
				for index in numberOfSectionsBeforeUpdate..<numberOfSectionsAfterUpdate {
					indexSet.insert(index)
				}
				if collectionView.numberOfSections > 0 {
					collectionView?.reloadSections([lastSectionIndexBeforeUpdate])
				}

				collectionView?.insertSections(indexSet)
			}, completion: { (_) in
				ARSLineProgress.hide()
			})
		}
	}
}
