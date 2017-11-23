//
//  EnterPhoneNumberContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


class EnterPhoneNumberContainerView: UIView {
  
  let title: UILabel = {
    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.textAlignment = .center
    title.text = "Your phone"
    title.font = UIFont.systemFont(ofSize: 32)
    
    return title
  }()
  
  let instructions: UILabel = {
    let instructions = UILabel()
    instructions.translatesAutoresizingMaskIntoConstraints = false
    instructions.textAlignment = .center
    instructions.text = "Please confirm your country code\nand enter your phone number."
    instructions.numberOfLines = 2
    instructions.font = UIFont.systemFont(ofSize: 17)

    return instructions
  }()
  
  let selectCountry: UIButton = {
    let selectCountry = UIButton()
    selectCountry.translatesAutoresizingMaskIntoConstraints = false
    selectCountry.setBackgroundImage(UIImage(named: "PigeonAuthCountryButton"), for: .normal)
    selectCountry.setBackgroundImage(UIImage(named:"PigeonAuthCountryButtonHighlighted"), for: .highlighted)
    selectCountry.setTitle("Ukraine", for: .normal)
    selectCountry.setTitleColor(.black, for: .normal)
    selectCountry.contentHorizontalAlignment = .left
    selectCountry.contentVerticalAlignment = .center
    selectCountry.titleEdgeInsets = UIEdgeInsetsMake(0, 15.0, 0.0, 0.0)
    selectCountry.titleLabel?.font = UIFont.systemFont(ofSize: 20)
    selectCountry.addTarget(self, action: #selector(EnterPhoneNumberController.openCountryCodesList), for: .touchUpInside)

    return selectCountry
  }()
  
  var countryCode: UILabel = {
    var countryCode = UILabel()
    countryCode.translatesAutoresizingMaskIntoConstraints = false
    countryCode.text = "+380"
    countryCode.textAlignment = .center
    countryCode.font = UIFont.systemFont(ofSize: 20)
    return countryCode
  }()
  
  let phoneNumber: UITextField = {
    let phoneNumber = UITextField()
    phoneNumber.font = UIFont.systemFont(ofSize: 20)
    phoneNumber.translatesAutoresizingMaskIntoConstraints = false
    phoneNumber.textAlignment = .center
    phoneNumber.keyboardType = .numberPad
    phoneNumber.placeholder = "Phone number"
    phoneNumber.addTarget(self, action: #selector(EnterPhoneNumberController.textFieldDidChange(_:)), for: .editingChanged)
    
    return phoneNumber
  }()
  
  let backgroundFrame: UIImageView = {
    let backgroundFrame = UIImageView()
    backgroundFrame.translatesAutoresizingMaskIntoConstraints = false
    backgroundFrame.image = UIImage(named: "PigeonAuthPhoneBackground")
    return backgroundFrame
  }()
  
  let termsAndPrivacy: UITextView = {
    let termsAndPrivacy = UITextView()
    termsAndPrivacy.translatesAutoresizingMaskIntoConstraints = false
    termsAndPrivacy.isEditable = false
    termsAndPrivacy.dataDetectorTypes = .all
    
    return termsAndPrivacy
  }()

  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(title)
    addSubview(instructions)
    addSubview(selectCountry)
    addSubview(countryCode)
    addSubview(phoneNumber)
    addSubview(backgroundFrame)
    addSubview(termsAndPrivacy)
    
    phoneNumber.delegate = self
   
    let countryCodeWidth = deviceScreen.width * 0.26
    
    configureTextViewText()
 
    NSLayoutConstraint.activate([
      
      title.topAnchor.constraint(equalTo: topAnchor, constant: 0),
      title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
      title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
      title.heightAnchor.constraint(equalToConstant: 70),
      
      instructions.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 0),
      instructions.leadingAnchor.constraint(equalTo: title.leadingAnchor, constant: 0),
      instructions.trailingAnchor.constraint(equalTo: title.trailingAnchor, constant: 0),
      instructions.heightAnchor.constraint(equalToConstant: 45),
      
      selectCountry.topAnchor.constraint(equalTo: instructions.bottomAnchor, constant: 0),
      selectCountry.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
      selectCountry.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
      selectCountry.heightAnchor.constraint(equalToConstant: 70),
      
      backgroundFrame.topAnchor.constraint(equalTo: selectCountry.bottomAnchor, constant: -8),
      backgroundFrame.leadingAnchor.constraint(equalTo: selectCountry.leadingAnchor, constant: 0),
      backgroundFrame.trailingAnchor.constraint(equalTo: selectCountry.trailingAnchor, constant: 0),
      backgroundFrame.heightAnchor.constraint(equalToConstant: 50),
      
      countryCode.leadingAnchor.constraint(equalTo: backgroundFrame.leadingAnchor, constant: 0),
      countryCode.centerYAnchor.constraint(equalTo: backgroundFrame.centerYAnchor, constant: 0),
      countryCode.widthAnchor.constraint(equalToConstant: countryCodeWidth),
      countryCode.heightAnchor.constraint(equalTo: backgroundFrame.heightAnchor, constant: 0),
      
      phoneNumber.leadingAnchor.constraint(equalTo: countryCode.trailingAnchor, constant: 2),
      phoneNumber.trailingAnchor.constraint(equalTo: backgroundFrame.trailingAnchor, constant: -5),
      phoneNumber.centerYAnchor.constraint(equalTo: backgroundFrame.centerYAnchor, constant: 0),
      phoneNumber.heightAnchor.constraint(equalTo: backgroundFrame.heightAnchor, constant: 0),
      
      termsAndPrivacy.topAnchor.constraint(equalTo: phoneNumber.bottomAnchor, constant: 10),
      termsAndPrivacy.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
      termsAndPrivacy.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
      termsAndPrivacy.heightAnchor.constraint(equalToConstant: 50)
    ])
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  
  private func configureTextViewText() {
    
    let termsAndConditionsAttributes = [NSAttributedStringKey.link: URL(string: "https://docs.google.com/document/d/19PQFh9LzXz1HO2Zq6U7ysCESIbGoodY6rBJbOeCyjkc/edit?usp=sharing")!,NSAttributedStringKey.foregroundColor: UIColor.blue] as [NSAttributedStringKey : Any]
    
    let privacyPolicyAttributes = [NSAttributedStringKey.link: URL(string: "https://docs.google.com/document/d/1r365Yan3Ng4l0T4o7UXqLid8BKm4N4Z3cSGTnzzA7Fg/edit?usp=sharing")!,NSAttributedStringKey.foregroundColor: UIColor.blue] as [NSAttributedStringKey : Any]
    
    let termsAttributedString = NSMutableAttributedString(string: "By signing up, you agree to the Terms and Conditions of Service.")
    termsAttributedString.setAttributes(termsAndConditionsAttributes, range: NSMakeRange(31, 22))
    
    let privacyAttributedString = NSMutableAttributedString(string: " Also if you still have not read the Privacy Policy, please take a look before signing up.")
    privacyAttributedString.setAttributes(privacyPolicyAttributes, range: NSMakeRange(37, 14))
    termsAttributedString.append(privacyAttributedString)
    
    termsAndPrivacy.attributedText = termsAttributedString
  }
}


extension EnterPhoneNumberContainerView: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text else { return true }
    
    let newLength = text.utf16.count + string.utf16.count - range.length
    return newLength <= 15
  }
}
