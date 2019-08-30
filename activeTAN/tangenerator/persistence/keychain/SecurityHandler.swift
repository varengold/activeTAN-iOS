//
// Copyright (c) 2019 EFDIS AG Bankensoftware, Freising <info@efdis.de>.
//
// This file is part of the activeTAN app for iOS.
//
// The activeTAN app is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The activeTAN app is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with the activeTAN app.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

class SecurityHandler {
    
    static var privateTag: String = "de.efdis.activeTAN.secureEnclaveKeyPair"
    static let attrKeyType : CFString = kSecAttrKeyTypeECSECPrimeRandom
    static let enclaveAlgorithm : SecKeyAlgorithm = .eciesEncryptionCofactorX963SHA256AESGCM
    
    static func saveToKeychain(key: String, data: Data) throws {
        let query : [String : Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Could not save to keychain.")
        }
    }
    
    static func loadFromKeychain(key: String) throws -> Data? {
        let query : [String : Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]

        var result: AnyObject?

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Cannot retrieve keychain item.")
        }
        return (result as! Data)
    }
    
    static func deleteFromKeychain(key: String) throws {
        let query : [String : Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
        ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Cannot delete keychain item.")
        }
    }
    
    static func restoreKey(keyData : Data) throws -> SecKey {
        let attributes: [String: Any] = [
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA
        ]
        var error : Unmanaged<CFError>?
        let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error)
        if key == nil{
            throw SecurityHandlerError.error("\(String(describing: error))")
        }
        return key!
    }
    
    static func verifySignature(data : Data, signature : Data, publicKey: SecKey, algorithm : SecKeyAlgorithm) throws -> Bool {
        guard SecKeyIsAlgorithmSupported(publicKey, .verify, algorithm) else{
            throw SecurityHandlerError.error("Verification of signature is not supported for provided algorithm or public key.")
        }
        
        var error : Unmanaged<CFError>?
        
        let verfiy = SecKeyVerifySignature(publicKey, algorithm, data as CFData, signature as CFData, &error)
        
        if !verfiy {
            throw SecurityHandlerError.error("\(String(describing: error))")
        }
        return verfiy
    }
}

// MARK: Secure Enclave operations

extension SecurityHandler {
    
    static func generateKeyPair() throws -> SecKey {
        // delete already generated key pairs, if existent
        try? deletePrivateKey()
        try? deletePublicKey()
        
        // Specify access control
        // TODO: other attribute?
        guard let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .privateKeyUsage, nil)
            else {
                fatalError("Cannot set access control.")
        }
        
        // Assemble attributes
        
        let attributes: [String : Any] = [
            kSecAttrKeyType as String:            attrKeyType,
            kSecAttrKeySizeInBits as String:      256,
            kSecAttrTokenID as String:            kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String:      true,
                kSecAttrApplicationTag as String:   privateTag,
                kSecAttrAccessControl as String:    accessControl
            ]
        ]
        
        // Generate key pair
        var publicKey, privateKey: SecKey?
        let status = SecKeyGeneratePair(attributes as CFDictionary, &publicKey, &privateKey)
        
        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Could not generate key pair.")
        }
        
        return publicKey!
    }
    
    static func savePublicKey(publicKey: SecKey) throws{
        let query: [String : Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: attrKeyType,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrApplicationTag as String: privateTag,
            kSecValueRef as String: publicKey,
            kSecAttrIsPermanent as String: true,
            kSecReturnData as String: true,
        ]
        var result: CFTypeRef?
        let status = SecItemAdd(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Could not save public key")
        }
    }
    
    static func getPublicKey() throws -> SecKey{
        let query : [String : Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrKeyType as String:          attrKeyType,
            kSecAttrApplicationTag as String:   privateTag,
            kSecAttrKeyClass as String:         kSecAttrKeyClassPublic,
            kSecReturnData as String:           true,
            kSecReturnRef as String:            true,
            kSecReturnPersistentRef as String:  true,
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Cannot retrieve public key. Keychain query failed.")
        }
        
        let dictionary = result as! [String: Any]
        
        return dictionary[kSecValueRef as String] as! SecKey
    }
    
    static func getPrivateKey() throws -> SecKey{
        let query : [String : Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrApplicationTag as String:   privateTag,
            kSecAttrKeyClass as String:         kSecAttrKeyClassPrivate,
            kSecReturnRef as String:            true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Cannot retrieve private key. Keychain query failed.")
        }
        return result as! SecKey
    }
    
    static func deletePrivateKey() throws {
        let query: [String : Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrKeyClass as String:         kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag as String:    privateTag,
            kSecReturnRef as String:            true,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Could not delete private key")
        }
    }
    
    static func deletePublicKey() throws {
        
        let query: [String : Any] = [
            kSecClass as String:                kSecClassKey,
            kSecAttrKeyType as String:          attrKeyType,
            kSecAttrKeyClass as String:         kSecAttrKeyClassPublic,
            kSecAttrApplicationTag as String:   privateTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess else {
            throw SecurityHandlerError.error("Could not delete public key")
        }
    }
    
    static func encrypt(plain : Data, publicKey: SecKey, algorithm : SecKeyAlgorithm) throws -> Data {
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else{
            throw SecurityHandlerError.error("Enryption algorithm not supported for provided public key.")
        }
        
        var error : Unmanaged<CFError>?
        
        let encrypted = SecKeyCreateEncryptedData(publicKey, algorithm, plain as CFData, &error)
        
        if encrypted == nil {
            throw SecurityHandlerError.error("\(String(describing: error))")
        }
        return encrypted! as Data
    }
    
    static func decrypt(encrypted : Data, privateKey: SecKey, algorithm : SecKeyAlgorithm) throws -> Data {
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else{
            throw SecurityHandlerError.error("Decryption algorithm not supported for provided private key.")
        }
        
        var error : Unmanaged<CFError>?
        
        let plain = SecKeyCreateDecryptedData(privateKey, algorithm, encrypted as CFData, &error)
        
        if plain == nil {
            throw SecurityHandlerError.error("\(String(describing: error))")
        }
        return plain! as Data
    }
    
    static func isUsableKeypairAvailable() -> Bool {
        do {
            let algorithm : SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA512
            let privateKey = try getPrivateKey()
            
            let signature = SecKeyCreateSignature(privateKey, algorithm, "Rosebud".data(using: .utf8)! as CFData, nil)
            
            if signature == nil {
                return false
            }
            
        } catch {
            return false
        }
        return true
    }
}

enum SecurityHandlerError: Error {
    case error(String)
}
