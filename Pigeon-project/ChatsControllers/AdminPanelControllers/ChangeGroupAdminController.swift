//
//  ChangeGroupAdminController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class ChangeGroupAdminController: SelectNewAdminTableViewController {
    
  override func viewDidLoad() {
    super.viewDidLoad()
    setupRightBarButton(with: "Change administrator")
  }
  
  override func rightBarButtonTapped() {
    super.rightBarButtonTapped()
    setNewAdmin(membersIDs: getMembersIDs())
  }
}
