//
//  SharedMediaDelegate.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

protocol SharedMediaHistoryDelegate: class {
	func sharedMediaHistory(isEmpty: Bool)
	func sharedMediaHistory(allLoaded: Bool)
	func sharedMediaHistory(updated sharedMedia: [SharedMedia])
}
