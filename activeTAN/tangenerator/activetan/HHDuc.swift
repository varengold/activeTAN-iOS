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

class HHDuc {

    // Legacy start codes have a maximum of 8 digits.
    private static let maxShortStartCodeDigits = 8
    
    // Start codes with visualization class (prefix 1 and 2) have a maximum of 12 digits.
    private static let maxStartCodeDigits = 12

    private var unpredictableNumber : Int?
    let visualisationClass : VisualisationClass!
    private var dataElements = [DataElement]() // use tuples to keep array order

    // Create a new, empty HHDuc object without visualization class.
    init(){
        self.visualisationClass = nil
    }
    
    // Create a new, empty HHDuc object for the specified visualisation class with the default data elements of the visualisation class.
    init(visualisationClass : VisualisationClass){
        self.visualisationClass = visualisationClass
        
        for de in visualisationClass.attr.dataElements {
            dataElements.append(DataElement(dataElementType: de, value: ""))
        }
    }

    // Create a new, empty HHDuc object for the specified visualisation class with custom data elements.
    init(visualisationClass : VisualisationClass, selectedElements : [DataElementType]){
        self.visualisationClass = visualisationClass
        for se in selectedElements {
            dataElements.append(DataElement(dataElementType: se, value: ""))
        }
    }
    
    func getDataElement(type : DataElementType) throws -> String {
        let element = dataElements.filter {$0.dataElementType == type}.first
        if element != nil {
            return element!.value
        }
        throw GeneralError.noSuchElement("Data element type is not in list")
    }
    
    func setDataElement(type : DataElementType, value : String) throws {
        var _value = String(value)
        
        if let row = dataElements.firstIndex(where: {$0.dataElementType == type}) {
            if type.attr.maxLength < _value.count {
                let ellipsis = "..."
                _value = _value.prefix(type.attr.maxLength - ellipsis.count) + ellipsis
            }
            
            dataElements[row] = DataElement(dataElementType: type, value: _value)
        }else{
             throw GeneralError.noSuchElement("\(type) is not available for this HHDuc")
        }
    }

    func setDataElement(type : DataElementType, value : Int64) throws {
        if type.attr.format != .numeric {
            throw GeneralError.illegalArgument("\(type) is not numeric")
        }
        
        try setDataElement(type: type, value: String(value))
    }

    func getDataElementTypes() -> [DataElementType] {
        return dataElements.map{ $0.dataElementType }
    }

    
    func setUnpredictableNumber(unpredictableNumber : Int) throws {
        if unpredictableNumber < 0 {
            throw GeneralError.illegalArgument("Random number cannot be negative")
        }
        self.unpredictableNumber = unpredictableNumber
    }
    
    func getStartCode() -> [UInt8] {
        var startCode : String = ""
        
        var maxDigits : Int
        if visualisationClass == nil {
            maxDigits = HHDuc.maxShortStartCodeDigits
            
            // Special case:
            // The only supported case for HHDuc w/o visualisation class is start code '08...'
            // for static TAN computation with display of the ATC.
            startCode.append("08")
        } else {
            maxDigits = HHDuc.maxStartCodeDigits
            
            if visualisationClass.attr.dataElements.elementsEqual(getDataElementTypes()) {
                startCode.append("1")
                startCode.append(String(format: "%02d", visualisationClass.attr.id))
            } else {
                startCode.append("2")
                startCode.append(String(format:"%02d", visualisationClass.attr.id))
                
                for dataElement in dataElements {
                    startCode.append(String(format:"%02d", dataElement.dataElementType.attr.id))
                }
                
                if dataElements.count < 3 {
                    startCode.append("0")
                }
            }

        }
        let format = "%0" + String(maxDigits) + "d"
        let randomNumber = String(format: format, unpredictableNumber!)
        
        startCode.append(String(randomNumber.suffix(maxDigits - startCode.count)))
        
        assert(startCode.count == maxDigits)
        
        return FieldEncoding.bcdEncode(number: startCode)
    }
    
    // In Germany only one value is allowed according to HHDuc version 1.4
    private static let hhdControlByte = 0x01;

