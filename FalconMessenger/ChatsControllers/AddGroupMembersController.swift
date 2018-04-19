//
//  AddGroupMembersController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/30/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class AddGroupMembersController: SelectParticipantsViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupRightBarButton(with: "Add")
    setupNavigationItemTitle(title: "Add users")
  }
  
  override func rightBarButtonTapped() {
    super.rightBarButtonTapped()
    
    addNewMembers()
  }
}
