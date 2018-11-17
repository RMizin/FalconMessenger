//
//  SelectGroupMembersController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SelectGroupMembersController: SelectParticipantsViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupRightBarButton(with: "Next")
    setupNavigationItemTitle(title: "New group")
  }
  
  override func rightBarButtonTapped() {
    super.rightBarButtonTapped()
    
    createGroup()
  }
}
