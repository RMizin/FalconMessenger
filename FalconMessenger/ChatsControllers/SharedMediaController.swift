//
//  SharedMediaController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

private let sharedMediaCellID = "sharedMediaCellID"
private let sharedMediaSupplementaryID = "sharedMediaSupplementaryID"

class SharedMediaController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

	fileprivate var sharedPhotos = [[SharedPhoto]]()
	fileprivate let sharedPhotosFetcher = SharedPhotosFetcher()

	var fetchingData: (userID: String, chatID: String)? {
		didSet {
			fetchPhotos()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView?.register(SharedMediaCell.self, forCellWithReuseIdentifier: sharedMediaCellID)
		collectionView?.register(ChatLogViewControllerSupplementaryView.self,
														 forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
														 withReuseIdentifier: sharedMediaSupplementaryID)
		configureController()
	}

	fileprivate func configureController() {
		navigationItem.title = "Shared"
		collectionView?.alwaysBounceVertical = true
		extendedLayoutIncludesOpaqueBars = true

		let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
		layout.minimumLineSpacing = 1
		layout.minimumInteritemSpacing = 1
		let collectionViewSize = collectionView!.frame.size
		let nrOfCellsPerRow: CGFloat = 4
		let itemWidth = collectionViewSize.width/nrOfCellsPerRow
		layout.itemSize = CGSize(width: itemWidth-2, height: itemWidth-2)
	}

	fileprivate func fetchPhotos() {
		sharedPhotosFetcher.delegate = self
		sharedPhotosFetcher.fetchPhotos(userID: fetchingData?.userID, chatID: fetchingData?.chatID)
	}

	// MARK: UICollectionViewDataSource
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sharedMediaSupplementaryID,
																																		for: indexPath) as? ChatLogViewControllerSupplementaryView {
			header.label.text = sharedPhotos[indexPath.section][indexPath.row].shortConvertedTimestamp
			return header
		}
		return UICollectionReusableView()
	}

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return sharedPhotos.count
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return sharedPhotos[section].count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sharedMediaCellID,
																									for: indexPath) as? SharedMediaCell ?? SharedMediaCell()
		let sharedPhoto = sharedPhotos[indexPath.section][indexPath.row]
		cell.configureCell(sharedPhoto: sharedPhoto)

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
		return CGSize(width: collectionView.bounds.width, height: 40)
	}
}

extension SharedMediaController: SharedMediaDelegate {
	func sharedPhotos(with photoURLs: [[SharedPhoto]]) {
		sharedPhotos = photoURLs
		DispatchQueue.main.async {
			self.collectionView?.reloadData()
		}
	}

	func sharedVideos(with videoURLs: [[SharedVideo]]) {}
}
