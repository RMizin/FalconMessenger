//
//  ReportAlertController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 9/10/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ReportAlertController: UIAlertController {

  let reportSender = ReportSender()
  weak var controller: UIViewController?
	var reportedMessage: Message?
  var indexPath: IndexPath?
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
      let spamAction = UIAlertAction(title: "Spam", style: .default) { (action) in
        self.sendReport(action.title ?? "Spam")
      }
      
      let violenceAction = UIAlertAction(title: "Violence", style: .default) { (action) in
        self.sendReport(action.title ?? "Violence")
      }
      
      let pornographyAction = UIAlertAction(title: "Pornography", style: .default) { (action) in
        self.sendReport(action.title ?? "Pornography")
      }
      
      let otherAction = UIAlertAction(title: "Other", style: .default) { (_) in
        guard let sender = self.controller else { return }
        let destination = OtherReportController()
        destination.delegate = self
        
        if DeviceType.isIPad {
          let navigation = UINavigationController(rootViewController: destination)
          navigation.modalPresentationStyle = .popover
          navigation.popoverPresentationController?.barButtonItem = sender.navigationItem.rightBarButtonItem
          sender.present(navigation, animated: true, completion: nil)
        } else {
          sender.navigationController?.pushViewController(destination, animated: true)
        }
      }
      
      addAction(spamAction)
      addAction(violenceAction)
      addAction(pornographyAction)
      addAction(otherAction)
      addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
  
  fileprivate func sendReport(_ title: String) {
		guard let sender = self.controller, let reportedMessage = self.reportedMessage else { return }
    let isConnected = self.checkInternetConnection()
    guard isConnected else { return }
    if let controller = self.controller as? ChatLogViewController,
      let indexPath = self.indexPath,
      let cell = controller.collectionView.cellForItem(at: indexPath) as? BaseMessageCell {

      self.reportSender.sendReport(title, sender, reportedMessage, indexPath, cell)
    } else {
      self.reportSender.sendReport(title, sender, reportedMessage)
    }
  }
  
  fileprivate func checkInternetConnection() -> Bool {
     guard currentReachabilityStatus != .notReachable else {
      guard let controller = self.controller else { return false }
      basicErrorAlertWith(title: "No Internet Connection",
                          message: "Check your internet connection and try again.",
                          controller: controller)
      return false
    }
    return true
  }
}

extension ReportAlertController: OtherReportDelegate {
  func send(reportWith description: String) {
    sendReport(description)
  }
}
