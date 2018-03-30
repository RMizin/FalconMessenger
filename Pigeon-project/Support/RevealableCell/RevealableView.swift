//
//  RevealableView.swift
//  RevealableCell
//
//  Created by Shaps Mohsenin on 03/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

public enum RevealStyle {
    case slide
    case over
}

public enum RevealSwipeDirection {
    case left
    case right
}

open class RevealableView: UIControl {
    
    @IBInspectable open var width: CGFloat = 0 {
      didSet {
        prepareWidthConstraint()
      }
    }
    
    internal weak var tableView: UICollectionView?
    open internal(set) var reuseIdentifier: String!
    open internal(set) var style: RevealStyle = .slide
    open internal(set) var direction: RevealSwipeDirection = .left
    fileprivate var widthConstraint: NSLayoutConstraint?
    
    /**
     Ensure to call super.didMoveToSuperview in your subclasses!
     */
    open override func didMoveToSuperview() {
      if self.superview != nil {
        prepareWidthConstraint()
      }
      self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    internal func prepareForReuse() {
      tableView?.prepareRevealableViewForReuse(self)
    }
    
    fileprivate func prepareWidthConstraint() {
      if width > 0 {
        let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal,
                                            toItem: nil, attribute: .notAnAttribute,
                                            multiplier: 1, constant: width)
        NSLayoutConstraint.activate([constraint])
        widthConstraint = constraint
      } else {
        if let constraint = widthConstraint {
          NSLayoutConstraint.deactivate([constraint])
        }
      }
      setNeedsUpdateConstraints()
    }
}
