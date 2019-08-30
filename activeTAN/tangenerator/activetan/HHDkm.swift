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

/**
 Hand held device, key material
 */
class HHDkm {
    let type: KeyMaterialType
    let aesKeyComponent : [UInt8]
    let letterNumber : Int
    var deviceSerialNumber : String?
    
    private let deviceSerialNumberLength = 12
    
    init(rawBytes : [UInt8]) throws {
        // 1 byte prefix
        guard let keyMaterialType = KeyMaterialType(rawValue: rawBytes[0]) else {
            throw HHDkmError.error("unsupported key prefix")
        }
        type = keyMaterialType
        
        // 16 bytes banking key
        if rawBytes.count-1 < BankingKeyComponents.bankingKeyLength {
            throw HHDkmError.error("incomplete key data")
        }
        aesKeyComponent = Array(rawBytes[1...BankingKeyComponents.bankingKeyLength])
        
        do{
            if type == KeyMaterialType.PORTAL {
                // 12 byte serial number
                if rawBytes.count < 1+BankingKeyComponents.bankingKeyLength+deviceSerialNumberLength {
                    throw HHDkmError.error("incomplete serial number")
                }
                let serialNumberBytes = Array(rawBytes[1+BankingKeyComponents.bankingKeyLength...BankingKeyComponents.bankingKeyLength+deviceSerialNumberLength])
                deviceSerialNumber =  DKCharset.decode(input: serialNumberBytes)
                let letterNumberPosition = 1+BankingKeyComponents.bankingKeyLength+deviceSerialNumberLength
                letterNumber = try FieldEncoding.bcdDecode(data: [rawBytes[letterNumberPosition]])
            } else if [KeyMaterialType.LETTER, KeyMaterialType.DEMO].contains(type) {
                // 1 byte letter number
                letterNumber = try FieldEncoding.bcdDecode(data: [rawBytes[17]])
            } else{
                throw HHDkmError.error("Unknown key material type")
            }

        } catch (FieldEncodingError.numberFormat(let message)){
            throw HHDkmError.error("Error encoding BCD: \(message)")
        }
        // The remaining data contains text instructions for other hand held devices, which can be ignored.

    }
    
    // TODO: Other functions
    
}

enum HHDkmError: Error {
    case error(String)
}

enum KeyMaterialType : UInt8{
    case LETTER = 0x42 // 'B'
    case PORTAL = 0x50 // 'P'
    case DEMO = 0x44 // 'D'
}
