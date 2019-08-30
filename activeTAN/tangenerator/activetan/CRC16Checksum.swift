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

class CRC16Checksum {
    private var table : [Int]?
    
    // Polynomial x^16 + x^15 + x^2 + 1 with LSB
    private let DIVISOR = 0xa001;

    private final let initialValue : Int!
    
    private var crc : Int!
    
    init(_ initialValue : Int){
        self.initialValue = initialValue
        initializeLookupTable()
        self.crc = initialValue
    }
    
    private func initializeLookupTable(){
        if table == nil {
            table = [Int](repeating: 0, count: 256)
            for idx in 0 ... table!.count-1 {
                var value = idx
                for _ in 0 ... 7 {
                    if value & 1 != 0 {
                        value = (value >> 1) ^ DIVISOR
                    } else {
                        value = (value >> 1)
                    }
                }
                table![idx] = value
            }
        }
    }
    
    func update(_ b : Int){
        crc = (crc >> 8) ^ (table![(crc ^ b) & 0xff]);
    }
    
    func update(b : [UInt8], off : Int, len : Int){
        let start = max(0, off)
        let end = min(b.count, off + len)
        for idx in start ... end-1 {
            update(Int(b[idx] & 0xff))
        }
    }
    
    func getCrc() -> Int {
        return crc
    }

}
