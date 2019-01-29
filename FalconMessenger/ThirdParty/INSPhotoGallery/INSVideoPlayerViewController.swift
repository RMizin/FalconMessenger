//
//  INSVideoPlayerViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/29/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit
import AVKit

class INSVideoPlayerViewController: AVPlayerViewController {

	override var player: AVPlayer? {
		didSet {
			player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		videoGravity = .resizeAspect
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		player?.pause()

		player?.seek(to: .zero)
		NotificationCenter.default.removeObserver(self)
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "rate" {
			if player!.rate > Float(0) {
				NotificationCenter.default.removeObserver(self)
				for subview in view.subviews where subview is INSScalingImageView {
					DispatchQueue.main.async {
						subview.removeFromSuperview()
					}
				}
			}
		}
	}
}
