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

  weak var delegate: CountryPickerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
    configureSearchBar()
    configureTableView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.setContentOffset(savedContentOffset, animated: false)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    savedContentOffset = tableView.contentOffset
  }
  
  fileprivate func configureView() {
    title = "Select your country"
    view.addSubview(tableView)
    view.addSubview(searchBar)
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  fileprivate func configureSearchBar() {
    searchBar.delegate = self
    searchBar.searchBarStyle = .minimal
    searchBar.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    searchBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
  }
  
  fileprivate func configureTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.separatorStyle = .none
    tableView.tableHeaderView = searchBar
    if #available(iOS 11.0, *) {
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
      tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
      tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    } else {
      tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    filteredCountries = countries
  }
}


extension SelectCountryCodeController: UITableViewDelegate, UITableViewDataSource {
 
   func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredCountries.count
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let identifier = "cell"
    
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    cell.textLabel?.text = filteredCountries[indexPath.row]["name"]! + " (" + filteredCountries[indexPath.row]["dial_code"]! + ")"
    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
    cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
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




