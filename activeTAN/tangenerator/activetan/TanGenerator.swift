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
import CryptoSwift

class TanGenerator {
    
    // Number of decimal digits for TANs.
    private static let tanDigits : Int = 6
    
    private static let pow10 : [Int]  = [1, 10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000, 100_000_000, 1_000_000_000]
    
    // Bitmask to generate a static TAN
    private static let generateStaticTan : [UInt8] = [
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80,
        0x00, 0x00, 0x00, 0x00, 0x09, 0x99, 0x00,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ]
    
    /**
     Compute a tan with a secret master key, transaction counter and transaction data.
     
     - Parameters:
        - token :Defines secret key alias in the key store and the current transaction counter.
        - hhduc : Transaction data
     
     - Returns: TAN for transaction authorization (6-digit decimal number)
     - Throws: If the secret key cannot be used
     */
    static func generateTan(token : BankingToken, hhduc : HHDuc) throws -> Int {
        let visData = VisDataBuffer()
        visData.write(hhduc: hhduc)

        let visDataDigest = visData.getHash()
        
        return try generateTan(token: token, commandData: visDataDigest)
    }

    
    /**
     Compute a tan for initialization of the security token with a secret master key.

     - Parameter token: Defines secret key alias in the key store. The transaction counter must be zero.
     - Returns: TAN for initialization of the security token (6-digit decimal number)
     - Throws: If the secret key cannot be used
     */
    public static func generateTanForInitialization(token : BankingToken) throws -> Int {
        if (token.transactionCounter != 0) {
            throw GeneralError.illegalState("static TAN can only be generated for a new token")
        }
    
        return try generateTan(token: token, commandData: generateStaticTan);
    }

    
    /**
     Compute a tan using an application cryptogram from arbitrary input data.
     
     - Parameter token: Defines secret key alias in the key store and the current transaction counter.
     - Returns: TAN (6-digit decimal number)
     - Throws: If the secret key cannot be used
     */
    private static func generateTan(token : BankingToken, commandData: [UInt8]) throws -> Int {
        let aac : [UInt8] = try computeApplicationAuthenticationCryptogram(token: token, digest: commandData)
        
        return try decimalization(hmac: aac, tanDigits: tanDigits)
    }
    
    /**
     Cryptographically sign a digest with the transaction counter and secret banking key associated with the `BankingToken`.

     - Parameters:
        - token : Defines secret key and transaction counter (ATC).
        - digest : Hash value of the data to be signed, e. g., from a VisDataBuffer.
     
     - Returns: hmac value
     
     - Throws: If the secret key cannot be used, e. g., because of unsatisfied protection constraints
     */
    private static func computeApplicationAuthenticationCryptogram(token : BankingToken, digest: [UInt8]) throws -> [UInt8] {
        let atc = UInt16(token.transactionCounter)
        
        var inputAAC : [UInt8] = Utils.copyOfRange(arr: digest, from: 0, to: 33)!
        inputAAC[31] = UInt8((atc & 0xff00) >> 8)
        inputAAC[32] = UInt8(atc & 0x00ff)

        if !SecurityHandler.isUsableKeypairAvailable(){
            throw TanGeneratorError.error("No key pair generated yet")
        }
        
        do {
            // get encrypted key from enclave
            let encryptedKey = try SecurityHandler.loadFromKeychain(key: token.keyAlias!)
            let algorithm : SecKeyAlgorithm = SecurityHandler.enclaveAlgorithm
            
            // decrypt key
            let privateKey = try SecurityHandler.getPrivateKey()
            let 🔑 = try SecurityHandler.decrypt(encrypted: encryptedKey!, privateKey: privateKey, algorithm: algorithm)
            
            let hmac = try CMAC(key: [UInt8](🔑)).authenticate(inputAAC)
            
            return hmac
        } catch {
            throw TanGeneratorError.error("Keychain access failed")
        }
    }

    /**
     Compute a decimal number from a hashed message authentication code (HMAC).
    
     The algorithm used is HOTP (RFC 4226) with a customized offset computation, depending on the hash value's length.
     
     - Parameters:
        - hmac: hashed message authentication code
        - tanDigits: desired maximum number of decimal digits of the result.
     
     - Returns: decimal number derived from the `hmac`
     */
    static func decimalization(hmac : [UInt8], tanDigits : Int) throws -> Int {
        if (tanDigits > 9) {
            // It is not possible to create more than 9 digits, because 2^31 = 2_147_483_648
            // limits the possible values of the 10th digit to 0, 1, and 2.
            throw GeneralError.illegalArgument("The maximum number of supported digits is 9")
        }
        
        // Determine an offset from the last byte of the hash value
        let offset : Int
        switch (hmac.count) {
        case 16: // MD5, AES-CBC-MAC
            offset = Int(hmac[hmac.count - 1] & 0x0b)
            break
        case 20: // SHA-0, SHA-1
            // RFC 4226
            offset = Int(hmac[hmac.count - 1] & 0x0f)
            break
        case 28: // SHA-224, SHA-512/224, SHA3-224
            offset = Int(hmac[hmac.count - 1] & 0x17)
            break
        case 32: // SHA-256, SHA-512/256, SHA3-256
            offset = Int(hmac[hmac.count - 1] & 0x1b)
            break
        case 48: // SHA-384, SHA3-384
            // 0x2b is not used, because 0x1f provides more bits
            offset = Int(hmac[hmac.count - 1] & 0x1f)
            break
        case 64: // SHA-512, SHA3-512
            offset = Int(hmac[hmac.count - 1] & 0x3b)
            break
        default:
            throw GeneralError.illegalArgument("Unsupported hash value length")
        }
        
        // Read a 31 bit unsigned integer at the offset
        let a = UInt32(hmac[offset] & 0x7f) << 24
        let b = UInt32(hmac[offset + 1]) << 16
        let c = UInt32(hmac[offset + 2]) << 8
        let d = UInt32(hmac[offset + 3])
        
        let binary = a
            | b
            | c
            | d
        
        // Extract the least significant decimal digits
        let hotp : Int = Int(binary) % pow10[tanDigits]
        
        return hotp
    }

    static func formatTAN(tan : Int) -> String {
        return String(format: "%06d", tan)
    }
}

enum TanGeneratorError : Error{
    case error(String)
}
