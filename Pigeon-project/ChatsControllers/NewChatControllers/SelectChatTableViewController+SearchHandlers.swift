//
//  SelectChatTableViewController+SearchHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/8/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension SelectChatTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {}
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    filteredUsers = users
   // actions.append(newGroupAction)
    tableView.reloadData()
  }
  
  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
  
    return true
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
  
   // actions.removeAll()
    
    filteredUsers = searchText.isEmpty ? users : users.filter({ (User) -> Bool in
      return User.name!.lowercased().contains(searchText.lowercased())
    })
    
    tableView.reloadData()
  }
}

extension SelectChatTableViewController { /* hiding keyboard */
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    
    if #available(iOS 11.0, *) {
      searchContactsController?.resignFirstResponder()
      searchContactsController?.searchBar.resignFirstResponder()
    } else {
      searchBar?.resignFirstResponder()
    }
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    
    if #available(iOS 11.0, *) {
      searchContactsController?.searchBar.endEditing(true)
    } else {
      self.searchBar?.endEditing(true)
    }
  }
}

