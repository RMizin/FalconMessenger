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

	override func viewDidLoad() {
		super.viewDidLoad()
		showsPlaybackControls = false
		view.backgroundColor = .clear
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		player?.pause()
		player?.seek(to: .zero)
	}
}
