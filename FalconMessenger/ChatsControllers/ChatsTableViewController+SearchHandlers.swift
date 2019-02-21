//
//  ChatsTableViewController+SearchHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension ChatsTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {}
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
		setupDataSource()

    UIView.transition(with: tableView,
											duration: 0.15,
											options: .transitionCrossDissolve,
											animations: { self.tableView.reloadData() },
											completion: nil)

    guard #available(iOS 11.0, *) else {
      searchBar.setShowsCancelButton(false, animated: true)
      searchBar.resignFirstResponder()
      return
    }
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		let objects = RealmKeychain.defaultRealm.objects(Conversation.self)
		let pinnedObjects = objects.filter("pinned == true").sorted(byKeyPath: "lastMessageTimestamp", ascending: false)
		let unpinnedObjects = objects.filter("pinned != true").sorted(byKeyPath: "lastMessageTimestamp", ascending: false)

		realmPinnedConversations = searchText.isEmpty ? pinnedObjects : pinnedObjects.filter("chatName contains[cd] %@", searchText)

		realmUnpinnedConversations = searchText.isEmpty ? unpinnedObjects : unpinnedObjects.filter("chatName contains[cd] %@", searchText)
		UIView.transition(with: tableView,
											duration: 0.15,
											options: .transitionCrossDissolve,
											animations: { self.tableView.reloadData() },
											completion: nil)
  }
  
  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    guard #available(iOS 11.0, *) else {
      searchBar.setShowsCancelButton(true, animated: true)
      return true
    }
    return true
  }
}

extension ChatsTableViewController { /* hiding keyboard */
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    if #available(iOS 11.0, *) {
      searchChatsController?.searchBar.endEditing(true)
    } else {
      self.searchBar?.endEditing(true)
    }
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    setNeedsStatusBarAppearanceUpdate()
    if #available(iOS 11.0, *) {
      searchChatsController?.searchBar.endEditing(true)
    } else {
      self.searchBar?.endEditing(true)
    }
  }
}
