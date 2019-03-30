//
//  UIIncrementSlider.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 3/3/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import UIKit


class UIIncrementSlider: UISlider {

	fileprivate var values = [Float]()
	fileprivate var lastIndex: Int? = nil
	fileprivate var dotAnchors = [NSLayoutConstraint]()
	fileprivate var callback: ((_ actualValue: Float) -> ())? = nil

	func initializeSlider(with values: [Float], currentValue: Float,  callback: @escaping (_ actualValue: Float) -> Void) {
		self.values = values
		self.callback = callback
		minimumValue = 0
		maximumValue = Float(values.count - 1)
		maximumTrackTintColor = ThemeManager.currentTheme().unselectedButtonTintColor
		minimumTrackTintColor = ThemeManager.currentTheme().tintColor

		thumbTintColor = ThemeManager.currentTheme().tintColor
		addTarget(self, action: #selector(handleValueChange(sender:)), for: .valueChanged)
		setupCurrentValue(currentValue, in: values)
		setupDots(amount: values.count)
	}

	fileprivate func setupCurrentValue(_ value: Float, in array: [Float]) {
		let currentIndex = array.firstIndex { (item) -> Bool in
			return item == value
		}
		setValue(Float(currentIndex ?? 0), animated: false)
	}

	fileprivate func setupDots(amount: Int) {
		for index in 0..<amount {
			let stepSize = (trackRect(forBounds: bounds).width - UIIncrementSliderDotView.dotSize) / CGFloat(amount - 1)
			let x = (stepSize * CGFloat(index))
			let leftDotAnchor: NSLayoutConstraint!
			let step = UIIncrementSliderDotView()

			addSubview(step)
			step.translatesAutoresizingMaskIntoConstraints = false
			step.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1).isActive = true
			leftDotAnchor = step.leftAnchor.constraint(equalTo: leftAnchor, constant: x)
			leftDotAnchor.isActive = true
			dotAnchors.append(leftDotAnchor)
			step.widthAnchor.constraint(equalToConstant: UIIncrementSliderDotView.dotSize).isActive = true
			step.heightAnchor.constraint(equalToConstant: UIIncrementSliderDotView.dotSize).isActive = true
		}
		updateColors()
	}

	fileprivate func setupFrame() {
		let stepSize = (trackRect(forBounds: bounds).width - UIIncrementSliderDotView.dotSize) / CGFloat(values.count - 1)
		for index in 0..<dotAnchors.count {
			let x = stepSize * CGFloat(index)
			dotAnchors[index].constant = x
		}
	}

	fileprivate func updateColors() {
		let tr = thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
		for subview in subviews where subview is UIIncrementSliderDotView {
			if subview.frame.origin.x >= tr.origin.x {
				subview.backgroundColor = maximumTrackTintColor
			} else {
				subview.backgroundColor = minimumTrackTintColor
			}
		}
		for state: UIControl.State in [.normal, .selected, .application, .reserved, .highlighted] {
			setThumbImage(UIImage(named: "steppedSliderThumb")?.withRenderingMode(.alwaysTemplate), for: state)
		}
	}

	@objc fileprivate func handleValueChange(sender: UISlider) {
		let newIndex = Int(sender.value + 0.5)
		setValue(Float(newIndex), animated: false)
		let didChange = lastIndex == nil || newIndex != lastIndex!
		guard didChange else { return }
		lastIndex = newIndex
		let generator = UIImpactFeedbackGenerator(style: .light)
		generator.impactOccurred()
		updateColors()
		let actualValue = values[newIndex]
		guard let callback = callback else { return }
		callback(actualValue)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		setupFrame()
		updateColors()
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateColors()
	}

	func changeTheme() {
		tintColor = ThemeManager.currentTheme().tintColor
		maximumTrackTintColor = ThemeManager.currentTheme().unselectedButtonTintColor
		minimumTrackTintColor = ThemeManager.currentTheme().tintColor
		thumbTintColor = ThemeManager.currentTheme().tintColor
		updateColors()
	}
}
