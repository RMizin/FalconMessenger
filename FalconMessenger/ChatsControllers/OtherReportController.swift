//
//  OtherReportController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/10/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

protocol OtherReportDelegate: class {
  func send(reportWith description: String)
}

class OtherReportController: UIViewController {
  
  weak var delegate: OtherReportDelegate?
  
  let textView: UITextView = {
    let textView = UITextView()
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.layer.cornerRadius = 30
    textView.layer.masksToBounds = true
    textView.textContainerInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 10)
    textView.font = UIFont.systemFont(ofSize: 18)
    
    return textView
  }()
  
  let reportSender = ReportSender()
  
  weak var reportedMessage: Message?
  weak var controller: UIViewController?
  var heightAnchor: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
      
      configureNavigationItem()
      configureView()
      configureTextView()
      changeTheme()
    }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc fileprivate func changeTheme() {
    textView.backgroundColor = ThemeManager.currentTheme().inputTextViewColor
    textView.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    textView.textColor = ThemeManager.currentTheme().generalTitleColor
  }
  
  fileprivate func configureNavigationItem() {
    let sendButton = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(send))
    navigationItem.setRightBarButton(sendButton, animated: false)
    navigationItem.rightBarButtonItem?.isEnabled = false
    navigationItem.title = "Report"
  }
  
  fileprivate func configureView() {
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    view.addSubview(textView)
    NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
  }
  
  fileprivate func configureTextView() {
    textView.delegate = self
    textView.becomeFirstResponder()
    textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
 
    if #available(iOS 11.0, *) {
      textView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
      textView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
    } else {
      textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
      textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
    }
  
    heightAnchor = textView.heightAnchor.constraint(equalToConstant: InputTextViewLayout.maxHeight()-10)
    heightAnchor.isActive = true
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    DispatchQueue.main.async {
      self.heightAnchor.constant = InputTextViewLayout.maxHeight()-10
    }
  }
  
  @objc fileprivate func send() {
    textView.resignFirstResponder()
    if DeviceType.isIPad {
      dismiss(animated: true, completion: nil)
    } else {
      navigationController?.popViewController(animated: true)
    }

    delegate?.send(reportWith: textView.text)
  }
}

extension OtherReportController: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    if textView.text.count > 0 {
      navigationItem.rightBarButtonItem?.isEnabled = true
    } else {
      navigationItem.rightBarButtonItem?.isEnabled = false
    }
  }
}
