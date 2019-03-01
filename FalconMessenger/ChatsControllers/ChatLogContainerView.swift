//
//  ChatLogContainerView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ChatLogContainerView: UIView {

  let backgroundView: UIView = {
    let backgroundView = UIView()
    backgroundView.translatesAutoresizingMaskIntoConstraints = false

    return backgroundView
  }()

	let inputContainerSafeAreaView: UIView = {
		let inputContainerSafeAreaView = UIView()
		inputContainerSafeAreaView.translatesAutoresizingMaskIntoConstraints = false
		inputContainerSafeAreaView.backgroundColor = ThemeManager.currentTheme().barBackgroundColor

		return inputContainerSafeAreaView
	}()
  
  let collectionViewContainer: UIView = {
    let collectionViewContainer = UIView()
    collectionViewContainer.translatesAutoresizingMaskIntoConstraints = false
    
    return collectionViewContainer
  }()
  
  let inputViewContainer: UIView = {
    let inputViewContainer = UIView()
    inputViewContainer.translatesAutoresizingMaskIntoConstraints = false
    
    return inputViewContainer
  }()
  
  fileprivate var bottomConstraint: NSLayoutConstraint!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(backgroundView)
    addSubview(collectionViewContainer)
		addSubview(inputContainerSafeAreaView)
    addSubview(inputViewContainer)

    backgroundView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    backgroundView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    backgroundView.topAnchor.constraint(equalTo: inputViewContainer.bottomAnchor).isActive = true
    
    collectionViewContainer.topAnchor.constraint(equalTo: topAnchor).isActive = true
    if #available(iOS 11.0, *) {
      collectionViewContainer.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
      collectionViewContainer.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
    } else {
      collectionViewContainer.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
      collectionViewContainer.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }

    if #available(iOS 11.0, *) {
      inputViewContainer.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
      inputViewContainer.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
    } else {
      inputViewContainer.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
      inputViewContainer.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    inputViewContainer.topAnchor.constraint(equalTo: collectionViewContainer.bottomAnchor).isActive = true
    
    bottomConstraint = inputViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor)

		inputContainerSafeAreaView.topAnchor.constraint(equalTo: inputViewContainer.topAnchor).isActive = true
		inputContainerSafeAreaView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
		inputContainerSafeAreaView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
		inputContainerSafeAreaView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func blockBottomConstraint(constant: CGFloat) {
    bottomConstraint.constant = constant
    bottomConstraint.isActive = true
  }
  
  func unblockBottomConstraint() {
    bottomConstraint.isActive = false
  }
  
  func add(_ collectionView: UICollectionView) {
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionViewContainer.addSubview(collectionView)
    collectionView.topAnchor.constraint(equalTo: collectionViewContainer.topAnchor).isActive = true
    collectionView.leftAnchor.constraint(equalTo: collectionViewContainer.leftAnchor).isActive = true
    collectionView.rightAnchor.constraint(equalTo: collectionViewContainer.rightAnchor).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: collectionViewContainer.bottomAnchor).isActive = true
  }
  
  func add(_ inputView: UIView) {

    for subview in inputViewContainer.subviews
      where subview is InputContainerView || subview is InputBlockerContainerView {
      subview.removeFromSuperview()
    }

    inputView.translatesAutoresizingMaskIntoConstraints = false
    inputViewContainer.addSubview(inputView)
    inputView.topAnchor.constraint(equalTo: inputViewContainer.topAnchor).isActive = true
    inputView.leftAnchor.constraint(equalTo: inputViewContainer.leftAnchor).isActive = true
    inputView.rightAnchor.constraint(equalTo: inputViewContainer.rightAnchor).isActive = true
    inputView.bottomAnchor.constraint(equalTo: inputViewContainer.bottomAnchor).isActive = true
  }
}
