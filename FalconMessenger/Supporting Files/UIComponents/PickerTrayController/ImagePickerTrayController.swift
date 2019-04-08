//
//  ImagePickerTrayController.swift
//  ImagePickerTrayController
//
//  Created by Laurin Brandner on 14.10.16.
//  Copyright © 2016 Laurin Brandner. All rights reserved.
//

import UIKit
import Photos

/// The media type an instance of ImagePickerSheetController can display
enum ImagePickerMediaType {
	case image
	case video
	case imageAndVideo
}

@objc protocol ImagePickerTrayControllerDelegate: class {
	@objc optional func controller(_ controller: ImagePickerTrayController, willSelectAsset asset: PHAsset, at indexPath: IndexPath)
	@objc optional func controller(_ controller: ImagePickerTrayController, didSelectAsset asset: PHAsset, at indexPath: IndexPath?)
	@objc optional func controller(_ controller: ImagePickerTrayController, willDeselectAsset asset: PHAsset, at indexPath: IndexPath)
	@objc optional func controller(_ controller: ImagePickerTrayController, didDeselectAsset asset: PHAsset, at indexPath: IndexPath)
	@objc optional func controller(_ controller: ImagePickerTrayController, didTakeImage image: UIImage)
	@objc optional func controller(_ controller: ImagePickerTrayController, didTakeImage image: UIImage, with asset: PHAsset)
	@objc optional func controller(_ controller: ImagePickerTrayController, didRecordVideoAsset asset: PHAsset)
}

let ImagePickerTrayWillShow: Notification.Name = Notification.Name(rawValue: "ch.laurinbrandner.ImagePickerTrayWillShow")
let ImagePickerTrayDidShow: Notification.Name = Notification.Name(rawValue: "ch.laurinbrandner.ImagePickerTrayDidShow")
let ImagePickerTrayWillHide: Notification.Name = Notification.Name(rawValue: "ch.laurinbrandner.ImagePickerTrayWillHide")
let ImagePickerTrayDidHide: Notification.Name = Notification.Name(rawValue: "ch.laurinbrandner.ImagePickerTrayDidHide")
let ImagePickerTrayFrameUserInfoKey = "ImagePickerTrayFrame"
let ImagePickerTrayAnimationDurationUserInfoKey = "ImagePickerTrayAnimationDuration"

class ImagePickerTrayController: UIViewController {

	weak var delegate: ImagePickerTrayControllerDelegate?
	var imageManager: PHCachingImageManager?
	var assets = [PHAsset]()

	fileprivate let actionCellWidth: CGFloat = 100
	fileprivate let animationDuration: TimeInterval = 0.2
	fileprivate(set) var actions = [ImagePickerAction]()
	fileprivate var transitionController: TransitionController?

	static let librarySectionIndex = 1

	fileprivate(set) lazy var collectionView: UICollectionView = {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 1
		layout.minimumLineSpacing = 1

		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		collectionView.dataSource = self
		collectionView.delegate = self
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.alwaysBounceHorizontal = true

		collectionView.register(ActionCell.self, forCellWithReuseIdentifier: NSStringFromClass(ActionCell.self))
		collectionView.register(ImageCell.self, forCellWithReuseIdentifier: NSStringFromClass(ImageCell.self))

		return collectionView
	}()

	fileprivate lazy var requestOptions: PHImageRequestOptions = {
		let options = PHImageRequestOptions()
		options.deliveryMode = .opportunistic
		options.resizeMode = .fast

		return options
	}()

	fileprivate var allowsMultipleSelection = true {
		didSet {
			guard isViewLoaded else { return }
			collectionView.allowsMultipleSelection = allowsMultipleSelection
		}
	}

	fileprivate var sections: [Int] {
		let actionSection = actions.count > 0 ? 1 : 0
		let assetSection = assets.count

		return [actionSection, assetSection]
	}

	fileprivate var allowsInteractivePresentation: Bool {
		get {
			return transitionController?.allowsInteractiveTransition ?? false
		}
		set {
			transitionController?.allowsInteractiveTransition = newValue
		}
	}

	// MARK: - Initialization

