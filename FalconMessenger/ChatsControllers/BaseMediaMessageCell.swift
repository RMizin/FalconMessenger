//
//  BaseMediaMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 9/4/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

let blurredPlaceholder = blurEffect(image: UIImage(named: "blurPlaceholder")!)

class BaseMediaMessageCell: BaseMessageCell {
  
  lazy var playButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(named: "play")
    button.isHidden = true
    button.setImage(image, for: .normal)
    button.addTarget(self, action: #selector(handleZoomTap(_:)), for: .touchUpInside)
    
    return button
  }()

	lazy var loadButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		let image = UIImage(named: "download")
		button.isHidden = true
		button.setImage(image, for: .normal)
		button.addTarget(self, action: #selector(handleLoadTap), for: .touchUpInside)

		return button
	}()
  
  lazy var messageImageView: UIImageView = {
    let messageImageView = UIImageView()
    messageImageView.translatesAutoresizingMaskIntoConstraints = false
    messageImageView.layer.cornerRadius = 15
    messageImageView.layer.masksToBounds = true
    messageImageView.isUserInteractionEnabled = true
    messageImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
    
    return messageImageView
  }()
  
  lazy var progressView: CircleProgress = {
    let progressView = CircleProgress()
    progressView.translatesAutoresizingMaskIntoConstraints = false
    
    return progressView
  }()
  

	func setupImageFromURL(message: Message, indexPath: IndexPath) {
		if let localImageData = message.localImage?.imageData {
			messageImageView.image = UIImage(data: localImageData)
			messageImageView.isUserInteractionEnabled = true
			playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
			return
		}

		if let chatLogController = chatLogController, chatLogController.imagesDownloadManager.cellsWithActiveDownloads.contains(indexPath) {
			loadFullSize(message: message, messageImageUrlString: message.imageUrl, indexPath: indexPath)
			return
		}

		if message.thumbnailImageUrl != nil && message.imageUrl == nil {
			loadThumbnail(message: message, messageImageUrlString: message.thumbnailImageUrl)

		} else if message.thumbnailImageUrl == nil && message.imageUrl != nil {
			loadFullSize(message: message, messageImageUrlString: message.imageUrl, indexPath: indexPath)

		}	else if message.thumbnailImageUrl != nil && message.imageUrl != nil {


			if let urlString = message.imageUrl, let url = URL(string: urlString) {

				SDWebImageManager.shared.imageCache.containsImage(
					forKey: SDWebImageManager.shared.cacheKey(for: url),
					cacheType: SDImageCacheType.disk) { (cacheType) in
						guard cacheType == SDImageCacheType.disk || cacheType == SDImageCacheType.memory else {

							if let localImageData = message.localImage?.imageData {
								self.messageImageView.image = UIImage(data: localImageData)
								return
							}
							self.loadThumbnail(message: message, messageImageUrlString: message.thumbnailImageUrl)
							return
						}
						self.loadFullSize(message: message, messageImageUrlString: message.imageUrl, indexPath: indexPath)
				}
			}
		} else {
			self.messageImageView.image = blurredPlaceholder
		}
  }

	fileprivate func loadThumbnail(message: Message, messageImageUrlString: String?) {
		guard let urlString = messageImageUrlString, let messageImageUrl = URL(string: urlString) else { return }
		let options: SDWebImageOptions = [.continueInBackground, .scaleDownLargeImages, .avoidAutoSetImage, .highPriority]

		loadButton.isHidden = false

		if message.thumbnailImage?.imageData != nil {
			messageImageView.image = message.thumbnailImage?.uiImage()
			return
		}

		messageImageView.sd_setImage(
			with: messageImageUrl,
			placeholderImage: blurredPlaceholder,
			options: options,
			completed: { (image, error, cacheType, _) in

				guard let image = image else {
					self.messageImageView.image = blurredPlaceholder
					return
				}

				guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
					self.messageImageView.image = blurEffect(image: image)
					return
				}

				UIView.transition(with: self.messageImageView,
													duration: 0.1,
													options: .transitionCrossDissolve,
													animations: { self.messageImageView.image = blurEffect(image: image) },
													completion: nil)
		})
	}

	fileprivate func loadFullSize(message: Message, messageImageUrlString: String?, indexPath: IndexPath) {
		guard let urlString = messageImageUrlString, let messageImageUrl = URL(string: urlString) else { return }

		chatLogController?.imagesDownloadManager.addCell(at: indexPath)
		progressView.startLoading()
		progressView.isHidden = false
		loadButton.isHidden = true
		let options: SDWebImageOptions = [.continueInBackground, .scaleDownLargeImages]

		messageImageView.sd_setImage(
			with: messageImageUrl,
			placeholderImage: message.thumbnailImage?.uiImage(),
			options: options,
			progress: { (_, _, _) in
				DispatchQueue.main.async {
					self.progressView.progress = self.messageImageView.sd_imageProgress.fractionCompleted
				}
		}, completed: { (image, error, _, _) in
			if error != nil {
				self.progressView.isHidden = false
				self.messageImageView.isUserInteractionEnabled = false
				self.playButton.isHidden = true
				return
			}

			self.chatLogController?.imagesDownloadManager.removeCell(at: indexPath)
			self.progressView.isHidden = true
			self.messageImageView.isUserInteractionEnabled = true
			self.playButton.isHidden = message.videoUrl == nil && message.localVideoUrl == nil
		})
	}

  @objc func handleZoomTap(_ tapGesture: UITapGestureRecognizer) {
    guard let indexPath = chatLogController?.collectionView.indexPath(for: self) else { return }
    self.chatLogController?.handleOpen(madiaAt: indexPath)
  }

	@objc func handleLoadTap() {
		guard let indexPath = chatLogController?.collectionView.indexPath(for: self) else { return }
		guard let message = chatLogController?.groupedMessages[indexPath.section].messages[indexPath.row] else { return }
		try! RealmKeychain.defaultRealm.safeWrite {
			let thumbnailObject = RealmKeychain.defaultRealm.object(ofType: RealmImage.self, forPrimaryKey: (message.messageUID ?? "") + "thumbnail")
			let messageObject = RealmKeychain.defaultRealm.object(ofType: Message.self, forPrimaryKey: message.messageUID ?? "")

			if thumbnailObject == nil {
				let thumbnail = RealmImage(messageImageView.image ?? blurEffect(image: UIImage(named: "blurPlaceholder")!),
																		 quality: 1.0,
																		 id: (message.messageUID ?? "") + "thumbnail")
				messageObject?.thumbnailImage = thumbnail
			} else {
				messageObject?.thumbnailImage = thumbnailObject
			}
		}
		loadFullSize(message: message, messageImageUrlString: message.imageUrl, indexPath: indexPath)
	}

  override func prepareForReuse() {
    super.prepareForReuse()
    playButton.isHidden = true
		loadButton.isHidden = true
		progressView.isHidden = true
    messageImageView.sd_cancelCurrentImageLoad()
    messageImageView.image = nil
    timeLabel.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    timeLabel.textColor = ThemeManager.currentTheme().generalTitleColor
  }
}
