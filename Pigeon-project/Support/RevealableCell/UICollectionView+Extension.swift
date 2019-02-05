//
//  UICollectionView+Extension.swift
//  RevealableCell
//
//  Created by Shaps Mohsenin on 03/01/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import ObjectiveC

struct AssociationKey {
    static var queues: UInt8 = 1
    static var registrations: UInt8 = 2
    static var panGesture: UInt8 = 3
}

extension UICollectionView: UIGestureRecognizerDelegate {
    
    fileprivate static var currentOffset: CGFloat = 0
    fileprivate static var translationX: CGFloat = 0
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &AssociationKey.panGesture && keyPath == "contentOffset" {
            updateTableViewCellFrames()
            return
        }
        
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
    fileprivate func updateTableViewCellFrames() {
        for cell in visibleCells {
            if let revealCell = cell as? RevealableCollectionViewCell {
                if let revealView = revealCell.revealView {
                    var rect = cell.contentView.frame
                    var x = UICollectionView.currentOffset
                    
                    if revealView.direction == .left {
                        x = max(x, -revealView.bounds.width)
                        x = min(x, 0)
                    } else {
                        x = max(x, 0)
                        x = min(x, revealView.bounds.width)
                    }
                    
                    if revealView.style == .slide {
                        rect.origin.x = x;
                        cell.contentView.frame = rect;
                    }
                    
                    revealView.transform = CGAffineTransform(translationX: x, y: 0)
                }
            }
        }
    }
  
    @objc func handleRevealPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
         
            addObserver(self, forKeyPath: "contentOffset", options: .new, context: &AssociationKey.panGesture)
            break
        case .changed:
        
          UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            UICollectionView.translationX = gesture.translation(in: gesture.view).x
            UICollectionView.currentOffset += UICollectionView.translationX
            
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
            
            self.updateTableViewCellFrames()
         
          }, completion: { (true) in
            
          })
          
            break
        default:
          
          UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
            UICollectionView.currentOffset = 0
            self.updateTableViewCellFrames()
          }, completion: { (finished: Bool) in
             UICollectionView.translationX = 0
          })

          
            removeObserver(self, forKeyPath: "contentOffset")
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return  false//[gestureRecognizer, otherGestureRecognizer].contains(revealPanGesture)
    }
    
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? UIPanGestureRecognizer, gesture == revealPanGesture {
            let translation = gesture.translation(in: gesture.view);
					return (abs(translation.x) > abs(translation.y)) && (gesture == revealPanGesture)
        }
        
        return true
    }
    
    fileprivate var revealPanGesture: UIPanGestureRecognizer {
        return objc_getAssociatedObject(self, &AssociationKey.panGesture) as? UIPanGestureRecognizer ?? {
            let associatedProperty = UIPanGestureRecognizer(target: self, action: #selector(UICollectionView.handleRevealPan(_:)))
            associatedProperty.delegate = self
            objc_setAssociatedObject(self, &AssociationKey.panGesture, associatedProperty, .OBJC_ASSOCIATION_RETAIN)
            return associatedProperty
            }()
    }
    
    fileprivate var registrations: NSMutableDictionary {
        return objc_getAssociatedObject(self, &AssociationKey.registrations) as? NSMutableDictionary ?? {
            let associatedProperty = NSMutableDictionary()
            objc_setAssociatedObject(self, &AssociationKey.registrations, associatedProperty, .OBJC_ASSOCIATION_RETAIN)
            return associatedProperty
            }()
    }
    
    fileprivate var reuseQueues: RevealableViewsReuseQueues {
        return objc_getAssociatedObject(self, &AssociationKey.queues) as? RevealableViewsReuseQueues ?? {
            let associatedProperty = RevealableViewsReuseQueues()
            objc_setAssociatedObject(self, &AssociationKey.queues, associatedProperty, .OBJC_ASSOCIATION_RETAIN)
            return associatedProperty
            }()
    }
    
    public func registerNib(_ nib: UINib, forRevealableViewReuseIdentifier identifier: String) {
        let regs = registrations
        
        guard regs[identifier] == nil else {
            print("A revealableView with the identifier '\(identifier)' already exists -- '\(String(describing: regs[identifier]))'")
            return
        }
        
        regs[identifier] = nib
    }
    
    public func registerClass(revealableViewClass viewClass: AnyClass, forRevealableViewReuseIdentifier identifier: String) {
        let regs = registrations
        
        guard regs[identifier] == nil else {
            print("A revealableView with the identifier '\(identifier)' already exists -- '\(String(describing: regs[identifier]))'")
            return
        }
        
        guard viewClass is RevealableView.Type else {
            print("The viewClass '\(viewClass)' is not a subclass of RevealableView!")
            return
        }
        
        regs[identifier] = viewClass
    }
    
    public func dequeueReusableRevealableView(withIdentifier identifier: String) -> RevealableView? {
        let queue = reuseQueues.queueForIdentifier(identifier)
      
        if let view = queue.dequeueView() {
            return view
        }
      
        let regs = registrations
        
        if let nib = regs[identifier] as? UINib {
            guard let view = nib.instantiate(withOwner: nil, options: nil).first as? RevealableView else {
                print("The view returned from NIB: '\(nib)' is not a subclass of RevealableView!")
                return nil
            }
            
            view.reuseIdentifier = identifier
            view.tableView = self
            
            addGestureRecognizer(revealPanGesture)
            return view
        }
        
        if let viewClass = regs[identifier] as? NSObject.Type {
            guard let view = viewClass.init() as? RevealableView  else {
                print("The view instantiated from Class: '\(viewClass)' is not a subclass of RevealableView!")
                return nil
            }
            
            view.reuseIdentifier = identifier
            view.tableView = self
            
            addGestureRecognizer(revealPanGesture)
            return view
        }
        
        return nil
    }
    
    internal func prepareRevealableViewForReuse(_ view: RevealableView) {
        view.removeFromSuperview()
       
        let queue = reuseQueues.queueForIdentifier(view.reuseIdentifier)
        queue.enqueue(view)
    }
    
}

private final class RevealableViewsReuseQueues: NSObject {
    
    fileprivate var queues: [String: RevealableViewsReuseQueue]
    
    fileprivate func queueForIdentifier(_ identifier: String) -> RevealableViewsReuseQueue {
        var queue = queues[identifier]
        
        if queue == nil {
            queue = RevealableViewsReuseQueue(identifier: identifier)
            queues[identifier] = queue
        }
        
        return queue!
    }
    
    override init() {
        queues = [String: RevealableViewsReuseQueue]()
    }
    
}

private final class RevealableViewsReuseQueue: NSObject {
    
    fileprivate var identifier: String
    fileprivate var views = [RevealableView]()
    
    fileprivate init(identifier: String) {
        self.identifier = identifier
    }
    
    fileprivate func enqueue(_ view: RevealableView) {
        views.append(view)
    }
    
    fileprivate func dequeueView() -> RevealableView? {
        guard views.count > 0 else {
            return nil
        }
        
        let view = views.first
        views.removeFirst()
        
        return view
    }
    
}
