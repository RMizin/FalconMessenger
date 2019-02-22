//
//  ContactsController+SearchHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/10/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension ContactsController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {

  func updateSearchResults(for searchController: UISearchController) {}

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
		setupDataSource()
    filteredContacts = contacts
    UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: {
      self.tableView.reloadData()
    }, completion: nil)
    guard #available(iOS 11.0, *) else {
      searchBar.setShowsCancelButton(false, animated: true)
      searchBar.resignFirstResponder()
      return
    }
  }

  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    guard #available(iOS 11.0, *) else {
     searchBar.setShowsCancelButton(true, animated: true)
      return true
    }
    return true
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		let userObjects = realm.objects(User.self).sorted(byKeyPath: "onlineStatusSortDescriptor", ascending: false)
		users = searchText.isEmpty ? userObjects : userObjects.filter("name contains[cd] %@", searchText)

    filteredContacts = searchText.isEmpty ? contacts : contacts.filter({ (CNContact) -> Bool in
      let contactFullName = CNContact.givenName.lowercased() + " " + CNContact.familyName.lowercased()
      return contactFullName.lowercased().contains(searchText.lowercased())
    })

    UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: {
      self.tableView.reloadData()
    }, completion: nil)
  }
}

extension ContactsController { /* hiding keyboard */

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
