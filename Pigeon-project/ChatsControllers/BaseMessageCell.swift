//
//  BaseMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class BaseMessageCell: RevealableCollectionViewCell {
  
  weak var message: Message?
  weak var chatLogController: ChatLogController?
  
  let grayBubbleImage = ThemeManager.currentTheme().incomingBubble
  let blueBubbleImage = ThemeManager.currentTheme().outgoingBubble
  static let selectedOutgoingBubble = UIImage(named: "OutgoingSelected")!.resizableImage(withCapInsets: UIEdgeInsetsMake(14, 14, 17, 28))
  static let selectedIncomingBubble = UIImage(named: "IncomingSelected")!.resizableImage(withCapInsets: UIEdgeInsetsMake(14, 22, 17, 20))
  
  static let incomingTextViewTopInset:CGFloat = 10
  static let incomingTextViewBottomInset:CGFloat = 10
  static let incomingTextViewLeftInset:CGFloat = 12
  static let incomingTextViewRightInset:CGFloat = 7
  
  let bubbleView: UIImageView = {
    let bubbleView = UIImageView()
    bubbleView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    bubbleView.isUserInteractionEnabled = true
    
    return bubbleView
  }()
  
  var deliveryStatus: UILabel = {
    var deliveryStatus = UILabel()
    deliveryStatus.text = "status"
    deliveryStatus.font = UIFont.boldSystemFont(ofSize: 10)
    deliveryStatus.textColor =  ThemeManager.currentTheme().generalSubtitleColor
    deliveryStatus.isHidden = true
    deliveryStatus.textAlignment = .right
    
    return deliveryStatus
  }()
  
  let nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.font = UIFont.systemFont(ofSize: 13)
    nameLabel.numberOfLines = 1
    nameLabel.backgroundColor = .clear
    nameLabel.textColor = FalconPalette.defaultBlue
    
    return nameLabel
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame.integral)
    
    setupViews()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setupViews() {
    backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    contentView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  func prepareViewsForReuse() {}
  
  override func prepareForReuse() {
    super.prepareForReuse()
    prepareViewsForReuse()
  }
}
