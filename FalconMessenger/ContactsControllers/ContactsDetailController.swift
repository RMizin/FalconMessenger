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
  var contactPhoto: UIImage!
  
  var contactPhoneNumbers = [String]()
  let invitationText = "Hey! Download Falcon Messenger on the App Store. https://itunes.apple.com/ua/app/falcon-messenger/id1313765714?mt=8 "
  let currentUserCellID = "currentUserCellID"
  
    override func viewDidLoad() {
        super.viewDidLoad()
      title = "Info"
      view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
      extendedLayoutIncludesOpaqueBars = true
      tableView.separatorStyle = .none
      tableView.register(CurrentUserTableViewCell.self, forCellReuseIdentifier: currentUserCellID)
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
      
      if indexPath.section == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: currentUserCellID, for: indexPath) as! CurrentUserTableViewCell
        cell.selectionStyle = .none
        cell.title.text = contactName
        if contactPhoto != nil {
          cell.icon.image = contactPhoto
        } else {
          cell.icon.image = UIImage(named: "UserpicIcon")
        }
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.backgroundColor = view.backgroundColor
        cell.selectionStyle = .none
        cell.imageView?.image = nil
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        if indexPath.section == 1 {
          cell.textLabel?.text = contactPhoneNumbers[indexPath.row]
          cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        } else {
          cell.textLabel?.textColor = FalconPalette.defaultBlue
          cell.textLabel?.text = "Invite to Falcon"
        }
        return cell
      }
    }
  
    deinit {
      print("DETAIL DEINIT")
    }
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      if indexPath.section == 2 {
        if MFMessageComposeViewController.canSendText() {
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
        return 90
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
