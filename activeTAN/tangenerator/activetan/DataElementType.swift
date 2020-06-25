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

enum DataElementType : CaseIterable{
    case address, quote, quantity, orderId, authToken, bankData, amount, bicRecipient, bankCodeSender, bankCodeRecipient, bankCodeCard, bankCodePayer, bankCodeOwn, ibanOwn, accountNumberOwn, merchant, ibanSender, ibanRecipient, ibanPayer, isin, cardNumber, accountNumberSender, accountNumberRecipient, accountNumberPayer, creditCard, limit, volume, mobilePhone, nameRecipient, postCode, rate, referenceAccountNumber, referenceNumber, pieces, tanMedia, date, contract, wkn, accountSender, accountRecipient, accountPayer, currency, orderType, assets, bankRecipient, product


    var attr:DataElementTypeAttributes{
        switch self {
        case .address:
            return DataElementTypeAttributes(10, "Adresse:", .alphanumeric, 36)
        case .quote:
            return DataElementTypeAttributes(11, "Angebots-Nr:",.alphanumeric, 12)
        case .quantity:
            return DataElementTypeAttributes(12, "Anzahl:", .numeric, 12)
        case .orderId:
            return DataElementTypeAttributes(13, "Auftrags-ID:", .alphanumeric, 12)
        case .authToken:
            return DataElementTypeAttributes(14, "Aut.Merkmal:", .alphanumeric, 12)
        case .bankData:
            return DataElementTypeAttributes(15, "Bankdaten:", .alphanumeric, 12)
        case .amount:
            return DataElementTypeAttributes(16, "Betrag:", .numeric, 12, 2)
        case .bicRecipient:
            return DataElementTypeAttributes(17, "BIC Empf.:", .alphanumeric, 12)
        case .bankCodeSender:
            return DataElementTypeAttributes(18, "BLZ Abs.:", .numeric, 12)
        case .bankCodeRecipient:
            return DataElementTypeAttributes(19, "BLZ Empf.:", .numeric, 12)
        case .bankCodeCard:
            return DataElementTypeAttributes(20, "BLZ Karte:", .numeric, 12)
        case .bankCodePayer:
            return DataElementTypeAttributes(21, "BLZ Zahler:", .numeric, 12)
        case .bankCodeOwn:
            return DataElementTypeAttributes(22, "Eigene BLZ:", .numeric, 12)
        case .ibanOwn:
            return DataElementTypeAttributes(23, "Eigene IBAN:", .alphanumeric, 36)
        case .accountNumberOwn:
            return DataElementTypeAttributes(24, "Eigenes Kto:", .numeric, 12)
        case .merchant:
            return DataElementTypeAttributes(26, "Händlername:", .alphanumeric, 36)
        case .ibanSender:
            return DataElementTypeAttributes(29, "IBAN Abs.:", .alphanumeric, 36)
        case .ibanRecipient:
            return DataElementTypeAttributes(32, "IBAN Empf.:", .alphanumeric, 36)
        case .ibanPayer:
            return DataElementTypeAttributes(33, "IBAN Zahler", .alphanumeric, 36) // sic!
        case .isin:
            return DataElementTypeAttributes(36, "ISIN:", .alphanumeric, 12)
        case .cardNumber:
            return DataElementTypeAttributes(37, "Kartennummer", .alphanumeric, 12)
        case .accountNumberSender:
            return DataElementTypeAttributes(38, "Konto Abs.:", .numeric, 12)
        case .accountNumberRecipient:
            return DataElementTypeAttributes(39, "Konto Empf.:", .numeric, 12)
        case .accountNumberPayer:
            return DataElementTypeAttributes(40, "Konto Zahler", .numeric, 12)
        case .creditCard:
            return DataElementTypeAttributes(41, "Kreditkarte:", .numeric, 12)
        case .limit:
            return DataElementTypeAttributes(42, "Limit:", .numeric, 12, 2)
        case .volume:
            return DataElementTypeAttributes(43, "Menge:", .numeric, 12, 3)
        case .mobilePhone:
            return DataElementTypeAttributes(44, "Mobilfunknr:", .alphanumeric, 17)
        case .nameRecipient:
            return DataElementTypeAttributes(45, "Name Empf.:", .alphanumeric, 12)
        case .postCode:
            return DataElementTypeAttributes(46, "Postleitzahl", .alphanumeric, 12)
        case .rate:
            return DataElementTypeAttributes(47, "Rate:", .numeric, 12, 2)
        case .referenceAccountNumber:
            return DataElementTypeAttributes(48, "Referenzkto:", .numeric, 12)
        case .referenceNumber:
            return DataElementTypeAttributes(49, "Referenzzahl", .alphanumeric, 36)
        case .pieces:
            return DataElementTypeAttributes(50, "Stücke/Nom.:", .numeric, 12, 3)
        case .tanMedia:
            return DataElementTypeAttributes(51, "TAN-Medium", .alphanumeric, 12) // sic!
        /* According to chipTAN specification DE52 must be numeric.
         * However, the date is formatted by the backend. Disable numeric formatting locally.
         */
        case .date:
            return DataElementTypeAttributes(52, "Termin:", .alphanumeric, 12)
        case .contract:
            return DataElementTypeAttributes(53, "Vertrag.Kenn", .alphanumeric, 12)
        case .wkn:
            return DataElementTypeAttributes(54, "WP-Kenn-Nr:", .alphanumeric, 12)
        case .accountSender:
            return DataElementTypeAttributes(55, "Konto Abs.:", .alphanumeric, 12)
        case .accountRecipient:
            return DataElementTypeAttributes(56, "Konto Empf.:", .alphanumeric, 12)
        case .accountPayer:
            return DataElementTypeAttributes(57, "Konto Zahler", .alphanumeric, 12)
        case .currency:
            return DataElementTypeAttributes(58, "Währung:", .alphanumeric, 3)
        case .orderType:
            return DataElementTypeAttributes(61, "Auftragsart:", .alphanumeric, 12)
        case .assets:
            return DataElementTypeAttributes(62, "Anz.Posten:", .numeric, 12) // sic!
        case .bankRecipient:
            return DataElementTypeAttributes(63, "Bank Empf.:", .alphanumeric, 36)
        case .product:
            return DataElementTypeAttributes(64, "Produkt:", .alphanumeric, 36)
        }
    }
    
