//
//  TransitionBackgrounView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 1/31/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit

class TransitionBackgrounView: UIView {

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .black
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
