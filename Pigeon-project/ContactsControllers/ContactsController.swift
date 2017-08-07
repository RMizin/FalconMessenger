//
//  ContactsController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/2/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import Contacts
import PhoneNumberKit
import Firebase
import FirebaseAuth
import SDWebImage


class ContactsController: UITableViewController {
  

  let phoneNumberKit = PhoneNumberKit()
  
  var contacts = [CNContact]()
  
  var localPhones = [String]()
  
  var users = [User]()
  
  let contactsCellID = "contactsCellID"
  

    override func viewDidLoad() {
        super.viewDidLoad()
      view.backgroundColor = .white
      tableView.register(ContactsTableViewCell.self, forCellReuseIdentifier: contactsCellID)
      tableView.separatorStyle = .none
      fetchContacts()
      tableView.prefetchDataSource = self
    }
  

  func fetchContacts () {
    
    let status = CNContactStore.authorizationStatus(for: .contacts)
    if status == .denied || status == .restricted {
      presentSettingsActionSheet()
      return
    }
    
    // open it
    let store = CNContactStore()
    store.requestAccess(for: .contacts) { granted, error in
      guard granted else {
        DispatchQueue.main.async {
          self.presentSettingsActionSheet()
        }
        return
      }
      
      // get the contacts
      let request = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey as NSString, CNContactPhoneNumbersKey as NSString, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)])
      do {
        try store.enumerateContacts(with: request) { contact, stop in
          self.contacts.append(contact)
        }
      } catch {
        print(error)
      }
      
      self.localPhones.removeAll()

      for contact in self.contacts {
       
        for phone in contact.phoneNumbers {
        
          self.localPhones.append(phone.value.stringValue)
        }
      }
      
      self.fetchPigeonUsers()
    }
  }
  
  
  func fetchPigeonUsers() {
  
    var preparedNumber = String()
    users.removeAll()
    
    for number in localPhones {
      
      do {
        let countryCode = try self.phoneNumberKit.parse(number).countryCode
        let nationalNumber = try self.phoneNumberKit.parse(number).nationalNumber
        preparedNumber = "+" + String(countryCode) + String(nationalNumber)
      
      } catch {
        print("Generic parser error")
      }

      var userRef: DatabaseQuery = Database.database().reference().child("users")
   
      userRef = userRef.queryOrdered(byChild: "phoneNumber").queryEqual(toValue: preparedNumber )
      userRef.observeSingleEvent(of: .value, with: { (snapshot) in
      
        if snapshot.exists() {
         
          userRef.observe(.childChanged, with: { (snap) in
            
            guard var dictionary = snap.value as? [String: AnyObject] else {
              return
            }
            
            dictionary.updateValue(snap.key as AnyObject, forKey: "id")
            
            for index in 0...self.users.count - 1 {
              if self.users[index].id == snap.key {
                self.users[index] = User(dictionary: dictionary)
                 self.tableView.reloadData()
              }
            }
          })
         
          
          for child in snapshot.children.allObjects as! [DataSnapshot]  {
  
            guard var dictionary = child.value as? [String: AnyObject] else {
              return
            }
            
            dictionary.updateValue(child.key as AnyObject, forKey: "id")
            self.users.append(User(dictionary: dictionary))
            
            DispatchQueue.main.async {
              self.tableView.reloadData()
            }
          }
        }
        
      }, withCancel: { (error) in
        //search error
      })
    }
  }
  
 
  func presentSettingsActionSheet() {
    let alert = UIAlertController(title: "Permission to Contacts", message: "This app needs access to contacts in order to ...", preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
      let url = URL(string: UIApplicationOpenSettingsURLString)!
      UIApplication.shared.open(url)
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
      if section == 0 {
        return users.count
      } else {
         return contacts.count
      }
    }
  
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 60
    }
  
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      if section == 0 {
      
        if users.count == 0 {
          return ""
        } else {
          return "Pigeon contacts"
        }
      
      } else {
        return "All contacts"
      }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: contactsCellID, for: indexPath) as! ContactsTableViewCell
      
      if indexPath.section == 0 {
      
        if let name = users[indexPath.row].name, let status = users[indexPath.row].onlineStatus {
          
            cell.title.text = name + " " + status
        } else {
          
           cell.title.text = users[indexPath.row].name
        }
    
        
        if let url = users[indexPath.row].photoURL {
          
          cell.icon.sd_setImage(with: URL(string: url),
                                placeholderImage: UIImage(named: "UserpicIcon"),
                                options: [.progressiveDownload, .continueInBackground, .highPriority])
          }
        
        
      } else if indexPath.section == 1 {
        
        cell.icon.image = UIImage(named: "UserpicIcon")
        cell.title.text = contacts[indexPath.row].givenName + " " + contacts[indexPath.row].familyName
      }
        return cell
    }
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
      if indexPath.section == 0 {
      
        let destination = ContactsDetailController()
        destination.contactName = "HERE IS GONNE BE CHAT LOG WINDOW"
        self.navigationController?.pushViewController(destination, animated: true)
      }
    
      if indexPath.section == 1 {
        let destination = ContactsDetailController()
        destination.contactName = contacts[indexPath.row].givenName + " " + contacts[indexPath.row].familyName
        destination.contactPhoneNumbers.removeAll()
        
        for phoneNumber in contacts[indexPath.row].phoneNumbers {
          destination.contactPhoneNumbers.append(phoneNumber.value.stringValue)
        }
        self.navigationController?.pushViewController(destination, animated: true)
      }
    }
}


extension ContactsController: UITableViewDataSourcePrefetching {
  
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let urls = users.map { $0.photoURL! }
    SDWebImagePrefetcher.shared().prefetchURLs(urls)
    
  }
}

