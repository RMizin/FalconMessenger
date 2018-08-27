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
        
      //  initialize()
    }
    
    fileprivate func initialize() {
        addSubview(flipCameraButton)
        addSubview(shutterButtonView)
      
      flipCameraButton.translatesAutoresizingMaskIntoConstraints = false
      shutterButtonView.translatesAutoresizingMaskIntoConstraints = false
      
      flipCameraButton.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
      flipCameraButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
      flipCameraButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
      flipCameraButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
      
      
      shutterButtonView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
      shutterButtonView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
      shutterButtonView.widthAnchor.constraint(equalToConstant: 29).isActive = true
      shutterButtonView.heightAnchor.constraint(equalToConstant: 29).isActive = true
    }
    
    // MARK: - Layout
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
      
      print("\n CAMERA controller init \n")
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
     //   initialize()
    }
  
  deinit {
    print("\n CAMERA controller DE init \n")
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
