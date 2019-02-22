//
//  ImagesDownloadManager.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/8/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class ImagesDownloadManager: NSObject {

	var cellsWithActiveDownloads: Set<(IndexPath)> = Set()

	func addCell(at indexPath: IndexPath) {
		if !cellsWithActiveDownloads.contains(indexPath) {
			cellsWithActiveDownloads.insert(indexPath)
		}
	}

	func removeCell(at indexPath: IndexPath) {
		cellsWithActiveDownloads.remove(indexPath)
	}
}
