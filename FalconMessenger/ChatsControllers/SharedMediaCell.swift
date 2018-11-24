//
//  SharedMediaCell.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

class SharedMediaCell: UICollectionViewCell {

	lazy var sharedPhotoImageView: UIImageView = {
		let sharedPhotoImageView = UIImageView()
		sharedPhotoImageView.translatesAutoresizingMaskIntoConstraints = false
		sharedPhotoImageView.contentMode = .scaleAspectFill
		sharedPhotoImageView.layer.masksToBounds = true
		sharedPhotoImageView.isUserInteractionEnabled = true
	//	sharedPhotoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))

		return sharedPhotoImageView
	}()


	override init(frame: CGRect) {
		super.init(frame: frame)

		addSubview(sharedPhotoImageView)
		sharedPhotoImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
		sharedPhotoImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
		sharedPhotoImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
		sharedPhotoImageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func configureCell(sharedPhoto: SharedPhoto) {
		guard let url = sharedPhoto.imageURL else { return }

		sharedPhotoImageView.sd_imageIndicator = SDWebImageActivityIndicator()
		sharedPhotoImageView.sd_imageIndicator?.startAnimatingIndicator()

		sharedPhotoImageView.sd_setImage(with: URL(string: url), placeholderImage: nil, options: [.scaleDownLargeImages, .continueInBackground]) { (_, _, _, _) in
			self.sharedPhotoImageView.sd_imageIndicator?.stopAnimatingIndicator()
			self.sharedPhotoImageView.sd_imageIndicator = nil
		}
	}
}
