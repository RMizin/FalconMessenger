//
//  ContactsDetailController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/7/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import MessageUI

class ContactsDetailController: UITableViewController {
  
  var contactName = String()
  
  var contactPhoneNumbers = [String]()
  let invitationText = "Hey! Download Falcon Messenger on the App Store. https://itunes.apple.com/ua/app/falcon-messenger/id1313765714?mt=8 "

  override func viewDidLoad() {
      super.viewDidLoad()
    title = "Info"
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    extendedLayoutIncludesOpaqueBars = true
    tableView.separatorStyle = .none
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
      return 3
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else if section == 1 {
      return contactPhoneNumbers.count
    } else {
      return 1
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let identifier = "cell"
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
     cell.backgroundColor =  view.backgroundColor
     cell.selectionStyle = .none
     cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
    
    if indexPath.section == 0 {
      cell.imageView?.image = UIImage(named: "UserpicIcon")
      cell.textLabel?.text = contactName
      cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
    } else if indexPath.section == 1 {
      cell.imageView?.image = nil
      cell.textLabel?.text = contactPhoneNumbers[indexPath.row]
      cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
    } else {
      cell.textLabel?.textColor = FalconPalette.defaultBlue
      cell.textLabel?.text = "Invite to Falcon"
      cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.section == 2 {
      if MFMessageComposeViewController.canSendText() {
        guard contactPhoneNumbers.indices.contains(0) else {
          basicErrorAlertWith(title: "Error", message: "This user doesn't have any phone number provided.", controller: self)
          return
        }
        let destination = MFMessageComposeViewController()
        destination.body = invitationText
        destination.recipients = [contactPhoneNumbers[0]]
        destination.messageComposeDelegate = self
        present(destination, animated: true, completion: nil)
      } else {
        basicErrorAlertWith(title: "Error", message: "You cannot send texts.", controller: self)
      }
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == 0 {
      return 100
    } else {
      return 50
    }
  }
}

extension ContactsDetailController: MFMessageComposeViewControllerDelegate {
  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    dismiss(animated: true, completion: nil)
  }
}
