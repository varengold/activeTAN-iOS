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

class DKCharset {
    
    static func encode(input : String) -> [UInt8] {
        var out = [UInt8]()
        for c in input {
            switch (c) {
            case "#":
                out.append(0x23)
                continue
            case "€":
                out.append(0x24)
                continue
            case "@":
                out.append(0x40)
                continue
            case "Ä":
                out.append(0x5b)
                continue
            case "Ö":
                out.append(0x5c)
                continue
            case "Ü":
                out.append(0x5d)
                continue
            case "£":
                out.append(0x5e)
                continue
            case "`":
                out.append(0x60)
                continue
            case "ä":
                out.append(0x7b)
                continue
            case "ö":
                out.append(0x7c)
                continue
            case "ü":
                out.append(0x7d)
                continue
            case "ß":
                out.append(0x7e)
                continue
            default: break
                
            }
            
            //let utf16 = Int(String(c))!
            let utf16 = Int(UnicodeScalar(String(c))!.value)
            
            if 0x20 <= utf16 && utf16 <= 0x7f {
                out.append(UInt8(utf16))
            } else {
                out.append(UInt8("?")!)
            }
        }
        
        return out
    }
    
    static func decode(input : [UInt8]) -> String {
        var output : String = ""
        for c in input {
            let b = c & 0xff
            
            switch (b) {
            case 0x23:
                output += "#"
                continue
            case 0x24:
                output += "€"
                continue
            case 0x40:
                output += "@"
                continue
            case 0x5b:
                output += "Ä"
                continue
            case 0x5c:
                output += "Ö"
                continue
            case 0x5d:
                output += "Ü"
                continue
            case 0x5e:
                output += "£"
                continue
            case 0x60:
                output += "`"
                continue
            case 0x7b:
                output += "ä"
                continue
            case 0x7c:
                output += "ö"
                continue
            case 0x7d:
                output += "ü"
                continue
            case 0x7e:
                output += "ß"
                continue
            default:
                break
            }
            
            if (0x20 <= b && b < 0x7f) {
                output += String(bytes: [b], encoding: .ascii)!
            }else{
                output += "?"
            }
        }
        
        return output
    }
}
