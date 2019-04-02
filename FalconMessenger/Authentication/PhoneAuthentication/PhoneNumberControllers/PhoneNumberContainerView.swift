//
//  PhoneNumberContainerView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

final class PhoneNumberContainerView: UIView {

	let title: UILabel = {
    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.textAlignment = .center
    title.text = "Phone number"
    title.textColor = ThemeManager.currentTheme().generalTitleColor
    title.font = UIFont.systemFont(ofSize: 32)
    if #available(iOS 11.0, *) {
      title.isHidden = true
    }

    return title
  }()

  let instructions: UILabel = {
    let instructions = UILabel()
    instructions.translatesAutoresizingMaskIntoConstraints = false
    instructions.textAlignment = .center
    instructions.numberOfLines = 2
    instructions.textColor = ThemeManager.currentTheme().generalTitleColor
    instructions.font = UIFont.boldSystemFont(ofSize: 18)//systemFont(ofSize: 18)
    instructions.sizeToFit()

    return instructions
  }()

  let selectCountry: ControlButton = {
    let selectCountry = ControlButton()
    selectCountry.translatesAutoresizingMaskIntoConstraints = false
    selectCountry.setTitle("Canada", for: .normal)
    selectCountry.addTarget(self, action: #selector(PhoneNumberController.openCountryCodesList), for: .touchUpInside)

    return selectCountry
  }()

  var countryCode: UILabel = {
    var countryCode = UILabel()
    countryCode.translatesAutoresizingMaskIntoConstraints = false
    countryCode.text = "+1"
    countryCode.textAlignment = .center
    countryCode.textColor = ThemeManager.currentTheme().generalTitleColor
    countryCode.font = UIFont.boldSystemFont(ofSize: 18)
    countryCode.sizeToFit()

    return countryCode
  }()

  let phoneNumber: UITextField = {
    let phoneNumber = UITextField()
    phoneNumber.font = UIFont.boldSystemFont(ofSize: 18)
    phoneNumber.translatesAutoresizingMaskIntoConstraints = false
    phoneNumber.textAlignment = .center
    phoneNumber.keyboardType = .numberPad
    phoneNumber.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    phoneNumber.textColor = ThemeManager.currentTheme().generalTitleColor
    phoneNumber.addTarget(self, action: #selector(PhoneNumberController.textFieldDidChange(_:)), for: .editingChanged)
    if !DeviceType.isIPad {
      phoneNumber.addDoneButtonOnKeyboard()
    }

    return phoneNumber
  }()

  let termsAndPrivacy: UITextView = {
    let termsAndPrivacy = UITextView()
    termsAndPrivacy.translatesAutoresizingMaskIntoConstraints = false
    termsAndPrivacy.isEditable = false
    termsAndPrivacy.backgroundColor = .clear
    termsAndPrivacy.textColor = ThemeManager.currentTheme().generalTitleColor
    termsAndPrivacy.dataDetectorTypes = .all
    termsAndPrivacy.isScrollEnabled = false
    termsAndPrivacy.textContainerInset.top = 0
    termsAndPrivacy.sizeToFit()

    return termsAndPrivacy
  }()

  var phoneContainer: UIView = {
    var phoneContainer = UIView()
    phoneContainer.translatesAutoresizingMaskIntoConstraints = false
    phoneContainer.layer.cornerRadius = 25
    phoneContainer.layer.borderWidth = 1
    phoneContainer.layer.borderColor = ThemeManager.currentTheme().inputTextViewColor.cgColor

    return phoneContainer
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(title)
    addSubview(instructions)
    addSubview(selectCountry)
    addSubview(termsAndPrivacy)
    addSubview(phoneContainer)
    phoneContainer.addSubview(countryCode)
    phoneContainer.addSubview(phoneNumber)

    let countriesFetcher = CountriesFetcher()
    countriesFetcher.delegate = self
    countriesFetcher.fetchCountries()

    phoneNumber.delegate = self

    configureTextViewText()

    let leftConstant: CGFloat = 10
    let rightConstant: CGFloat = -10
    let heightConstant: CGFloat = 50
    let spacingConstant: CGFloat = 20

    if #available(iOS 11.0, *) {
      title.heightAnchor.constraint(equalToConstant: 0).isActive = true
    } else {
      title.sizeToFit()
    }

    NSLayoutConstraint.activate([
      title.topAnchor.constraint(equalTo: topAnchor, constant: spacingConstant),
      title.rightAnchor.constraint(equalTo: rightAnchor, constant: rightConstant),
      title.leftAnchor.constraint(equalTo: leftAnchor, constant: leftConstant),

      instructions.topAnchor.constraint(equalTo: title.bottomAnchor, constant: spacingConstant),
      instructions.rightAnchor.constraint(equalTo: title.rightAnchor),
      instructions.leftAnchor.constraint(equalTo: title.leftAnchor),

      selectCountry.topAnchor.constraint(equalTo: instructions.bottomAnchor, constant: spacingConstant),
      selectCountry.rightAnchor.constraint(equalTo: title.rightAnchor),
      selectCountry.leftAnchor.constraint(equalTo: title.leftAnchor),
      selectCountry.heightAnchor.constraint(equalToConstant: heightConstant),

      phoneContainer.topAnchor.constraint(equalTo: selectCountry.bottomAnchor, constant: spacingConstant),
      phoneContainer.rightAnchor.constraint(equalTo: title.rightAnchor),
      phoneContainer.leftAnchor.constraint(equalTo: title.leftAnchor),
      phoneContainer.heightAnchor.constraint(equalToConstant: heightConstant),

      countryCode.leftAnchor.constraint(equalTo: phoneContainer.leftAnchor, constant: leftConstant),
      countryCode.centerYAnchor.constraint(equalTo: phoneContainer.centerYAnchor),
      countryCode.heightAnchor.constraint(equalTo: phoneContainer.heightAnchor),

      phoneNumber.rightAnchor.constraint(equalTo: phoneContainer.rightAnchor, constant: rightConstant),
      phoneNumber.leftAnchor.constraint(equalTo: countryCode.rightAnchor, constant: leftConstant),
      phoneNumber.centerYAnchor.constraint(equalTo: phoneContainer.centerYAnchor),
      phoneNumber.heightAnchor.constraint(equalTo: phoneContainer.heightAnchor),

      termsAndPrivacy.topAnchor.constraint(equalTo: phoneContainer.bottomAnchor, constant: 15),
      termsAndPrivacy.rightAnchor.constraint(equalTo: title.rightAnchor),
      termsAndPrivacy.leftAnchor.constraint(equalTo: title.leftAnchor)
    ])
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }

  private func configureTextViewText() {
    let font = UIFont.boldSystemFont(ofSize: 14)
    let termsURL = URL(string: "https://docs.google.com/document/d/19PQFh9LzXz1HO2Zq6U7ysCESIbGoodY6rBJbOeCyjkc/edit?usp=sharing")!
    let privacyURL = URL(string: "https://docs.google.com/document/d/1r365Yan3Ng4l0T4o7UXqLid8BKm4N4Z3cSGTnzzA7Fg/edit?usp=sharing")!
    let termsString = "By signing up, you agree to the Terms of Service."
    let privacyString = " Also if you still have not read the Privacy Policy, please take a look before signing up."
		let termsAndConditionsAttributes = [NSAttributedString.Key.link: termsURL,
																				NSAttributedString.Key.foregroundColor: UIColor.blue,
																				NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any]

		let privacyPolicyAttributes = [NSAttributedString.Key.link: privacyURL,
																	 NSAttributedString.Key.foregroundColor: UIColor.blue,
																	 NSAttributedString.Key.font: font] as [NSAttributedString.Key : Any]
 //and Conditions
    let termsAttributedString = NSMutableAttributedString(string: termsString,
																													attributes: [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor,
																																			 NSAttributedString.Key.font: font])
    termsAttributedString.setAttributes(termsAndConditionsAttributes, range: NSRange(location: 31, length: 17))

		let privacyAttributedString = NSMutableAttributedString(string: privacyString, attributes: [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor, NSAttributedString.Key.font: font])
    privacyAttributedString.setAttributes(privacyPolicyAttributes, range: NSRange(location: 37, length: 14))
    termsAttributedString.append(privacyAttributedString)
    termsAndPrivacy.attributedText = termsAttributedString
  }
}

extension PhoneNumberContainerView: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text else { return true }
    let newLength = text.utf16.count + string.utf16.count - range.length
    return newLength <= 25
  }
}

extension PhoneNumberContainerView: CountriesFetcherDelegate {
  func countriesFetcher(_ fetcher: CountriesFetcher, currentCountry country: Country) {
    selectCountry.setTitle(country.name, for: .normal)
    countryCode.text = country.dialCode
  }
}
