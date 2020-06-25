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

import UIKit

class VisDataBuffer {
    private static let fieldSeparator = 0xe1
    private static let startCodeSeparator = 0xe0
    private static let maxDatablockLength = 12
    private static let maxHashLength = 29

    var content : Data
    
    init(){
        content = Data()
    }
    
    private func write(_ data : [UInt8]){
        content.append(contentsOf: data)
    }
    
    private func write(_ b : Int){
        content.append(UInt8(b))
    }
    
    private func write(_ text : String){
        write(DKCharset.encode(input: text))
    }
    
    func write(hhduc : HHDuc) {
        var numDataBlocks = 0
        
        write(VisDataBuffer.fieldSeparator)
        write("Start-Code:")
        numDataBlocks += 1
        
        write(VisDataBuffer.startCodeSeparator)
        write(hhduc.getStartCode())
        numDataBlocks += 1
        
        if let _visClass = hhduc.visualisationClass {
            write(VisDataBuffer.fieldSeparator)
            write(_visClass.attr.visDataLine1)
            numDataBlocks += 1
            
            if !_visClass.attr.visDataLine2.isEmpty {
                write(VisDataBuffer.fieldSeparator)
                write(_visClass.attr.visDataLine2)
                numDataBlocks += 1
            }
        }

        for dataElementType in hhduc.getDataElementTypes() {
            var label = dataElementType.attr.visDataLine1!
            let value = try! hhduc.getDataElement(type: dataElementType)
            
            for i in stride(from: 0, to: value.count, by: VisDataBuffer.maxDatablockLength) {
            
                if value.count > VisDataBuffer.maxDatablockLength {
                    while label.count < VisDataBuffer.maxDatablockLength-1 {
                        label += " "
                    }
                    
                    label = String(label.prefix(VisDataBuffer.maxDatablockLength-1))
                    label += String(i / VisDataBuffer.maxDatablockLength + 1)
                }
                
                write(VisDataBuffer.fieldSeparator)
                write(label)
                numDataBlocks += 1
                
                write(VisDataBuffer.fieldSeparator)
                
                let start = value.index(value.startIndex, offsetBy: i)
                let x = min(value.count, i + VisDataBuffer.maxDatablockLength)
                let end = value.index(value.startIndex, offsetBy: x)
                let range = start..<end
                
                write(String(value[range]))
                numDataBlocks += 1
            }
        }
        
        if (numDataBlocks < 0x0f) {
            write(0xb0 | numDataBlocks)
        } else {
            write(0xbf)
            write(numDataBlocks)
        }
    }
    
    func getHash() -> [UInt8] {
        var digest = content.sha256()
        if digest.count > VisDataBuffer.maxHashLength {
            digest = digest.prefix(VisDataBuffer.maxHashLength)
        }
        return [UInt8](digest)
    }
    
}
