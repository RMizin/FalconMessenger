//
//  ChatLogViewControllerTitleView.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/24/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension UINavigationItem {
  
  func setTitle(title: String, subtitle: String) {
    let chatLogTitleView = ChatLogViewControllerTitleView(title: title, subtitle: subtitle)///.stackView
    let stackView = chatLogTitleView.stackView
    let stackViewFrame = chatLogTitleView.stackViewFrame()
    stackView.frame = stackViewFrame
    titleView = stackView
  }
}

class ChatLogViewControllerTitleView: UIView {

  var title: UILabel = {
    let title = UILabel()
    title.textColor = ThemeManager.currentTheme().chatLogTitleColor
    title.font = UIFont.systemFont(ofSize: 17)
    
    return title
  }()
  
  var subtitle: UILabel = {
    let subtitle = UILabel()
    subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
    subtitle.font = UIFont.systemFont(ofSize: 12)
    subtitle.textAlignment = .center
    
    return subtitle
  }()
  
  var stackView: UIStackView = {
    var stackView = UIStackView()
    stackView.distribution = .equalCentering
    stackView.axis = .vertical
    return stackView
  }()
  
  init(title: String, subtitle: String) {
   super.init(frame: .zero)
    self.title.text = title
    self.subtitle.text = subtitle
		if subtitle == statusOnline {
			self.subtitle.textColor = tintColor
		} else {
			self.subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
		}
    stackView.addArrangedSubview(self.title)
    stackView.addArrangedSubview(self.subtitle)
    self.title.sizeToFit()
    self.subtitle.sizeToFit()
  }
  
  func stackViewFrame() -> CGRect {
    let width = max(title.frame.size.width, subtitle.frame.size.width)
    return CGRect(x: 0, y: 0, width: width, height: 35)
  }
  
  func updateColors() {
    subtitle.textColor = ThemeManager.currentTheme().generalSubtitleColor
    title.textColor = ThemeManager.currentTheme().chatLogTitleColor
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
