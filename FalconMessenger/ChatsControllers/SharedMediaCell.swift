//
//  SharedMediaCell.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 11/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
//import SDWebImage

class SharedMediaCell: UICollectionViewCell {

	lazy var playButton: UIImageView = {
		let button = UIImageView()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.contentMode = .scaleAspectFit
		button.isUserInteractionEnabled = false
		button.isHidden = true
		button.image = UIImage(named: "play")

		return button
	}()

	lazy var sharedPhotoImageView: UIImageView = {
		let sharedPhotoImageView = UIImageView()
		sharedPhotoImageView.translatesAutoresizingMaskIntoConstraints = false
		sharedPhotoImageView.contentMode = .scaleAspectFill
		sharedPhotoImageView.layer.masksToBounds = true
		sharedPhotoImageView.isUserInteractionEnabled = true
		sharedPhotoImageView.sd_imageIndicator = ThemeManager.currentTheme().sdWebImageActivityIndicator
		sharedPhotoImageView.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
		return sharedPhotoImageView
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)

		contentView.addSubview(sharedPhotoImageView)
		contentView.addSubview(playButton)
		sharedPhotoImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
		sharedPhotoImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
		if #available(iOS 11.0, *) {
			sharedPhotoImageView.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor).isActive = true
			sharedPhotoImageView.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor).isActive = true
		} else {
			sharedPhotoImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
			sharedPhotoImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
		}

		playButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
		playButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
		playButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
		playButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func configureCell(sharedElement: SharedMedia) {
		guard var url = sharedElement.imageURL else { return }

		if let thumbnailURL = sharedElement.thumbnailImageUrl {
			url = thumbnailURL
		}
		
		sharedPhotoImageView.sd_setImage(with: URL(string: url), placeholderImage: nil, options: [.scaleDownLargeImages, .continueInBackground, .highPriority]) { (image, error, _, _) in
			if error != nil {
				self.playButton.isHidden = true
				return
			}
			if sharedElement.videoURL != nil {
				self.playButton.isHidden = false
			}
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		sharedPhotoImageView.image = nil
		sharedPhotoImageView.sd_cancelCurrentImageLoad()
		playButton.isHidden = true
	}
}
