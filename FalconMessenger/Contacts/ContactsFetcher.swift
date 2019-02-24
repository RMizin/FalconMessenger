//
//  ContactsFetcher.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Contacts

protocol ContactsUpdatesDelegate: class {
  func contacts(shouldPerformSyncronization: Bool)
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

      let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey,
                  CNContactImageDataKey, CNContactPhoneNumbersKey,
                  CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey]
      let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
      var contacts = [CNContact]()
      do {
        try store.enumerateContacts(with: request) { contact, _ in
          contacts.append(contact)
        }
      } catch {}

      let phoneNumbers = contacts.flatMap({$0.phoneNumbers.map({$0.value.stringValue.digits})})
      globalVariables.localPhones = phoneNumbers
      self.delegate?.contacts(updateDatasource: contacts)
      self.syncronizeContacts(contacts: contacts)
    }
  }

  func syncronizeContacts(contacts: [CNContact]) {
    let contactsCount = contacts.count
    let defaultContactsCount = userDefaults.currentIntObjectState(for: userDefaults.contactsCount)
    let syncronizationStatus = userDefaults.currentBoolObjectState(for: userDefaults.contactsSyncronizationStatus)
    guard userDefaults.currentBoolObjectState(for: userDefaults.contactsContiniousSync) == true else { return }
    if !userDefaults.isContactsCountExists() || defaultContactsCount != contactsCount || syncronizationStatus != true {
      userDefaults.updateObject(for: userDefaults.contactsCount, with: contactsCount)
      delegate?.contacts(shouldPerformSyncronization: true)
    }
  }
}
