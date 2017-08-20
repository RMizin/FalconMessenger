//
//  CameraOverlayView.swift
//  ImagePickerTrayController
//
//  Created by Laurin Brandner on 26.11.16.
//  Copyright © 2016 Laurin Brandner. All rights reserved.
//

import UIKit

class CameraOverlayView: UIButton {
    
    let flipCameraButton: UIButton = {
        let button = FlipCameraButton()
        button.setImage(UIImage(bundledName: "CameraOverlayView-CameraFlip"), for: .normal)
        
        return button
    }()
    
    fileprivate let shutterButtonView = ShutterButtonView()
    
    override var isHighlighted: Bool {
        didSet {
            shutterButtonView.isHighlighted = isHighlighted
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    fileprivate func initialize() {
        addSubview(flipCameraButton)
        addSubview(shutterButtonView)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let flipCameraButtonSize = CGSize(width: 44, height: 44)
        let flipCameraButtonOrigin = CGPoint(x: bounds.maxX - flipCameraButtonSize.width, y: bounds.minY)
        flipCameraButton.frame = CGRect(origin: flipCameraButtonOrigin, size: flipCameraButtonSize)
        
        let shutterButtonViewSize = CGSize(width: 29, height: 29)
        let shutterButtonViewOrigin = CGPoint(x: bounds.midX - shutterButtonViewSize.width/2, y: bounds.maxY - shutterButtonViewSize.height-4)
        shutterButtonView.frame = CGRect(origin: shutterButtonViewOrigin, size: shutterButtonViewSize)
    }
    
}

fileprivate class FlipCameraButton: UIButton {
    
    fileprivate override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageSize = super.imageRect(forContentRect: contentRect).size
        let imageOrigin = CGPoint(x: contentRect.maxX-imageSize.width-10, y: contentRect.minY+10)
        
        return CGRect(origin: imageOrigin, size: imageSize)
    }
    
}

fileprivate class ShutterButtonView: UIView {
    
    let bezelLayer: CALayer = {
        let layer = CALayer()
        layer.masksToBounds = true
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
        
        return layer
    }()
    
    let knobLayer: CALayer = {
        let layer = CALayer()
        layer.masksToBounds = true
        layer.backgroundColor = UIColor.white.cgColor
        
        return layer
    }()
    
    var isHighlighted = false {
        didSet {
            knobLayer.backgroundColor = (isHighlighted) ? UIColor.lightGray.cgColor : UIColor.white.cgColor
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    fileprivate func initialize() {
        layer.addSublayer(bezelLayer)
        layer.addSublayer(knobLayer)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bezelLayer.frame = bounds
        bezelLayer.cornerRadius = bounds.width/2
        
        let knobInset = bezelLayer.borderWidth + 1.5
        knobLayer.frame = bounds.insetBy(dx: knobInset, dy: knobInset)
        knobLayer.cornerRadius = knobLayer.bounds.height/2
    }
    
}
