//
//  AppSecurityManager.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import Foundation
import CryptoKit
import Security

final class AppSecurityManager {
    static let shared = AppSecurityManager()
    private let keyTag = "com.audittract.masterkey"
    
    // Enforce Hardware Complete File Protection on App Sandbox
    func enforceHardwareFileProtection() {
        let fileManager = FileManager.default
        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? fileManager.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: docsURL.path
            )
        }
    }
    
    // Retrieve or Generate AES-256 Symmetric Key from Keychain
    func getOrCreateMasterKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let keyData = item as? Data {
            return SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keyTag,
                kSecValueData as String: keyData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            SecItemAdd(addQuery as CFDictionary, nil)
            return newKey
        }
    }
    
    // Encrypt Plaintext -> Base64 Sealed Payload
    func encrypt(_ plaintext: String) -> String {
        guard !plaintext.isEmpty,
              let key = getOrCreateMasterKey(),
              let data = plaintext.data(using: .utf8),
              let sealedBox = try? AES.GCM.seal(data, using: key) else { return plaintext }
        return sealedBox.combined?.base64EncodedString() ?? plaintext
    }
    
    // Decrypt Base64 Sealed Payload -> Plaintext
    func decrypt(_ ciphertext: String) -> String {
        guard let key = getOrCreateMasterKey(),
              let data = Data(base64Encoded: ciphertext),
              let sealedBox = try? AES.GCM.SealedBox(combined: data),
              let decryptedData = try? AES.GCM.open(sealedBox, using: key),
              let str = String(data: decryptedData, encoding: .utf8) else { return ciphertext }
        return str
    }
}
