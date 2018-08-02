//
//  SelectParticipantsViewController+SearchHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/11/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension SelectParticipantsViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {}
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    filteredUsers = users
    guard users.count > 0 else { return }
    searchBar.setShowsCancelButton(false, animated: true)
    searchBar.resignFirstResponder()
    setUpCollation()
    UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData() }, completion: nil)
  }
  
  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    searchBar.setShowsCancelButton(true, animated: true)

    return true
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    filteredUsers = searchText.isEmpty ? users : users.filter({ (User) -> Bool in
      return User.name!.lowercased().contains(searchText.lowercased())
    })
    setUpCollation()
    UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: { self.tableView.reloadData() }, completion: nil)
  }
}

extension SelectParticipantsViewController { /* hiding keyboard */
  
   func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    searchBar?.resignFirstResponder()
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    self.searchBar?.endEditing(true)
  }
}


