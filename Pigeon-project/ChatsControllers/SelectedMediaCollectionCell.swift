//
//  SelectedMediaCollectionCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/20/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class SelectedMediaCollectionCell: UICollectionViewCell {
  
  var image: UIImageView = {
    var image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    image.contentMode = .scaleAspectFill
    image.layer.masksToBounds = true
    image.layer.cornerRadius = 10
    image.backgroundColor = .clear
    image.isUserInteractionEnabled = true
    
    return image
  }()
  
  var remove: UIButton = {
    var remove = UIButton()
    remove.translatesAutoresizingMaskIntoConstraints = false
    remove.setImage(UIImage(named: "remove"), for: .normal)
    remove.addTarget(self, action: #selector(ChatInputContainerView.removeButtonDidTap), for: .touchUpInside)
   
    return remove
  }()
  
  let videoIndicatorView: UIImageView = {
    let videoIndicatorView = UIImageView(image: UIImage(bundledName: "ImageCell-Video"))
    videoIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    videoIndicatorView.backgroundColor = .clear
    return videoIndicatorView
  }()
  
  var isHeightCalculated: Bool = false
  
  
 override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
  
    if !isHeightCalculated {
  
      self.setNeedsLayout()
      self.layoutIfNeeded()
   
      let size = contentView.systemLayoutSizeFitting(layoutAttributes.size)
      var newFrame = layoutAttributes.frame
      newFrame.size.width = CGFloat(ceilf(Float(size.width)))
      layoutAttributes.frame = newFrame
      isHeightCalculated = true
    }
  
    return layoutAttributes
  }
  
  var isVideo = false {
    didSet {
      reloadAccessoryViews()
    }
  }
  
  fileprivate func reloadAccessoryViews() {
    videoIndicatorView.isHidden = !isVideo
  }

  override func prepareForReuse() {
    super.prepareForReuse()

      isVideo = false
  }
  
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
   
    addSubview(image)
    addSubview(remove)
    addSubview(videoIndicatorView)
  
    NSLayoutConstraint.activate([
    
      image.leadingAnchor.constraint(equalTo: leadingAnchor),
      image.topAnchor.constraint(equalTo: topAnchor),
      image.trailingAnchor.constraint(equalTo: trailingAnchor),
      image.bottomAnchor.constraint(equalTo: bottomAnchor),
      
      remove.topAnchor.constraint(equalTo: topAnchor, constant: 2),
      remove.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
      remove.widthAnchor.constraint(equalToConstant: 25),
      remove.heightAnchor.constraint(equalToConstant: 25),
      
      videoIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
      videoIndicatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
      videoIndicatorView.widthAnchor.constraint(equalToConstant: videoIndicatorView.image!.size.width),
      videoIndicatorView.heightAnchor.constraint(equalToConstant: videoIndicatorView.image!.size.height)
      
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
