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

class LuhnChecksum {
    private var sum : Int = 0
    
    func update(b : [UInt8], off : Int, len : Int) {
        let start = max(0, off)
        let end = min(b.count, off + len)
        if end > 0 {
            for idx in start...end-1{
                update(Int(b[idx] & 0xff))
            }
        }
    }

    func update(_ b : Int) {
        let firstNibble = (b & 0xf0) >> 4;
        var secondNibble = b & 0x0f
        
        secondNibble *= 2
        
        if (secondNibble > 9) {
            secondNibble = (secondNibble / 10) + (secondNibble % 10);
        }
        
        self.sum += firstNibble + secondNibble
    }
    
    func getValue() -> Int {
        let luhnDigit = (10 - (sum % 10)) % 10
        
        return luhnDigit

    }
}
