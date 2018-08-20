//
//  ContactsFetcher.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Contacts

protocol ContactsUpdatesDelegate: class {
  func contacts(updateDatasource contacts: [CNContact])
  func contacts(handleAccessStatus: Bool)
}

class ContactsFetcher: NSObject {
  
  weak var delegate: ContactsUpdatesDelegate?
  
  func fetchContacts () {
    let status = CNContactStore.authorizationStatus(for: .contacts)
    let store = CNContactStore()
    if status == .denied || status == .restricted {
      delegate?.contacts(handleAccessStatus: false)
      return
    }
    
    store.requestAccess(for: .contacts) { granted, error in
      guard granted, error == nil else {
        self.delegate?.contacts(handleAccessStatus: false)
        return
      }
      
      self.delegate?.contacts(handleAccessStatus: true)
      
      let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey]
      let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
      var contacts = [CNContact]()
      do {
        try store.enumerateContacts(with: request) { contact, stop in
          contacts.append(contact)
        }
      } catch {}
      
      let phoneNumbers = contacts.flatMap({$0.phoneNumbers.map({$0.value.stringValue.digits})})
      localPhones = phoneNumbers
      self.delegate?.contacts(updateDatasource: contacts)
    }
  }
}
