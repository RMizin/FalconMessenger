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

public var countryCode = NSLocale.current.regionCode
fileprivate var savedContentOffset = CGPoint(x: 0, y: -50)
fileprivate var savedCountryCode = String()


class SelectCountryCodeController: UITableViewController {

  let countries = Country().countries
  var filteredCountries = [[String:String]]()
  var searchBar = UISearchBar()

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
    view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
  }
  
  fileprivate func configureSearchBar() {
    searchBar.delegate = self
    searchBar.searchBarStyle = .minimal
    searchBar.placeholder = "Search"
    searchBar.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
    searchBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
  }
  
  fileprivate func configureTableView() {
    tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
    tableView.separatorStyle = .none
    tableView.tableHeaderView = searchBar
    filteredCountries = countries
  }
}

extension SelectCountryCodeController {
 
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredCountries.count
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 55
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let identifier = "cell"
    
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
    
    let countryName = filteredCountries[indexPath.row]["name"]!
    let countryDial = " " + filteredCountries[indexPath.row]["dial_code"]!
    
		let countryNameAttribute = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalTitleColor]
		let countryDialAttribute = [NSAttributedString.Key.foregroundColor: ThemeManager.currentTheme().generalSubtitleColor]
    let countryNameAString = NSAttributedString(string: countryName, attributes: countryNameAttribute)
    let countryDialAString = NSAttributedString(string: countryDial, attributes: countryDialAttribute)
    
    let mutableAttributedString = NSMutableAttributedString()
    mutableAttributedString.append(countryNameAString)
    mutableAttributedString.append(countryDialAString)
    
    cell.textLabel?.attributedText = mutableAttributedString
    
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
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
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
      return data["name"]!.lowercased().contains(searchText.lowercased()) || data["dial_code"]!.lowercased().contains(searchText.lowercased())
    })
 
    tableView.reloadData()
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    self.searchBar.endEditing(true)
  }
}

extension SelectCountryCodeController {
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.isDecelerating {
      view.endEditing(true)
    }
  }
}
