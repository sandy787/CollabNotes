//  KeychainService.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    func save(key: String, data: Data) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func load(key: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
    
    func delete(key: String) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    
    func saveString(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }
    
    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    
    func saveJWTToken(_ token: String) -> Bool {
        return saveString(key: KeychainKeys.jwtToken, value: token)
    }
    
    func getJWTToken() -> String? {
        return loadString(key: KeychainKeys.jwtToken)
    }
    
    func deleteJWTToken() -> Bool {
        return delete(key: KeychainKeys.jwtToken)
    }
    
    func saveUserID(_ userID: String) -> Bool {
        return saveString(key: KeychainKeys.userID, value: userID)
    }
    
    func getUserID() -> String? {
        return loadString(key: KeychainKeys.userID)
    }
    
    func deleteUserID() -> Bool {
        return delete(key: KeychainKeys.userID)
    }
    
    func clearAll() {
        _ = deleteJWTToken()
        _ = deleteUserID()
    }
}
