//
//  RealmKeychain.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 2/21/19.
//  Copyright © 2019 Roman Mizin. All rights reserved.
//

import Security
import RealmSwift

final class RealmKeychain {

	static let defaultRealm = try! Realm(configuration: RealmKeychain.realmDefaultConfiguration())
	static let usersRealm = try! Realm(configuration: RealmKeychain.realmUsersConfiguration())

	static func realmUsersArray() -> [User] {
		return Array(RealmKeychain.usersRealm.objects(User.self))
	}

	static func realmUsersConfiguration() -> Realm.Configuration {
		var config = Realm.Configuration()
		config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("users.realm")
		config.encryptionKey = RealmKeychain.getKey() as Data
		return config
	}

	static func realmDefaultConfiguration() -> Realm.Configuration {
		var config = Realm.Configuration()
		config.encryptionKey = RealmKeychain.getKey() as Data
		return config
	}

	static fileprivate func getKey() -> NSData {
		// Identifier for our keychain entry - should be unique for your application
		let keychainIdentifier = "falconMessenger.Realm.EncryptionKey"
		let keychainIdentifierData = keychainIdentifier.data(using: String.Encoding.utf8, allowLossyConversion: false)!

		// First check in the keychain for an existing key
		var query: [NSString: AnyObject] = [
			kSecClass: kSecClassKey,
			kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
			kSecAttrKeySizeInBits: 512 as AnyObject,
			kSecReturnData: true as AnyObject
		]

		// To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
		// See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
		var dataTypeRef: AnyObject?
		var status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
		if status == errSecSuccess {
			return dataTypeRef as! NSData
		}

		// No pre-existing key from this application, so generate a new one
		let keyData = NSMutableData(length: 64)!
		let result = SecRandomCopyBytes(kSecRandomDefault, 64, keyData.mutableBytes.bindMemory(to: UInt8.self, capacity: 64))
		assert(result == 0, "Failed to get random bytes")

		// Store the key in the keychain
		query = [
			kSecClass: kSecClassKey,
			kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
			kSecAttrKeySizeInBits: 512 as AnyObject,
			kSecValueData: keyData
		]

		status = SecItemAdd(query as CFDictionary, nil)
		assert(status == errSecSuccess, "Failed to insert the new key in the keychain")

		return keyData
	}
}
