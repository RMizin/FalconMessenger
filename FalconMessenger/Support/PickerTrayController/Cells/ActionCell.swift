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
  
  weak var imagePickerTrayController: ImagePickerTrayController?
  
    fileprivate let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = spacing.x/2
        
        return stackView
    }()


    var actions = [ImagePickerAction]() {
        
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
  
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
      
      addSubview(stackView)
      stackView.translatesAutoresizingMaskIntoConstraints = false
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
      stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
      stackView.widthAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
    

    @objc fileprivate func callAction(sender: UIButton) {
        if let index = stackView.arrangedSubviews.index(of: sender) {
          
          if index == 0 { /* camera */
            
            let status = cameraAccessChecking()
            
            if status {
               actions[index].call()
            } else {
              
              basicErrorAlertWith(title: basicTitleForAccessError, message: cameraAccessDeniedMessage, controller: imagePickerTrayController!)
            }
          } else {
            let status = libraryAccessChecking()
            
            if status {
              actions[index].call()
            } else {
              
              basicErrorAlertWith(title: basicTitleForAccessError, message: photoLibraryAccessDeniedMessage, controller: imagePickerTrayController!)
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
        return  CGRect(x: 0, y: -contentRect.height/2.45, width: contentRect.width, height: contentRect.height) //contentRect.divided(atDistance: contentRect.midX, from: .minYEdge ).slice
    }
    
    fileprivate override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        return contentRect.divided(atDistance: contentRect.midX, from: .minYEdge).remainder
    }
    
}
