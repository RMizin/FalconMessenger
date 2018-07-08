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
    filtededConversations = conversations
    filteredPinnedConversations = pinnedConversations
    handleReloadTable()
    guard #available(iOS 11.0, *) else {
      searchBar.setShowsCancelButton(false, animated: true)
      searchBar.resignFirstResponder()
      return
    }
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
    filtededConversations = searchText.isEmpty ? conversations :
      conversations.filter({ (conversation) -> Bool in
        if let chatName = conversation.chatName {
          return chatName.lowercased().contains(searchText.lowercased())
        }
        return ("").lowercased().contains(searchText.lowercased())
      })
    
    filteredPinnedConversations = searchText.isEmpty ? pinnedConversations :
      pinnedConversations.filter({ (conversation) -> Bool in
        if let chatName = conversation.chatName {
          return chatName.lowercased().contains(searchText.lowercased())
        }
        return ("").lowercased().contains(searchText.lowercased())
      })
    
    handleReloadTableAfterSearch()
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
