import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.diabfit.app.encryption"
    private let encryptionKeyAccount = "user-data-encryption-key"
    
    private init() {}
    
    // MARK: - Encryption Key Management
    
    func saveEncryptionKey(_ keyData: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: encryptionKeyAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing key if it exists
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to save encryption key to Keychain: \(status)")
        }
    }
    
    func getEncryptionKey() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: encryptionKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            print("Failed to retrieve encryption key from Keychain: \(status)")
            return nil
        }
    }
    
    func deleteEncryptionKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: encryptionKeyAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Failed to delete encryption key from Keychain: \(status)")
        }
    }
    
    // MARK: - Biometric Authentication Keys
    
    func saveBiometricToken(_ token: String, for userID: String) {
        let tokenData = token.data(using: .utf8) ?? Data()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "biometric-\(userID)",
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing token if it exists
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to save biometric token to Keychain: \(status)")
        }
    }
    
    func getBiometricToken(for userID: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "biometric-\(userID)",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let tokenData = result as? Data {
            return String(data: tokenData, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    // MARK: - HIPAA Compliance Methods
    
    func clearAllUserData() {
        // Clear all user-related data from Keychain for HIPAA compliance
        let queries: [[String: Any]] = [
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ],
            [
                kSecClass as String: kSecClassInternetPassword,
                kSecAttrService as String: service
            ]
        ]
        
        for query in queries {
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                print("Failed to clear Keychain data: \(status)")
            }
        }
    }
}