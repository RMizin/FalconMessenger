//
//  CountriesTableViewController+Search.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/27/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension CountriesTableViewController: UISearchBarDelegate, UISearchControllerDelegate {

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    if #available(iOS 11.0, *) {
      searchController?.searchBar.endEditing(true)
    } else {
      self.searchBar?.endEditing(true)
    }
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    filteredCountries = countries
    guard countries.count > 0 else { return }

    searchBar.setShowsCancelButton(false, animated: true)
    searchBar.resignFirstResponder()
    setUpCollation()
    UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: {
      self.tableView.reloadData()
    }, completion: nil)
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
    filteredCountries = searchText.isEmpty ? countries : countries.filter({ (country) -> Bool in
      return country.name!.lowercased().contains(searchText.lowercased()) ||
        country.code!.lowercased().contains(searchText.lowercased()) ||
        country.dialCode!.lowercased().contains(searchText.lowercased())
    })
    setUpCollation()
    UIView.transition(with: tableView, duration: 0.15, options: .transitionCrossDissolve, animations: {
      self.tableView.reloadData()
    }, completion: nil)
  }
}

extension CountriesTableViewController { /* hiding keyboard */
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    if #available(iOS 11.0, *) {
      searchController?.searchBar.endEditing(true)
    } else {
      searchBar?.endEditing(true)
    }
  }
}
