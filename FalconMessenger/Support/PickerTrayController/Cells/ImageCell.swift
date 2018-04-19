//
//  ImageCell.swift
//  ImagePickerTrayController
//
//  Created by Laurin Brandner on 15.10.16.
//  Copyright © 2016 Laurin Brandner. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        
        return imageView
    }()
    
    fileprivate let shadowView = UIImageView(image: UIImage(bundledName: "ImageCell-Shadow"))
    
    fileprivate let videoIndicatorView = UIImageView(image: UIImage(bundledName: "ImageCell-Video"))
    
    fileprivate let cloudIndicatorView = UIImageView(image: UIImage(bundledName: "ImageCell-Cloud"))
    
    fileprivate let checkmarkView = UIImageView(image: UIImage(bundledName: "ImageCell-Selected"))
  
  //  fileprivate let checkmarkViewUnselected = UIImageView(image: UIImage(bundledName: "ImageCell-Unselected"))
   //ImageCell-Unselected
    var isVideo = false {
        didSet {
            reloadAccessoryViews()
        }
    }
    
    var isRemote = false {
        didSet {
            reloadAccessoryViews()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            reloadCheckmarkView()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
       // initialize()
    }
    
    fileprivate func initialize() {
        contentView.addSubview(imageView)
        //contentView.addSubview(shadowView)
        contentView.addSubview(videoIndicatorView)
        contentView.addSubview(cloudIndicatorView)
        contentView.addSubview(checkmarkView)
      //  contentView.addSubview(checkmarkViewUnselected)
        
        reloadAccessoryViews()
        reloadCheckmarkView()
    }
    
    // MARK: - Other Methods
    
    fileprivate func reloadAccessoryViews() {
        videoIndicatorView.isHidden = !isVideo
        cloudIndicatorView.isHidden = !isRemote
        shadowView.isHidden = videoIndicatorView.isHidden && cloudIndicatorView.isHidden
    }
    
    fileprivate func reloadCheckmarkView() {
        checkmarkView.isHidden = !isSelected
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        isVideo = false
        isRemote = false
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = bounds
        let inset: CGFloat = 8
        
      //  let shadowHeight = shadowView.image?.size.height ?? 0
       // shadowView.frame = CGRect(origin: CGPoint(x: bounds.minX, y: bounds.maxY-shadowHeight), size: CGSize(width: bounds.width, height: shadowHeight))
        
        let videoIndicatorViewSize = videoIndicatorView.image?.size ?? .zero
        let videoIndicatorViewOrigin = CGPoint(x: bounds.minX + inset, y: bounds.maxY - inset - videoIndicatorViewSize.height)
        videoIndicatorView.frame = CGRect(origin: videoIndicatorViewOrigin, size: videoIndicatorViewSize)
        
        let cloudIndicatorViewSize = cloudIndicatorView.image?.size ?? .zero
        let cloudIndicatorViewOrigin = CGPoint(x: bounds.maxX - inset - cloudIndicatorViewSize.width, y: bounds.maxY - inset - cloudIndicatorViewSize.height)
        cloudIndicatorView.frame = CGRect(origin: cloudIndicatorViewOrigin, size: cloudIndicatorViewSize)
        
        let checkmarkSize = checkmarkView.frame.size
        checkmarkView.center = CGPoint(x: bounds.maxX-checkmarkSize.width/2-4, y: bounds.maxY-checkmarkSize.height/2-4)
       // checkmarkViewUnselected.center = CGPoint(x: bounds.maxX-checkmarkSize.width/2-4, y: bounds.maxY-checkmarkSize.height/2-4)
    }
    
}