    static func parse(rawBytes : [UInt8]) throws -> HHDuc {
        var bytePos = 0
        // LC
        do {
            let challengeLength = Int(rawBytes[bytePos])
            bytePos += 1
            if challengeLength != rawBytes.count - bytePos {
                throw UnsupportedDataFormatError.error("LC contains wrong value")
            }
        }
        
        // LS
        let startCodeLength : Int
        let startCodeFormat : FieldEncoding
        do {
            let lsByte = Int(rawBytes[bytePos])
            bytePos += 1
            if lsByte < 0 {
                throw UnsupportedDataFormatError.error("LS is missing")
            }
            
            let withControlByte = Bool((lsByte & 0x80) != 0)
            startCodeFormat = (lsByte & 0x40) != 0 ? FieldEncoding.ascii : FieldEncoding.bcd
            startCodeLength = Int(lsByte & 0x3f)
            
            // the control byte has been introduced with HHDuc version 1.4
            if !withControlByte {
                throw UnsupportedDataFormatError.error("Control byte missing according to LS")
            }
        }
        
        // Control
        let controlByte : Int
        do {
            controlByte = Int(rawBytes[bytePos])
            bytePos += 1
            if (controlByte < 0) {
                throw UnsupportedDataFormatError.error("Control is missing")
            }
            
            if controlByte != hhdControlByte {
                throw UnsupportedDataFormatError.error("Control has unknown value")
            }
        }
        
        // Start Code
        let startCode : [UInt8]
        do {
            if rawBytes.count - bytePos < startCodeLength {
                throw UnsupportedDataFormatError.error("Start code is missing")
            }
            startCode = Utils.copyOfRange(arr: rawBytes, from: bytePos, to: startCodeLength+bytePos)!
            bytePos += startCodeLength
        }
        
        // Data elements 1..3
        var dataElementEncodings = [FieldEncoding]()
        var dataElements = [[UInt8]]()
        
        while bytePos < rawBytes.count-1 {
            let ldeByte = rawBytes[bytePos]
            
            let encoding : FieldEncoding = ((ldeByte & 0x40) != 0) ? .ascii : .bcd
            let length = Int(ldeByte & 0x3f)
            
            if rawBytes.count - bytePos - 1 < length {
                throw UnsupportedDataFormatError.error("DE\(dataElements.count + 1) is incomplete")
            }
            
            if length > 36 || (encoding == .bcd && length > 18) {
                throw UnsupportedDataFormatError.error("DE\(dataElements.count + 1) exceeds the maximum length")
            }
            bytePos += 1
            
            var de = [UInt8](repeating: 0, count: length)
            if length > 0 {
                for i in 0...length-1 {
                    de[i] = rawBytes[bytePos]
                    bytePos += 1
                }
            }
            dataElementEncodings.append(encoding)
            dataElements.append(de)
        }
        
        // Check byte
        do {
            if bytePos != rawBytes.count-1 {
                throw UnsupportedDataFormatError.error("Check byte is missing")
            }
            
            let checkByte = rawBytes[bytePos]
            
            let luhnDigit = LuhnChecksum()
            luhnDigit.update(controlByte)
            luhnDigit.update(b: startCode, off: 0, len: startCode.count)
            
            for dataElement in dataElements {
                luhnDigit.update(b: dataElement, off: 0, len: dataElement.count)
            }
            
            let xor = XorChecksum()
            xor.update(b: rawBytes, off: 0, len: rawBytes.count-1)
            
            let computedCheckByte = (luhnDigit.getValue() << 4) | xor.getValue()
            
            if checkByte != computedCheckByte {
                throw UnsupportedDataFormatError.error("Check byte is wrong")
            }
            
        }
        
        return try parseApplicationData(startCodeEncoding: startCodeFormat, rawStartCode: startCode, dataElementEncodings: dataElementEncodings, rawDataElements: dataElements)
    }
    
    
    private static func parseApplicationData(startCodeEncoding : FieldEncoding, rawStartCode : [UInt8], dataElementEncodings : [FieldEncoding], rawDataElements : [[UInt8]]) throws -> HHDuc {
        assert(dataElementEncodings.count == rawDataElements.count)
        
        let startCode : Int64
        switch startCodeEncoding {
        case .ascii:
            if let _startCode = Int64(DKCharset.decode(input: rawStartCode)){
                startCode = _startCode
            } else {
                throw UnsupportedDataFormatError.error("Start code is not numeric")
            }
            break
        case .bcd:
            do {
                startCode = Int64(try FieldEncoding.bcdDecode(data: rawStartCode))
            } catch FieldEncodingError.numberFormat(let message){
                throw UnsupportedDataFormatError.error("Illegal start code format: \(message)")
            }
            break
        default:
            throw UnsupportedDataFormatError.error("Unsupported start code encoding")
        }
        
        var hhduc : HHDuc
        
        if 8_000_000 <= startCode && startCode <= 8_999_999 {
            // Start code prefix 08: No visualization class
            hhduc = HHDuc()
            try hhduc.setUnpredictableNumber(unpredictableNumber: Int(startCode % 1_000_000))
        } else {
            if startCode < 100_000_000_000 || startCode > 299_999_999_999 {
                throw UnsupportedDataFormatError.error("Only start codes with length 12 and prefix 1 or 2 are supported")
            }
            
            let vc = Int(startCode / 1_000_000_000) % 100
            guard let visualisationClass = VisualisationClass.forId(id: vc) else{
                throw UnsupportedDataFormatError.error("Visualisation class \(vc) unknown")
            }
            
            if startCode < 200_000_000_000 {
                hhduc = HHDuc(visualisationClass: visualisationClass)
                try hhduc.setUnpredictableNumber(unpredictableNumber: Int(startCode % 1_000_000_000))
            } else {
                var dataElements =  [DataElementType?]()
                
                let unpredictableNumber : Int
                
                let p = Int((startCode / 10_000_000) % 100)
                let s = Int((startCode / 100_000) % 100)
                let t = Int((startCode / 1000) % 100)
                if p >= 10 {
                    dataElements.append(DataElementType.forId(id: p))
                    
                    if s >= 10 {
                        dataElements.append(DataElementType.forId(id: s))
                        if t >= 10 {
                            dataElements.append(DataElementType.forId(id: t))
                            unpredictableNumber = Int(startCode % 1000)
                        } else {
                            unpredictableNumber = Int(startCode % 10_000)
                        }
                    } else {
                        unpredictableNumber = Int(startCode % 1_000_000)
                    }
                } else {
                    unpredictableNumber = Int(startCode % 100_000_000)
                }
                
                for dataElement in dataElements {
                    if dataElement == nil {
                        throw UnsupportedDataFormatError.error("Start code contains an unknown data element ID")
                    }
                }
                
                hhduc = HHDuc(visualisationClass: visualisationClass, selectedElements: dataElements as! [DataElementType])
                try hhduc.setUnpredictableNumber(unpredictableNumber: unpredictableNumber)
            }

        }
        
        let definedTypes = hhduc.getDataElementTypes()
        if definedTypes.count < rawDataElements.count {
            throw UnsupportedDataFormatError.error("More data elements provided than declared by the start code")
        }
        
        if !rawDataElements.isEmpty {
            for i in 0...rawDataElements.count-1 {
                let type = definedTypes[i]
                switch dataElementEncodings[i] {
                case .ascii:
                    let stringValue = DKCharset.decode(input: rawDataElements[i])
                    try hhduc.setDataElement(type: type, value: stringValue)
                    break;
                    
                case .bcd:
                    if type.attr.format != .numeric {
                        throw UnsupportedDataFormatError.error("Only numeric data can be BCD coded")
                    }
                    if rawDataElements[i].isEmpty {
                        try hhduc.setDataElement(type: type, value: "")
                    } else {
                        let longValue : Int64
                        do {
                            longValue = Int64(try FieldEncoding.bcdDecode(data: rawDataElements[i]))
                        } catch FieldEncodingError.numberFormat(let message) {
                            throw UnsupportedDataFormatError.error("Illegal numeric data: \(message)")
                        }
                        try hhduc.setDataElement(type: type, value: longValue)
                    }
                    break;
                    
                default:
                    throw UnsupportedDataFormatError.error("Unsupported data element encoding")
                }
            }
        }
        
        return hhduc

    }
    
