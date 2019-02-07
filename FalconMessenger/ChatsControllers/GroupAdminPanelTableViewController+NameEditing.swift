//
//  GroupAdminControlsTableViewController+NameEditing.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import ARSLineProgress

extension GroupAdminPanelTableViewController: UITextFieldDelegate { /* user name editing */

  func setEditingBarButtons() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                       style: .plain,
                                                       target: self,
                                                       action: #selector(cancelBarButtonPressed))
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
                                                        style: .done,
                                                        target: self,
                                                        action: #selector(doneBarButtonPressed))
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    doneBarButtonPressed()
    textField.resignFirstResponder()
    return true
  }

  @objc func nameDidBeginEditing() {
    setEditingBarButtons()
  }

  @objc func nameEditingChanged() {

    if groupProfileTableHeaderContainer.name.text!.count == 0 ||
      groupProfileTableHeaderContainer.name.text!.trimmingCharacters(in: .whitespaces).isEmpty {
      navigationItem.rightBarButtonItem?.isEnabled = false
    } else {
      navigationItem.rightBarButtonItem?.isEnabled = true
    }
  }

  @objc func cancelBarButtonPressed() {

    groupProfileTableHeaderContainer.name.text = currentName
    groupProfileTableHeaderContainer.name.resignFirstResponder()
    navigationItem.leftBarButtonItem = nil
    guard isCurrentUserAdministrator else { navigationItem.rightBarButtonItem = nil; return }
    navigationItem.rightBarButtonItem = editButtonItem
  }

  @objc func doneBarButtonPressed() {
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: "No internet", message: noInternetError, controller: self)
      return
    }

    groupProfileTableHeaderContainer.name.resignFirstResponder()
    ARSLineProgress.ars_showOnView(view)

    guard let newChatName = groupProfileTableHeaderContainer.name.text else { return }
    let nameUpdateReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    nameUpdateReference.updateChildValues(["chatName": newChatName], withCompletionBlock: { (_, _) in
      ARSLineProgress.showSuccess()
    })

    navigationItem.leftBarButtonItem = nil
    guard isCurrentUserAdministrator else { navigationItem.rightBarButtonItem = nil; return }
    navigationItem.rightBarButtonItem = editButtonItem
  }
}
