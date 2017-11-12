//
//  BaseMessageCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/8/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class BaseMessageCell: RevealableCollectionViewCell {
  
  static let grayBubbleImage = UIImage(named: "PigeonBubbleIncomingFull")?.resizableImage(withCapInsets: UIEdgeInsetsMake(14, 22, 17, 20))
  
  static let blueBubbleImage = UIImage(named: "PigeonBubbleOutgoingFull")!.resizableImage(withCapInsets: UIEdgeInsetsMake(14, 14, 17, 28))
  
  
  let bubbleView: UIImageView = {
    let bubbleView = UIImageView()
    bubbleView.backgroundColor = UIColor.white
    bubbleView.isUserInteractionEnabled = true
    
    return bubbleView
  }()
  
  var deliveryStatus: UILabel = {
    var deliveryStatus = UILabel()
    deliveryStatus.text = "status"
    deliveryStatus.font = UIFont.boldSystemFont(ofSize: 10)
    deliveryStatus.textColor = UIColor.lightGray
    deliveryStatus.isHidden = true
    deliveryStatus.textAlignment = .right
    
    return deliveryStatus
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame.integral)
    
    setupViews()
  }
  
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  func setupViews() {
    backgroundColor = PigeonPalette.pigeonPaletteControllerBackground
    contentView.backgroundColor = PigeonPalette.pigeonPaletteControllerBackground
  }
  
  
  func prepareViewsForReuse() {}
  
  override func prepareForReuse() {
    super.prepareForReuse()
    prepareViewsForReuse()
  }
}
