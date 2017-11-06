//
//  ActionCell.swift
//  ImagePickerTrayController
//
//  Created by Laurin Brandner on 22.11.16.
//  Copyright © 2016 Laurin Brandner. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos

let spacing = CGPoint(x: 26, y: 14)
fileprivate let stackViewOffset: CGFloat = 6

class ActionCell: UICollectionViewCell {
  
  weak var imagePickerTrayController:ImagePickerTrayController?
  
  fileprivate func basicErrorAlertWith (title:String, message: String) {
    
   
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
    imagePickerTrayController?.present(alert, animated: true, completion: nil)
  }
  
  

    fileprivate let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = spacing.x/2
        
        return stackView
    }()

    fileprivate let chevronImageView: UIImageView = {
        let bundle = Bundle(for: ImagePickerTrayController.self)
        let image = UIImage(named: "ActionCell-Chevron", in: bundle, compatibleWith: nil)
        let imageView = UIImageView(image: image)
        imageView.alpha = 0.5

        return imageView
    }()

    var actions = [ImagePickerAction]() {
        // It is sufficient to compare the length of the array
        // as actions can only be added but not removed
        
        willSet {
            if newValue.count != actions.count {
                stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            }
        }
        didSet {
            if stackView.arrangedSubviews.count != actions.count {
                actions.map { ActionButton(action: $0, target: self, selector: #selector(callAction(sender:))) }
                       .forEach { stackView.addArrangedSubview($0) }
            }
        }
    }
    
    var disclosureProcess: CGFloat = 0 {
        didSet {
            setNeedsLayout()
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
        contentView.addSubview(stackView)
        contentView.addSubview(chevronImageView)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let progress = max(disclosureProcess, 0)
        stackView.frame = bounds.insetBy(dx: spacing.x, dy: spacing.y).offsetBy(dx: -progress * stackViewOffset, dy: 0)
        
        chevronImageView.alpha = progress/2
        
        let chevronOffset = (1-progress) * (spacing.x + stackViewOffset)
        let chevronCenterX = max(bounds.maxX - spacing.x/2 + chevronOffset, stackView.frame.maxX + spacing.x/2)
        chevronImageView.center = CGPoint(x: chevronCenterX, y: bounds.midY)
    }
    

    @objc fileprivate func callAction(sender: UIButton) {
        if let index = stackView.arrangedSubviews.index(of: sender) {
          
          if index == 0 { /* camera */
            
            let status = cameraAccessChecking()
            
            if status {
               actions[index].call()
            } else {
              
              basicErrorAlertWith(title: basicTitleForAccessError, message: cameraAccessDeniedMessage)
            }
          } else {
            let status = libraryAccessChecking()
            
            if status {
              actions[index].call()
            } else {
              
              basicErrorAlertWith(title: basicTitleForAccessError, message: photoLibraryAccessDeniedMessage)
            }
          }
       }
    }
}


fileprivate class ActionButton: UIButton {
    
    // MARK: - Initialization
    
    init(action: ImagePickerAction, target: Any, selector: Selector) {
        super.init(frame: .zero)
        
        setTitle(action.title, for: .normal)
        setTitleColor(.black, for: .normal)
        setImage(action.image.withRenderingMode(.alwaysTemplate), for: .normal)
        
        imageView?.tintColor = .black
        imageView?.contentMode = .bottom
        
        titleLabel?.textAlignment = .center
        titleLabel?.font = .systemFont(ofSize: 14)
        
        backgroundColor = .white
        layer.masksToBounds = true
        layer.cornerRadius = 11.0
        addTarget(target, action: selector, for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    fileprivate override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        return contentRect.divided(atDistance: contentRect.midX, from: .minYEdge).slice
    }
    
    fileprivate override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        return contentRect.divided(atDistance: contentRect.midX, from: .minYEdge).remainder
    }
    
}
