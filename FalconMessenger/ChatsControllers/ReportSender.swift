//
//  ReportSender.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/10/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import ARSLineProgress

class ReportSender: NSObject {

  func sendReport(_ description: String?, _ controller: UIViewController?, _ message: Message?, _ indexPath: IndexPath? = nil, _ cell: BaseMessageCell? = nil) {
    
    guard let controller = controller else { return }
    ARSLineProgress.show()
    var reportsDatabaseReference: DatabaseReference!
    reportsDatabaseReference = Database.database(url: globalVariables.reportDatabaseURL).reference().child("reports").childByAutoId()
    
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
       ARSLineProgress.hide()
       basicErrorAlertWith(title: "Your report has bees sent",
                           message: "We will review your report and react as soon as possible",
                           controller: controller)
      guard let indexPath = indexPath , let cell = cell else { return }
      cell.handleDeletion(indexPath: indexPath)
    }
  }
}
