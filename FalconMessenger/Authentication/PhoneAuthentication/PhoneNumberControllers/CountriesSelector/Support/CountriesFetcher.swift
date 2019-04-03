//
//  CountriesFetcher.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/27/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

@objc protocol CountriesFetcherDelegate: class {
  @objc optional func countriesFetcher(_ fetcher: CountriesFetcher, didFetch countries: [Country])
  @objc optional func countriesFetcher(_ fetcher: CountriesFetcher, currentCountry country: Country)
}

final class CountriesFetcher: NSObject {

	weak var delegate: CountriesFetcherDelegate?

	func fetchCountries() {
		guard let path = Bundle.main.path(forResource: "CallingCodes", ofType: "plist") else { return }
		let url = URL(fileURLWithPath: path)
		do {
			let data = try Data(contentsOf: url)
			let plist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
			guard let countriesArray = plist as? [[String: String]] else { return }
			fetch(countriesArray)
		} catch {
			fatalError()
		}
	}

	fileprivate func fetch(_ plist: [[String: String]]) {
		var countries = [Country]()
		for dictionary in plist {
			let country = Country(dictionary: dictionary)
			countries.append(country)
		}
		delegate?.countriesFetcher?(self, didFetch: countries)
		currentCountry(countries: countries)
	}

	fileprivate func currentCountry(countries: [Country]) {
		let currentCountryCode = NSLocale.current.regionCode
		for country in countries where country.code == currentCountryCode {
			delegate?.countriesFetcher?(self, currentCountry: country)
		}
	}
}
