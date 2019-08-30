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

enum FieldEncoding {
    case bcd, ascii
    
    public static func bcdDecode(data : [UInt8]) throws -> Int {
        var result = 0
        for i in 0 ... data.count-1 {
            let firstNibble = (data[i] & 0xf0) >> 4
            let secondNibble = (data[i] & 0x0f)
            
            if firstNibble > 9 {
                throw FieldEncodingError.numberFormat("Illegal value in first half-byte of BCD coded number")
            } else{
                result = result * 10 + Int(firstNibble)
            }
            
            if secondNibble > 9 {
                if secondNibble == 0xf && i == data.count - 1 {
                    // end of number
                    break
                }
                
                throw FieldEncodingError.numberFormat("Illegal value in second half-byte of BCD coded number")
            } else {
                result = result * 10 + Int(secondNibble);
            }
        }
        
        return result
    }
    
    static func bcdEncode(number: String) -> [UInt8] {
        var digits : [Int]
        if number.count % 2 == 0 {
            digits = [Int](repeating: 0, count: number.count)
        } else {
            digits = [Int](repeating: 0, count: number.count+1)
            digits[digits.count - 1] = 0xf
        }
        
        for i in 0...number.count-1 {
            let index = number.index(number.startIndex, offsetBy: i)
            
            let digit = Int(String(number[index]))! - Int(String("0"))!
            digits[i] = digit
        }
        
        var result : [UInt8] = [UInt8](repeating: 0, count: digits.count / 2)
        for i in 0...result.count-1 {
            let firstNibble = digits[2 * i]
            let secondNibble = digits[2 * i + 1]
            result[i] = UInt8((firstNibble << 4) | secondNibble)
        }
        
        return result

    }
}

public enum FieldEncodingError : Error {
    case numberFormat(String)
}

        



