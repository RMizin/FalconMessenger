//
//  FalconUISlider.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/31/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class FalconUISlider: UISlider {
	override func trackRect(forBounds bounds: CGRect) -> CGRect {
		let customBounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width, height: 5.0))
		super.trackRect(forBounds: customBounds)
		return customBounds
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		thumbTintColor = .white
		minimumTrackTintColor = .white
		setThumbImage(UIImage(named: "sliderThumb"), for: .normal)
		setThumbImage(UIImage(named: "sliderThumb"), for: .highlighted)
		translatesAutoresizingMaskIntoConstraints = false
		layer.cornerRadius = 10
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
