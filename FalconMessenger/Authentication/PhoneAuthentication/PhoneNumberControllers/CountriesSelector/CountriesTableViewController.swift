//
//  CountriesTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/26/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

protocol CountryPickerDelegate: class {
  func countryPicker(_ picker: CountriesTableViewController,
                     didSelectCountryWithName name: String,
                     code: String,
                     dialCode: String)
}

private let countriesTableViewCellID = "countriesTableViewCellID"

final class CountriesTableViewController: UITableViewController {

	var countries = [Country]()
	var filteredCountries = [Country]()
	fileprivate var filteredCountriesWithSection = [[Country]]()
	fileprivate var collation = UILocalizedIndexedCollation.current()
	fileprivate var sectionTitles = [String]()
	var searchBar: UISearchBar?
	var searchController: UISearchController?
	var currentCountry: String?
	fileprivate let countriesFetcher = CountriesFetcher()

	weak var delegate: CountryPickerDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()
		configureController()
		setupSearchController()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		searchController?.isActive = false
	}

	fileprivate func configureController() {
		navigationItem.title = "Select country"
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = true
		}
		definesPresentationContext = true
		extendedLayoutIncludesOpaqueBars = true
		view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
		tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
		tableView.sectionIndexBackgroundColor = view.backgroundColor
		tableView.separatorStyle = .none
		tableView.backgroundColor = view.backgroundColor
		tableView.register(CountriesTableViewCell.self, forCellReuseIdentifier: countriesTableViewCellID)
		countriesFetcher.delegate = self
		countriesFetcher.fetchCountries()
	}

	fileprivate func setupSearchController() {
		if #available(iOS 11.0, *) {
			searchController = UISearchController(searchResultsController: nil)
			searchController?.obscuresBackgroundDuringPresentation = false
			searchController?.searchBar.delegate = self
			searchController?.hidesNavigationBarDuringPresentation = false
			navigationItem.searchController = searchController
			navigationItem.hidesSearchBarWhenScrolling = false
		} else {
			searchBar = UISearchBar()
			searchBar?.delegate = self
			searchBar?.placeholder = "Search"
			searchBar?.searchBarStyle = .minimal
			searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
			tableView.tableHeaderView = searchBar
		}
	}

	@objc func setUpCollation() {
		let (arrayContacts, arrayTitles) = collation.partitionObjects(array: filteredCountries,
																																	collationStringSelector: #selector(getter: Country.name))
		guard let contacts = arrayContacts as? [[Country]] else { return }
		filteredCountriesWithSection = contacts
		sectionTitles = arrayTitles
	}

	fileprivate func set(_ isSelected: Bool, for country: Country, at indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath) as? CountriesTableViewCell ?? CountriesTableViewCell()
		cell.accessoryType = isSelected ? .checkmark : .none

		if let index = countries.firstIndex(where: { (item) -> Bool in
			return item.name == country.name }) {
			countries[index].isSelected = isSelected
		}

		if let index = filteredCountries.firstIndex(where: { (item) -> Bool in
			return item.name == country.name }) {
			filteredCountries[index].isSelected = isSelected
		}
	}

	fileprivate func selectCurrentCountry(with name: String, in countries: [Country]) {
		if let index = countries.firstIndex(where: { (item) -> Bool in
			return item.name == name }) {
			countries[index].isSelected = true
		}

		self.countries = countries
		filteredCountries = countries
		setUpCollation()
	}

	fileprivate func resetSelection() {
		_ = countries.map({$0.isSelected = false})
		_ = filteredCountries.map({$0.isSelected = false})
		_ = filteredCountriesWithSection.map({$0.map({$0.isSelected = false })})
		tableView.reloadData()
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return sectionTitles.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return filteredCountriesWithSection[section].count
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sectionTitles[section]
	}

	override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
		return sectionTitles
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: countriesTableViewCellID,
																						 for: indexPath) as? CountriesTableViewCell ?? CountriesTableViewCell()
		let country = filteredCountriesWithSection[indexPath.section][indexPath.row]
		cell.setupCell(for: country)

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		resetSelection()
		let selectedCountry = filteredCountriesWithSection[indexPath.section][indexPath.row]
		filteredCountriesWithSection[indexPath.section][indexPath.row].isSelected = true
		set(true, for: selectedCountry, at: indexPath)
		delegate?.countryPicker(self, didSelectCountryWithName: selectedCountry.name ?? "",
														code: selectedCountry.code ?? "",
														dialCode: selectedCountry.dialCode ?? "")
	}

	override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		view.tintColor = ThemeManager.currentTheme().generalBackgroundColor
		if let headerTitle = view as? UITableViewHeaderFooterView {
			headerTitle.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
			headerTitle.textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
		}
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 25
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 65
	}
}

extension CountriesTableViewController: CountriesFetcherDelegate {
  func countriesFetcher(_ fetcher: CountriesFetcher, didFetch countries: [Country]) {
    if let currentCountryName = self.currentCountry {
      selectCurrentCountry(with: currentCountryName, in: countries)
    } else {
      self.countries = countries
      filteredCountries = countries
      setUpCollation()
    }
  }
}
