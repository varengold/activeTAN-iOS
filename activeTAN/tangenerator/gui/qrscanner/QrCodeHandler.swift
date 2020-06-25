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

import ZXingObjC

// Filter and parse QR codes in Banking QR code format
class QrCodeHandler {
    
    private final var listener : BankingQrCodeListener!
    
    init(_ listener: BankingQrCodeListener){
        self.listener = listener
    }
    
    func handleResult(result: ZXResult) throws{
        print("Barcode detected")
        
        var bqr : [UInt8]!
        
        bqr = try extractBinaryQrCodeContent(result: result)
        
        if bqr.count < 4 {
            throw NoBankingQrCodeError.error("no BQR container, data too short")
        }
        
        unscramble(bqr: &bqr)
        
        if !checkCrc16(bqr: bqr) {
            throw NoBankingQrCodeError.error("invalid CRC-16 checksum")
        }
        
        // 2 bytes prefix
        // wrapped content
        // 2 bytes CRC-16
        guard let contents = Utils.copyOfRange(arr: bqr, from: 2, to: bqr.count-2) else{
            throw NoBankingQrCodeError.error("invalid BQT container")
        }
        
        if contents.count == 0 {
            throw NoBankingQrCodeError.error("empty BQR container")
        }
        
        // 'DK' prefix: chipTAN QR codes with transaction data
        if bqr[0] == 0x44 && bqr[1] == 0x4b {
            do {
                let amsFlag = try readAmsFlag(byteArray: contents)
                var count = 1
                let hhduc = try extractDataBlock(byteArray: Array(contents[1...contents.count-1]))
                count += hhduc.count
                if amsFlag {
                    // skip optional AMS data block
                    // content is ignored
                    let ams = try extractDataBlock(byteArray: Array(contents[hhduc.count...contents.count-1]))
                    count += ams.count
                }
                if contents.count > count {
                    throw NoBankingQrCodeError.error("Unexpected data after last block found")
                }
                listener.onTransactionData(hhduc: hhduc)
            } catch NoBankingQrCodeError.error(let message) {
                listener.onInvalidBankingQrCode(detailReason: message)
            }
            return
        }
        
        // 'KM' prefix: key material for device initialization
        if (bqr[0] == 0x4b && bqr[1] == 0x4d) {
            listener.onKeyMaterial(hhdkm: contents)
            return
        }

        throw NoBankingQrCodeError.error("unsupported prefix")
    }
    
    private func extractBinaryQrCodeContent(result: ZXResult) throws ->[UInt8]{
        if (kBarcodeFormatQRCode != result.barcodeFormat) {
            // This should not happen, ZXing can ignore other barcode formats.
            assert(false);
            throw NoBankingQrCodeError.error("Barcode is not in QR code format")
        }

        let rawBytes = result.rawBytes.array
        let rawBytesLength = Int(result.rawBytes!.length)
        
        if (rawBytesLength < 2) {
            // The raw data must be at lease 2 bytes long:
            //  - 1 half-byte for mode indicator
            //  - 1 byte for data length (2 bytes for long data)
            //  - data
            //  - 1 half-byte for end of message terminator
            //  - padding
            throw NoBankingQrCodeError.error("Not a valid QR code, no data has been read")
        }
        
        var byteArray = [UInt8] ()
        // The byte values are offset by 4 bits, because of the mode indicator. Undo this.
        // We lose the last 4 bits, which might include the mandatory end of message terminator.
        let bufferPointer = Array(UnsafeBufferPointer(start: rawBytes, count: rawBytesLength))
        var temp: UInt8 = 0
        for (index, value) in bufferPointer.enumerated() {
            let valueUnsigned = UInt8(bitPattern: value)
            if index > 0 {
                let firstHalfByte = (temp & 0x0f) << 4;
                let secondHalfByte = (valueUnsigned & 0xf0) >> 4;
                
                byteArray.append(firstHalfByte | secondHalfByte)
            }else{
                // First byte indicates mode which must be BYTE
                if ZXQRCodeMode.forBits(Int32(valueUnsigned & 0xf0) >> 4) != ZXQRCodeMode.byte() {
                    throw NoBankingQrCodeError.error("QR code is not in byte encoding mode")
                }
            }
            
            temp = valueUnsigned
        }
        
        let length:UInt16
        let contentOffset:UInt16
        if (byteArray.count >= 256) {
            // For long messages the length is encoded with 2 bytes (unsigned integer)
            length = UInt16(byteArray[0]) << 8 | UInt16(byteArray[1])
            contentOffset = 2;
        } else {
            // For short messages the length is encoded with 1 byte (unsigned integer)
            length = UInt16(byteArray[0]);
            contentOffset = 1;
        }
        
        let content:[UInt8] = Utils.copyOfRange(arr: byteArray, from: Int(contentOffset), to: Int(contentOffset + length))!
        
        return content
    }
    
    private func unscramble(bqr: inout [UInt8]) {
        if (bqr.count < 2) {
            return;
        }
        for i in 2...bqr.count-1 {
            bqr[i] = UInt8(UInt16(bqr[i]) ^ UInt16(bqr[i % 2]))
        }
    }
    
    private func checkCrc16(bqr: [UInt8]) -> Bool{
        let expectedChecksum = UInt16(bqr[bqr.count - 2]) << 8 | UInt16(bqr[bqr.count - 1])
        
        let crc16checksum = CRC16Checksum(0)
        crc16checksum.update(b: bqr, off: 0, len: bqr.count-2)
        let actualChecksum = crc16checksum.getCrc()
        
        return expectedChecksum == actualChecksum
    }
    
    private func readAmsFlag(byteArray : [UInt8]) throws -> Bool {
        if byteArray.count < 1 {
            throw NoBankingQrCodeError.error("No AMS flag available")
        }
        
        let flag = byteArray[0]
        
        switch flag {
        case 0x4e: // N
            return false
        case 0x4a: // J
            return true
        default:
            throw NoBankingQrCodeError.error("Invalid AMS flag value")
        }
    }
    
    private func extractDataBlock(byteArray : [UInt8]) throws -> [UInt8] {
        // according to specification, maximum length is limited to 255 Bytes
        if byteArray.count < 1 {
            throw NoBankingQrCodeError.error("No data block available")
        }
        
        let length = Int(byteArray[0])

        if let block = Utils.copyOfRange(arr: byteArray, from: 0, to: length+1) {
            return block
        }
        
        throw NoBankingQrCodeError.error("Data block invalid")
    }
}
