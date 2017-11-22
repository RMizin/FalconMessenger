//
//  SelfSizingTextView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/22/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class SelfSizingTextView: UITextView {
  
  var preferredMaxLayoutWidth: CGFloat? {
    didSet {
      if preferredMaxLayoutWidth != oldValue {
        invalidateIntrinsicContentSize()
      }
    }
  }
  
  override var intrinsicContentSize: CGSize {
    guard isScrollEnabled, let width = preferredMaxLayoutWidth else {
      return super.intrinsicContentSize
    }
    return textSize(for: width)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    preferredMaxLayoutWidth = bounds.size.width
  }
  
  override var contentSize: CGSize {
    didSet {
      if contentSize.height <= InputContainerViewConstants.maxContainerViewHeight {
        invalidateIntrinsicContentSize()
        // This eliminates a weird UI glitch where inserting a new line sometimes causes there to be a
        // content offset when self.bounds == self.contentSize causing the text at the top to be snipped
        // and a gap at the bottom.
        setNeedsLayout()
        layoutIfNeeded()
      } else {
        setNeedsLayout()
        layoutIfNeeded()
      }
    }
  }
  
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit() {
    NotificationCenter.default.addObserver(self, selector: #selector(scrollToBottom), name: .UITextViewTextDidChange, object: nil)
  }
  
  @objc func scrollToBottom() {
    // This needs to happen so the superview updates the bounds of this text view from its new intrinsicContentSize
    // If not called, the bounds will be smaller than the contentSize at this moment, causing the guard to not be triggered.
    superview?.layoutIfNeeded()
    
    // Prevent scrolling if the textview is large enough to show all its content. Otherwise there is a jump.
    guard contentSize.height > bounds.size.height else {
      return
    }
    
    let offsetY = (contentSize.height + contentInset.top) - bounds.size.height
    UIView.animate(withDuration: 0.125) {
      self.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
    }
  }
}


extension UIEdgeInsets {
  var horizontal: CGFloat { return right + left }
  //  var vertical: CGFloat { return top + bottom }
}

extension CGSize {
  func paddedBy(_ insets: UIEdgeInsets) -> CGSize {
    return CGSize(width: width + insets.horizontal, height: height + insets.vertical)
  }
  
  var roundedUp: CGSize {
    return CGSize(width: ceil(width), height: ceil(height))
  }
}

extension UITextView {
  func textSize(for width: CGFloat) -> CGSize {
    let containerSize = CGSize(width: width - textContainerInset.horizontal,
                               height: CGFloat.greatestFiniteMagnitude)
    let container = NSTextContainer(size: containerSize)
    container.lineFragmentPadding = textContainer.lineFragmentPadding
    let storage = NSTextStorage(attributedString: attributedText)
    let layoutManager = NSLayoutManager()
    layoutManager.addTextContainer(container)
    storage.addLayoutManager(layoutManager)
    layoutManager.glyphRange(for: container)
    let rawSize = layoutManager.usedRect(for: container).size.paddedBy(textContainerInset)
    return rawSize.roundedUp
  }
}

