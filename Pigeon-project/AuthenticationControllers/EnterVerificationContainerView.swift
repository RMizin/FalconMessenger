//
//  EnterVerificationContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/3/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

class EnterVerificationContainerView: UIView {

  
  let titleNumber: UILabel = {
    let titleNumber = UILabel()
    titleNumber.translatesAutoresizingMaskIntoConstraints = false
    titleNumber.textAlignment = .center
    titleNumber.font = UIFont.systemFont(ofSize: 32)
    
    return titleNumber
  }()
  
  let subtitleText: UILabel = {
    let subtitleText = UILabel()
    subtitleText.translatesAutoresizingMaskIntoConstraints = false
    subtitleText.font = UIFont.systemFont(ofSize: 15)
    subtitleText.textAlignment = .center
    subtitleText.text = "We have sent you an SMS with the code"
    
    return subtitleText
  }()
  
  let verificationCode: UITextField = {
    let verificationCode = UITextField()
    verificationCode.font = UIFont.systemFont(ofSize: 20)
    verificationCode.translatesAutoresizingMaskIntoConstraints = false
    verificationCode.textAlignment = .center
    verificationCode.keyboardType = .numberPad
    verificationCode.placeholder = "Code"
    verificationCode.borderStyle = .roundedRect
    //verificationCode.addTarget(self, action: #selector(EnterPhoneNumberController.textFieldDidChange(_:)), for: .editingChanged)
    
    return verificationCode
  }()
  
  let resend: UIButton = {
    let resend = UIButton()
    resend.translatesAutoresizingMaskIntoConstraints = false
    resend.setTitle("Resend", for: .normal)
    resend.contentVerticalAlignment = .center
    resend.contentHorizontalAlignment = .center
    resend.setTitleColor(PigeonPalette.pigeonPaletteBlue, for: .normal)
    resend.setTitleColor(PigeonPalette.pigeonPaletteUiViewGray, for: .highlighted)
    return resend
  }()
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  
    addSubview(titleNumber)
    addSubview(subtitleText)
    addSubview(verificationCode)
    addSubview(resend)
  
    NSLayoutConstraint.activate([
      titleNumber.topAnchor.constraint(equalTo: topAnchor),
      titleNumber.leadingAnchor.constraint(equalTo: leadingAnchor),
      titleNumber.trailingAnchor.constraint(equalTo: trailingAnchor),
      titleNumber.heightAnchor.constraint(equalToConstant: 70),
      
      subtitleText.topAnchor.constraint(equalTo: titleNumber.bottomAnchor),
      subtitleText.leadingAnchor.constraint(equalTo: leadingAnchor),
      subtitleText.trailingAnchor.constraint(equalTo: trailingAnchor),
      subtitleText.heightAnchor.constraint(equalToConstant: 30),
      
      verificationCode.topAnchor.constraint(equalTo: subtitleText.bottomAnchor, constant: 30),
      verificationCode.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
      verificationCode.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
      verificationCode.heightAnchor.constraint(equalToConstant: 50),
      
      resend.topAnchor.constraint(equalTo: verificationCode.bottomAnchor, constant: 30),
      resend.leadingAnchor.constraint(equalTo: leadingAnchor),
      resend.trailingAnchor.constraint(equalTo: trailingAnchor),
      resend.heightAnchor.constraint(equalToConstant: 50)
    ])
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
}


 
