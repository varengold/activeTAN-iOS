//
// Copyright (c) 2019-2020 EFDIS AG Bankensoftware, Freising <info@efdis.de>.
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

class BankingKeyComponents {
    
    static let bankingKeyLength : Int = 16
    
    var deviceKeyComponent : [UInt8]?
    var letterKeyComponent : [UInt8]?
    var portalKeyComponent : [UInt8]?
    
    // Generate a new device key component using random data
    func generateDeviceKeyComponent() {
        var keyData = Data(count: BankingKeyComponents.bankingKeyLength)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, BankingKeyComponents.bankingKeyLength, $0.baseAddress!)
        }
        if result == errSecSuccess {
            deviceKeyComponent = [UInt8](keyData)
        } else {
            fatalError()
        }
    }
    
    // Create the banking key by combination of all components
    func combine() throws -> [UInt8] {
        guard let _deviceKeyComponent = deviceKeyComponent, _deviceKeyComponent.count == BankingKeyComponents.bankingKeyLength else{
            throw GeneralError.illegalState("device key is missing or invalid")
        }
        
        guard let _letterKeyComponent = letterKeyComponent, _letterKeyComponent.count == BankingKeyComponents.bankingKeyLength else{
            throw GeneralError.illegalState("letter key is missing or invalid")
        }
        
        guard let _portalKeyComponent = portalKeyComponent, _portalKeyComponent.count == BankingKeyComponents.bankingKeyLength else{
            throw GeneralError.illegalState("portal key is missing or invalid")
        }
        
        var bankingKey = [UInt8](repeating: 0, count: BankingKeyComponents.bankingKeyLength)
        
        for i in 0 ... BankingKeyComponents.bankingKeyLength-1 {
            bankingKey[i] ^= _deviceKeyComponent[i] ^ _letterKeyComponent[i] ^ _portalKeyComponent[i]
        }
        
        return bankingKey
    }
}
