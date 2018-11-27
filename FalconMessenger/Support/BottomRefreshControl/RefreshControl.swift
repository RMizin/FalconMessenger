//
// RefreshControl.swift
//
// Copyright (c) 2015 Jerry Wong
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public protocol AnyRefreshContext : NSObjectProtocol where ContentType : AnyRefreshContent {
    
    associatedtype ContentType
    
    var contentView: ContentType { get }
    
    var state: PullRefreshState { get set }
}

public protocol RefreshControl {
    
    func startLoading()
    
    func stopLoading()
    
    func loadedSuccess(withDelay: TimeInterval?)
    
    func loadedPause(withMsg msg: String)
    
    func loadedError(withMsg msg: String)
    
}

public extension RefreshControl where Self : AnyRefreshContext {
    
    public func loadedPause(withMsg msg: String) {
			self.contentView.loadedPause?(withMsg: msg)
			self.state = .pause
    }
    
    public func loadedError(withMsg msg: String) {
			self.contentView.loadedError?(withMsg: msg)
			self.state = .pause
    }
    
    public func startLoading() {
			self.state = .refreshing
    }
    
    public func stopLoading() {
			self.state = .idle
    }
    
    public func loadedSuccess(withDelay: TimeInterval? = 0.6) {
			self.contentView.loadedSuccess?()
			DispatchQueue.main.asyncAfter(deadline: .now() + (withDelay ?? 0.6)) {[weak self] in
				self?.state = .idle
			}
    }
}

open class RefreshFooterControl<T>: UIView , AnyRefreshContext, RefreshControl where T: AnyRefreshContent, T: UIView {
    
	open var state = PullRefreshState.idle {
		didSet {
			if state != oldValue {
				self.updateContentViewByStateChanged()
			}
		}
	}
    
	open var refreshingBlock: ((RefreshFooterControl<T>) -> ())?

	open var preFetchedDistance: CGFloat = 0
    
  public let contentView = T.init()
    
    public override init(frame: CGRect) {
			super.init(frame: frame)
			self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
			super.init(coder: aDecoder)
			self.setup()
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
			super.willMove(toSuperview: newSuperview)
			guard let scrollView = newSuperview as? UIScrollView else {
				return
			}
			self.contentView.frame = CGRect.init(x: 0, y: 0, width: scrollView.frame.size.width, height: T.preferredHeight)
			self.scrollView = scrollView
			scrollView.alwaysBounceVertical = true
			self.scrollViewContentSize = scrollView.contentSize
			self.registKVO()
    }
    
    private func removeKVO() {
			self.keyPathObservations = []
			self.scrollView = nil
    }
    
    private func registKVO() {
        guard let scrollView = self.scrollView else {
					return
        }
        
        var observations: [NSKeyValueObservation] = []
        observations.append(
					scrollView.observe(\.contentSize, changeHandler: { [weak self] (scrollView, change) in
						self?.scrollViewContentSize = scrollView.contentSize
					})
        )
        
        observations.append(
					scrollView.observe(\.contentOffset, changeHandler: { [weak self] (scrollView, change) in
						self?.scrollViewContentOffsetDidChange()
					})
        )
        self.keyPathObservations = observations
    }
    
    private func setup() {
			self.autoresizingMask = .flexibleWidth
			self.clipsToBounds = true
			self.addSubview(self.contentView)

      if #available(iOS 9.0, *) {
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.contentView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.contentView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
      }
      
			self.isHidden = true
    }
    
    private func scrollViewContentOffsetDidChange() {
			guard let scrollView = self.scrollView else {
				return
			}
			var offsetSpace = -self.preFetchedDistance
			if #available(iOS 11.0, *) {
				offsetSpace += scrollView.adjustedContentInset.bottom
			}

			if self.state != .pause &&
				scrollView.contentSize.height > 0 &&
				scrollView.contentSize.height >= scrollView.frame.size.height &&
				scrollView.contentOffset.y + scrollView.frame.size.height - scrollView.contentSize.height > offsetSpace {
				self.state = .refreshing
				self.frame = CGRect.init(x: 0, y: scrollView.contentSize.height, width: scrollView.frame.size.width, height: self.contentView.frame.size.height)
			}
    }
    
    private func updateContentViewByStateChanged() {
        guard let scrollView = self.scrollView else {
					return
        }
        
        switch self.state {
        case .idle:
					UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
						self.alpha = 0
					}, completion: { _ in
						self.isHidden = true
						self.alpha = 1
					})

          //  self.isHidden = true
            self.contentView.stopLoading?()
            if scrollView.contentInset.bottom >= self.contentView.frame.size.height {
							var oldInsets = scrollView.contentInset
							oldInsets.bottom -= self.contentView.frame.size.height
							UIView.animate(withDuration: 0.2) {
								scrollView.contentInset = oldInsets
							}

            }
        case .refreshing:
            var oldInsets = scrollView.contentInset
            oldInsets.bottom += self.contentView.frame.size.height
            scrollView.contentInset = oldInsets
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                self.refreshingBlock?(self)
            })
            self.isHidden = false
            self.contentView.startLoading?()
        default:
            break
        }
    }
    
    private weak var scrollView: UIScrollView?
    
    private var scrollViewContentSize = CGSize.zero {
			didSet {
				if scrollViewContentSize != oldValue && self.state != .refreshing {
					self.frame = CGRect.init(x: 0, y: scrollViewContentSize.height, width: self.scrollView?.frame.size.width ?? 0, height: self.contentView.frame.size.height)
				}
			}
    }
    
    private var keyPathObservations: [NSKeyValueObservation] = []
}
