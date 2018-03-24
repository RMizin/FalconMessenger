//
//  GroupAdminControlsTableViewController+NameEditing.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase


extension GroupAdminControlsTableViewController: UITextFieldDelegate { /* user name editing */
  
  func setEditingBarButtons() {
    navigationItem.leftBarButtonItem = cancelBarButton
    navigationItem.rightBarButtonItem = doneBarButton
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
      doneBarButton.isEnabled = false
    } else {
      doneBarButton.isEnabled = true
    }
  }
  
  @objc func cancelBarButtonPressed() {
    
    groupProfileTableHeaderContainer.name.text = currentName
    groupProfileTableHeaderContainer.name.resignFirstResponder()
    navigationItem.leftBarButtonItem = nil
    navigationItem.rightBarButtonItem = nil
  }
  
  @objc func doneBarButtonPressed() {
    
    if currentReachabilityStatus == .notReachable {
      basicErrorAlertWith(title: "No internet", message: noInternetError, controller: self)
      return
    }
    
   // let nameUpdatingGroup = DispatchGroup()
    navigationItem.leftBarButtonItem = nil
    navigationItem.rightBarButtonItem = nil
    groupProfileTableHeaderContainer.name.resignFirstResponder()
    ARSLineProgress.ars_showOnView(view)
  
//    for _ in members {
//      nameUpdatingGroup.enter()
//    }
    
//    nameUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
//      ARSLineProgress.showSuccess()
//    })
    
  //  for member in members {
      guard let newChatName = groupProfileTableHeaderContainer.name.text else { return }
      let nameUpdateReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
    //  print("Updating chat name for \(String(describing: member.name)) with id: \(String(describing: member.id))")
   
      nameUpdateReference.updateChildValues(["chatName": newChatName], withCompletionBlock: { (error, reference) in
        ARSLineProgress.showSuccess()
        //nameUpdatingGroup.leave()
      })
   // }
  }
}