    func getBytes() -> [UInt8] {
        var baos = Data()
        let luhnDigit = LuhnChecksum()
        
        // LC, will de defined later
       baos.append(0)
        
        // Start code
        do {
            let startCodeEncoded = getStartCode()
            
            // LS, with control byte, BCD encoding
            baos.append(UInt8 (0x80 | startCodeEncoded.count))
            
            // Control byte
            baos.append(UInt8(HHDuc.hhdControlByte))
            luhnDigit.update(HHDuc.hhdControlByte)

            // Start code
            baos.append(contentsOf: startCodeEncoded)
            luhnDigit.update(b: startCodeEncoded, off: 0, len: startCodeEncoded.count)
        }
        
        for entry in dataElements {
            let type = entry.dataElementType
            let value = entry.value
            
            var valueEncoded : [UInt8]
            if type.attr.format == .numeric && type.attr.fractionDigits == 0
                && !value.contains("-") {
                // non-negative integers can be BCD encoded
                valueEncoded = FieldEncoding.bcdEncode(number: value)
                
                // L(DEx), BCD encoding
                baos.append(UInt8(valueEncoded.count))
            } else {
                valueEncoded = DKCharset.encode(input: value)
                
                // L(DEx), ASCII encoding
                baos.append(UInt8(0x40 | valueEncoded.count))
            }
            
            baos.append(contentsOf: valueEncoded);
            luhnDigit.update(b: valueEncoded, off: 0, len: valueEncoded.count);
            
        }
        
        // Check byte, will be computed later
        baos.append(0)
        
        var challenge = baos.bytes
        
        // LC
        challenge[0] = UInt8(baos.count - 1)
        
        // Control byte
        let xor = XorChecksum()
        xor.update(b: challenge, off: 0, len: challenge.count - 1)
        let controlByte = UInt8((luhnDigit.getValue() << 4) | xor.getValue())
        challenge[challenge.count - 1] = controlByte
        
        return challenge

    }
    
    
    struct DataElement {
        var dataElementType : DataElementType
        var value : String
    }
    
    enum UnsupportedDataFormatError : Error {
       case error(String)
    }

}
