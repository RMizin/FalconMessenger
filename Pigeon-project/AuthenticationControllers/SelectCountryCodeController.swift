//
//  SelectCountryCodeController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/3/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


protocol CountryPickerDelegate: class {
  func countryPicker(_ picker: SelectCountryCodeController, didSelectCountryWithName name: String, code: String, dialCode: String)
}

fileprivate var savedContentOffset = CGPoint(x: 0, y: -50)
fileprivate var savedCountryCode = String()


class SelectCountryCodeController: UIViewController {

  let countries = Country().countries
  var filteredCountries = [[String:String]]()
  var searchBar = UISearchBar()
  let tableView = UITableView()
  var hidingNavBarManager: HidingNavigationBarManager?
  weak var delegate: CountryPickerDelegate?
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    
      view.addSubview(tableView)
      tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
      searchBar.frame = CGRect(x: 0, y: navigationController!.navigationBar.frame.height, width: view.frame.width, height: 50)
      hidingNavBarManager = HidingNavigationBarManager(viewController: self, scrollView: tableView)
      filteredCountries = countries
      hidingNavBarManager?.addExtensionView(searchBar)
      
    }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    hidingNavBarManager?.viewWillAppear(animated)
    tableView.setContentOffset(savedContentOffset, animated: false)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    hidingNavBarManager?.viewWillDisappear(animated)
    savedContentOffset = tableView.contentOffset
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    hidingNavBarManager?.viewDidLayoutSubviews()
  }
  
  func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
    hidingNavBarManager?.shouldScrollToTop()
    
    return true
  }
}


extension SelectCountryCodeController: UITableViewDelegate, UITableViewDataSource {
 
   func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredCountries.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let identifier = "cell"
    
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
    cell.textLabel?.text = filteredCountries[indexPath.row]["name"]! + " (" + filteredCountries[indexPath.row]["dial_code"]! + ")"
    
    if countryCode == filteredCountries[indexPath.row]["code"]! {
      cell.accessoryType = .checkmark
    } else {
      cell.accessoryType = .none
    }
    
    return cell
  }
  
 fileprivate func resetCheckmark() {
    for index in 0...filteredCountries.count {
      let indexPath = IndexPath(row: index , section: 0)
      let cell = tableView.cellForRow(at: indexPath)
      
       cell?.accessoryType = .none
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    resetCheckmark()
    let cell = tableView.cellForRow(at: indexPath)
    cell?.accessoryType = .checkmark
    
    countryCode = filteredCountries[indexPath.row]["code"]!
    delegate?.countryPicker(self, didSelectCountryWithName: filteredCountries[indexPath.row]["name"]!,
                                   code: filteredCountries[indexPath.row]["code"]!,
                                   dialCode: filteredCountries[indexPath.row]["dial_code"]!)
  }
}


extension SelectCountryCodeController: UISearchBarDelegate {
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
    filteredCountries = searchText.isEmpty ? countries : countries.filter({ (data: [String : String]) -> Bool in
      return data["name"]!.lowercased().contains(searchText.lowercased())
    })
 
    tableView.reloadData()
  }
  
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    self.searchBar.endEditing(true)
  }
}


extension SelectCountryCodeController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.isDecelerating {
      view.endEditing(true)
    }
  }
}




