//
//  ContactsDetailController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/7/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import MessageUI
import Contacts

private let currentUserCellID = "currentUserCellID"
private let contactPhoneNnumberTableViewCellID = "contactPhoneNnumberTableViewCellID"
private let invitationText = "Hey! Download Falcon Messenger on the App Store. https://itunes.apple.com/ua/app/falcon-messenger/id1313765714?mt=8 "

class ContactsDetailController: UITableViewController {

  var contactName = String()
  var contactPhoto: UIImage!
  var contactPhoneNumbers = [CNLabeledValue<CNPhoneNumber>]()

    override func viewDidLoad() {
        super.viewDidLoad()
      title = "Info"
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      extendedLayoutIncludesOpaqueBars = true
      tableView.separatorStyle = .none
      tableView.register(CurrentUserTableViewCell.self, forCellReuseIdentifier: currentUserCellID)
      tableView.register(ContactPhoneNnumberTableViewCell.self, forCellReuseIdentifier: contactPhoneNnumberTableViewCellID)
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
      if indexPath.section == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: currentUserCellID,
                                                 for: indexPath) as? CurrentUserTableViewCell ?? CurrentUserTableViewCell()
        cell.selectionStyle = .none
        cell.iconWidthAnchor.constant = CurrentUserTableViewCell.iconSizeLargeConstant
        cell.iconHeightAnchor.constant = CurrentUserTableViewCell.iconSizeLargeConstant
        cell.icon.layer.cornerRadius = CurrentUserTableViewCell.iconLargreCornerRadius
        cell.title.font = UIFont.systemFont(ofSize: 18)
        cell.title.text = contactName

        if contactPhoto != nil {
          cell.icon.image = contactPhoto
        } else {
          cell.icon.image = UIImage(named: "UserpicIcon")
        }

        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: contactPhoneNnumberTableViewCellID,
                                                 for: indexPath) as? ContactPhoneNnumberTableViewCell ?? ContactPhoneNnumberTableViewCell()
        if indexPath.section == 1 {
          let contact = contactPhoneNumbers[indexPath.row]
          cell.configureCell(contact: contact)
        } else {
          cell.textLabel?.textColor = view.tintColor
          cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
          cell.textLabel?.text = "Invite to Falcon"
        }
        return cell
      }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      if indexPath.section == 2 {
        if MFMessageComposeViewController.canSendText() {
          guard contactPhoneNumbers.indices.contains(0) else {
            basicErrorAlertWith(title: "Error",
                                message: "This user doesn't have any phone number provided.",
                                controller: self)
            return
          }
          let destination = MFMessageComposeViewController()
          destination.body = invitationText
          destination.recipients = [contactPhoneNumbers[0].value.stringValue]
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
      } else if indexPath.section == 1 {
        return 60
      } else {
        return 80
      }
    }
}

extension ContactsDetailController: MFMessageComposeViewControllerDelegate {
  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    dismiss(animated: true, completion: nil)
  }
}