    static var byId : [Int : DataElementType] {
        var _byId = [Int : DataElementType]()
        DataElementType.allCases.forEach {
            _byId[$0.attr.id] = $0
        }
        return _byId
    }
    
    static func forId(id : Int) -> DataElementType?{
        return byId[id]
    }
}

class DataElementTypeAttributes {
    let id : Int!
    let visDataLine1: String!
    let format: Format!
    let maxLength : Int!
    let integerDigits : Int!
    let fractionDigits : Int!
    
    init(_ id : Int, _ visDataLine1: String, _ format : Format, _ maxLength : Int){
        self.id = id
        self.visDataLine1 = visDataLine1
        self.format = format
        self.maxLength = maxLength
        integerDigits = 0
        fractionDigits = 0
    }
    
    init(_ id : Int, _ visDataLine1: String, _ format : Format, _ maxLength : Int, _ fractionDigits : Int){
        self.id = id
        self.visDataLine1 = visDataLine1
        self.format = format
        self.maxLength = maxLength
        self.fractionDigits = fractionDigits
        
        if maxLength < 0 {
            fatalError("illegal maximum length")
        }
        
        if format == .numeric {
            if fractionDigits == 0 {
                self.integerDigits = maxLength
            } else {
                self.integerDigits = maxLength - 1 - fractionDigits // -1 because of decimal point
                if integerDigits < 0 {
                    fatalError("fraction digits exceeds maximum length")
                }
            }
        } else{
            if fractionDigits != 0 {
                fatalError("only numeric format may use fraction digits")
            }
            self.integerDigits = 0
        }
        
        if format == .alphanumeric && fractionDigits != 0 {
            fatalError("alphanumeric format cannot use fraction digits")
        }
    }

    enum Format {
        case alphanumeric, numeric
    }
}
