//
//  AnimationController.swift
//  ImagePickerTrayController
//
//  Created by Laurin Brandner on 15.04.17.
//  Copyright © 2017 Laurin Brandner. All rights reserved.
//

import UIKit

final class AnimationController: NSObject {

	fileprivate let transition: Transition

	enum Transition {
		case presentation(UIPanGestureRecognizer)
		case dismissal
	}

	init(transition: Transition) {
		self.transition = transition
		super.init()
		print("\n animation controller init \n")
	}

	deinit {
		print("\n animation controller DE init \n")
	}
}

extension AnimationController: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch transition {
        case .presentation(let gestureRecognizer):
            present(with: gestureRecognizer, using: transitionContext)
        case .dismissal:
            dismiss(using: transitionContext)
        }
    }
    
    private func present(with gestureRecognizer: UIPanGestureRecognizer, using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to) as? ImagePickerTrayController else {
            transitionContext.completeTransition(false)
            return
        }
        
        let container = transitionContext.containerView
        container.window?.addGestureRecognizer(gestureRecognizer)
        
        container.addSubview(to.view)
        container.frame = CGRect(x: 0, y: container.bounds.height-to.collectionView.frame.height, width: container.bounds.width, height: to.collectionView.frame.height)
        to.view.transform = CGAffineTransform(translationX: 0, y: to.collectionView.frame.height)
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
            to.view.transform = .identity
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    private func dismiss(using transitionContext: UIViewControllerContextTransitioning) {
        guard let from = transitionContext.viewController(forKey: .from) as? ImagePickerTrayController else {
                transitionContext.completeTransition(false)
                return
        }
        
        let duration = transitionDuration(using: transitionContext)
        //from.heig heightConstraint?.constant = 0
        UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
           // from.view.frame.origin.y += from.collectionView.frame.height
          from.view.layoutIfNeeded()
        }, completion: { _ in
            if !transitionContext.transitionWasCancelled {
//                from.view.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
}
