//
//  RevealableCollectionViewCell
//  RevealableCell
//
//  Created by Shaps Mohsenin on 03/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

open class RevealableCollectionViewCell: UICollectionViewCell {
    
  var horizontalConstraint: NSLayoutConstraint?
  var revealView: RevealableView?
  var revealWidth: CGFloat = 0
    
  open override var isSelected: Bool {
      didSet {
          revealView?.isSelected = isSelected
      }
  }
  
  open override var isHighlighted: Bool {
    didSet {
      revealView?.isHighlighted = isHighlighted
    }
  }
    
  /**
   Ensure you call super.prepareForReuse() when overriding this method in your subclasses!
   */
  open override func prepareForReuse() {
    super.prepareForReuse()
  
    if let view = revealView {
      view.prepareForReuse()
    }
  }
  
  open func setRevealableView(_ view: RevealableView,
                              style: RevealStyle = .slide, direction: RevealSwipeDirection = .left) {
    if let view = revealView {
      view.removeFromSuperview()
    }
  
    revealView = view
    view.style = style
    view.direction = direction
  
    view.sizeToFit()
    addSubview(view)
  
    let topConstraint = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal,
                                           toItem: self, attribute: .top, multiplier: 1, constant: 0)
    let bottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal,
                                              toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
  
		let viewAttribute: NSLayoutConstraint.Attribute = direction == .left ? .left : .right
		let parentAttribute: NSLayoutConstraint.Attribute = direction == .left ? .right : .left
    let horizontalConstraint = NSLayoutConstraint(item: view, attribute: viewAttribute, relatedBy: .equal,
                                                  toItem: self, attribute: parentAttribute, multiplier: 1, constant: 0)
    self.horizontalConstraint = horizontalConstraint
  
    NSLayoutConstraint.activate([ topConstraint, bottomConstraint, horizontalConstraint ])
  }
}
