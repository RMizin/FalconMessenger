//
//  ReportSender.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/10/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase

class ReportSender: NSObject {
  
  func sendReport(_ description: String?, _ controller: UIViewController?, _ message: Message?) {
    
    guard let controller = controller else { return }
    ARSLineProgress.show()
    var reportsDatabaseReference: DatabaseReference!
    reportsDatabaseReference = Database.database(url: GlobalDataStorage.reportDatabaseURL).reference().child("reports").childByAutoId()
    
    let reportedMessageID = message?.messageUID ?? "empty"
    let reportedUserID = message?.fromId ?? "empty"
    let victimUserID = Auth.auth().currentUser?.uid ?? "empty"
    let reportDescription = description ?? "empty"
    
    let childValues: [String: String] = ["reportedMessageID": reportedMessageID,
                                         "reportedUserID": reportedUserID,
                                         "victimUserID": victimUserID,
                                         "description": reportDescription]
    
    reportsDatabaseReference.updateChildValues(childValues) { (error, _) in
      guard error == nil else {
        ARSLineProgress.hide()
        basicErrorAlertWith(title: "Error", message: error?.localizedDescription ?? "Try again later", controller: controller)
        return
      }
      ARSLineProgress.showSuccess()
    }
  }
}