	init() {
		super.init(nibName: nil, bundle: nil)

		let status = libraryAccessChecking()

		if status {
			imageManager = PHCachingImageManager()
		} else {
			imageManager = nil
		}

		transitionController = TransitionController(frame: collectionView.frame)
		transitionController?.delegate = self
		modalPresentationStyle = .custom
		transitioningDelegate = transitionController
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		if imageManager != nil { imageManager = nil }
		collectionView.removeFromSuperview()
		print("\n TRAY CONTROLLER DID DEINIT \n")
	}

//	var heightConstraint: NSLayoutConstraint!
	override func loadView() {
		super.loadView()

		view.addSubview(collectionView)
		collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		if #available(iOS 11.0, *) {
			collectionView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
			collectionView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
			collectionView.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor).isActive = true
		} else {
			collectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
			collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
			collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
		}
		collectionView.allowsMultipleSelection = allowsMultipleSelection
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		fetchAssets()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self)
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		collectionView.collectionViewLayout.invalidateLayout()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		collectionView.collectionViewLayout.invalidateLayout()
	}

	func add(action: ImagePickerAction) {
		actions.append(action)
	}

	func fetchAssets() {
		let options = PHFetchOptions()
		options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		options.fetchLimit = 100

		let result = PHAsset.fetchAssets(with: options)
		result.enumerateObjects({ asset, index, stop in
			self.assets.append(asset)
		})
	}

	typealias CompletionHandler = (_ success: Bool) -> Void

	func reFetchAssets(completionHandler: @escaping CompletionHandler) {
		assets.removeAll()
		let options = PHFetchOptions()
		options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		options.fetchLimit = 100

		let result = PHAsset.fetchAssets(with: options)
		result.enumerateObjects({ asset, index, stop in
			self.assets.append(asset)
		})

		let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems
		var newSelectedIndexPaths = [IndexPath]()

		for newIndexPath in selectedIndexPaths! {
			let indexPath = IndexPath(item: newIndexPath.item + 1 , section: newIndexPath.section)
			newSelectedIndexPaths.append(indexPath)
		}
		newSelectedIndexPaths.append(IndexPath(item: 0, section: 1))

		var indexPaths = [IndexPath]()
		for index in 0..<assets.count {
			indexPaths.append(IndexPath(item: index, section: 1))
		}

		DispatchQueue.main.async { [weak self] in
			self?.collectionView.performBatchUpdates({
				self?.collectionView.reloadItems(at: indexPaths)
			}) { (_) in
				for indexPathForSelection in newSelectedIndexPaths {
					self?.collectionView.selectItem(at: indexPathForSelection, animated: false, scrollPosition: .bottom)
				}
				completionHandler(true)
			}
		}
	}

	fileprivate func requestImage(for asset: PHAsset, completion: @escaping (_ image: UIImage?) -> ()) {
		requestOptions.isSynchronous = false

		let size = CGSize(width: 200, height: 200)

		if asset.representsBurst {
			self.imageManager?.requestImageData(for: asset, options: self.requestOptions) { data, _, _, _ in
				let image = data.flatMap { UIImage(data: $0) }
				completion(image)
			}
		} else {
			self.imageManager?.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: self.requestOptions) { image, _ in
				completion(image)
			}
		}
	}
}

// MARK: - UICollectionViewDataSource

extension ImagePickerTrayController: UICollectionViewDataSource {

	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return sections.count
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return sections[section]
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		switch indexPath.section {
		case 0:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ActionCell.self), for: indexPath) as! ActionCell
			cell.imagePickerTrayController = self
			cell.actions = actions

			return cell

		case 1:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ImageCell.self), for: indexPath) as! ImageCell
			let asset = assets[indexPath.item]
			if assets.count > indexPath.item {
				cell.isVideo = (asset.mediaType == .video)
				DispatchQueue.main.async {
					self.requestImage(for: asset) { cell.imageView.image = $0 }
				}
			}

			return cell

		default:
			fatalError("More than 3 sections is invalid.")
		}
	}
}

// MARK: - UICollectionViewDelegate

extension ImagePickerTrayController: UICollectionViewDelegate {
    
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		guard indexPath.section == sections.count - 1 else {
			return false
		}

		if assets.count > indexPath.item {
			delegate?.controller?(self, willSelectAsset: assets[indexPath.item], at: indexPath)
		}
		return true
	}
    
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if assets.count > indexPath.item {
			delegate?.controller?(self, didSelectAsset: assets[indexPath.item], at: indexPath)
		}
	}

	func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
		if assets.count > indexPath.item {
			delegate?.controller?(self, willDeselectAsset: assets[indexPath.item], at: indexPath)
		}
		return true
	}

	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		if assets.count > indexPath.item {
			delegate?.controller?(self, didDeselectAsset: assets[indexPath.item], at: indexPath)
		}
	}
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ImagePickerTrayController: UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		switch indexPath.section {
		case 0:
			return CGSize(width: actionCellWidth, height: collectionView.frame.height - 1)
		case 1:
			return CGSize(width: (collectionView.frame.height/2)-1, height: (collectionView.frame.height/2)-1)
		default:
			return .zero
		}
	}
}

extension ImagePickerTrayController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
			delegate?.controller?(self, didTakeImage: image)
		}
	}
}

extension ImagePickerTrayController: TransitionControllerDelegate {
	func dismiss() {
		dismiss(animated: true, completion: nil)
	}
}
