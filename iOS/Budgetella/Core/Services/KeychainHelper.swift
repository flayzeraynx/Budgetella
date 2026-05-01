//
//  KeychainHelper.swift
//  Budgetella
//
//  Keychain CRUD — Firebase ID token ve biometric lock state persist için.
//  Tüm operasyonlar senkron, thread-safe (Security framework garantisi).
//

import Foundation
import Security

public enum KeychainHelper {

    public enum Key: String {
        case firebaseIdToken  = "com.ozankilic.budgetella.firebase.idToken"
        case firebaseUid      = "com.ozankilic.budgetella.firebase.uid"
        case biometricEnabled = "com.ozankilic.budgetella.biometric.enabled"
    }

    // MARK: - Write

    @discardableResult
    public static func set(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecValueData:   data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    public static func set(_ value: Bool, for key: Key) -> Bool {
        set(value ? "1" : "0", for: key)
    }

    // MARK: - Read

    public static func string(for key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func bool(for key: Key) -> Bool {
        string(for: key) == "1"
    }

    // MARK: - Delete

    @discardableResult
    public static func delete(_ key: Key) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    public static func clearAll() {
        Key.allCases.forEach { delete($0) }
    }
}

extension KeychainHelper.Key: CaseIterable {}
