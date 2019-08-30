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

enum VisualisationClass : CaseIterable {
    case empty, userAuthentication01, creditTransferNational, transfer, transferScheduled, creditTransferReferenceAccount07, creditTransferReferenceAccount08, creditTransferSepa, creditTransferForeign10, creditTransferForeignCheque, CollectiveTransferNational, collectiveTransferSepa, collectiveTransferForeign, directDebitNational, directDebitReturn16, directDebitASepa, directDebitForeign, collectiveDebitNational, collectiveDebitSepa, collectiveDebitForeign, creditTransferNationalScheduled, creditTransferSepaScheduled, creditTransferForeignScheduled, collectiveTransferNationalScheduled, collectiveTransferSepaScheduled, collectiveTransferForeignScheduled, directDebitNationalScheduled, directDebitSepaScheduled, directDebitForeignScheduled, collectiveDebitNationalScheduled, collectiveDebitSepaScheduled, collectiveDebitForeignScheduled, standingOrderNational, standingOrderSepa, standingOrderForeign, standingOrderDebitNational, standingOrderDebitSepa, portfolioRetrieval, deleteOrder40, stopOrderCreditTransfer41, stopOrderDirectDebit42, updateOrderCreditTransfer43, updateOrderDebitTransfer44, releaseCreditTransfersNational, releaseDirectDebitsNational, releaseCreditTransferForeign, releaseCreditTransfersSepa, releaseDirectDebitsSepa, releaseFiles, electronicStatement, electronicStatementSubscribe, electronicMailboxSubscribe, electronicMailbox, dataVault, securitiesBuy, securitiesSell, securitiesTrade, contractAsset, contractLoan, contractProduct, contractInsurance, masterDataManagement, tanManagement, chargeMobilePhone, chargeChipCard, internetPayment67, internetMoneyTransfer, exemptionOrder, addressChange70, addressChange71, creditTransferForeign72, creditTransferForeign73, directDebitReturn74, deleteOrder75, deleteOrder76, stopOrderCreditTransfer77, stopOrderDirectDebit78, updateOrderCreditTransfer79, updateOrderDebitTransfer80, internetPayment81

    
    var attr:VisualisationClassAttributes{
        switch self {
        case .empty:
            return VisualisationClassAttributes(0, "Bankauftrag", "allgemein")
        case .userAuthentication01:
            return VisualisationClassAttributes(1, "Legitimation", "Kunde", .authToken)
        case .creditTransferNational:
            return VisualisationClassAttributes(4, "Überweisung", "Inland", .accountNumberRecipient, .bankCodeRecipient, .amount)
        case .transfer:
            return VisualisationClassAttributes(5, "Umbuchung", "", .accountNumberRecipient, .amount)
        case .transferScheduled:
            return VisualisationClassAttributes(6, "Umbuchung", "terminiert", .accountNumberRecipient, .amount, .date)
        case .creditTransferReferenceAccount07:
            return VisualisationClassAttributes(7, "Überweisung", "Referenzkto", .referenceAccountNumber, .amount)
        case .creditTransferReferenceAccount08:
            return VisualisationClassAttributes(8, "Überweisung", "Referenzkto", .ibanRecipient, .amount)
        case .creditTransferSepa:
            return VisualisationClassAttributes(9, "Überweisung", "SEPA/EU", .ibanRecipient, .amount)
        case .creditTransferForeign10:
            return VisualisationClassAttributes(10, "Überweisung", "Ausland", .accountNumberRecipient, .amount)
        case .creditTransferForeignCheque:
            return VisualisationClassAttributes(11, "Überweisung", "Ausland", .nameRecipient, .amount)
        case .CollectiveTransferNational:
            return VisualisationClassAttributes(12, "Sammelüberw.", "Inland", .accountNumberOwn, .amount, .quantity)
        case .collectiveTransferSepa:
            return VisualisationClassAttributes(13, "Sammelüberw.", "SEPA", .ibanOwn, .amount, .quantity)
        case .collectiveTransferForeign:
            return VisualisationClassAttributes(14, "Sammelüberw.", "Ausland", .accountNumberOwn, .amount, .quantity)
        case .directDebitNational:
            return VisualisationClassAttributes(15, "Lastschrift", "Inland", .accountNumberPayer, .bankCodePayer, .amount)
        case .directDebitReturn16:
            return VisualisationClassAttributes(16, "Rückgabe", "Lastschrift", .accountNumberRecipient, .bankCodeRecipient, .amount)
        case .directDebitASepa:
            return VisualisationClassAttributes(17, "Lastschrift", "SEPA", .ibanPayer, .amount)
        case .directDebitForeign:
            return VisualisationClassAttributes(18, "Lastschrift", "Ausland", .accountNumberPayer, .amount)
        case .collectiveDebitNational:
            return VisualisationClassAttributes(19, "Sammellasts.", "Inland", .accountNumberOwn, .amount, .quantity)
        case .collectiveDebitSepa:
            return VisualisationClassAttributes(20, "Sammellasts.", "SEPA", .ibanOwn, .amount, .quantity)
        case .collectiveDebitForeign:
            return VisualisationClassAttributes(21, "Sammellasts.", "Ausland", .accountNumberOwn, .amount, .quantity)
        case .creditTransferNationalScheduled:
            return VisualisationClassAttributes(22, "Terminüberw.", "Inland", .accountNumberRecipient, .bankCodeRecipient, .amount)
        case .creditTransferSepaScheduled:
            return VisualisationClassAttributes(23, "Terminüberw.", "SEPA", .ibanRecipient, .amount)
        case .creditTransferForeignScheduled:
            return VisualisationClassAttributes(24, "Terminüberw.", "Ausland", .accountNumberRecipient, .amount)
        case .collectiveTransferNationalScheduled:
            return VisualisationClassAttributes(25, "Terminüberw.", "Sammel Inl.", .accountNumberOwn, .amount, .quantity)
        case .collectiveTransferSepaScheduled:
            return VisualisationClassAttributes(26, "Terminüberw.", "Sammel SEPA", .ibanOwn, .amount, .quantity)
        case .collectiveTransferForeignScheduled:
            return VisualisationClassAttributes(27, "Terminüberw.", "Sammel Ausl.", .accountNumberOwn, .amount, .quantity)
        case .directDebitNationalScheduled:
            return VisualisationClassAttributes(28, "Terminlasts.", "Inland", .accountNumberPayer, .bankCodePayer, .amount)
        case .directDebitSepaScheduled:
            return VisualisationClassAttributes(29, "Terminlasts.", "SEPA", .ibanPayer, .amount)
        case .directDebitForeignScheduled:
            return VisualisationClassAttributes(30, "Terminlasts.", "Ausland", .accountNumberPayer, .amount)
        case .collectiveDebitNationalScheduled:
            return VisualisationClassAttributes(31, "Terminlasts.", "Sammel Inl.", .accountNumberOwn, .amount, .quantity)
        case .collectiveDebitSepaScheduled:
            return VisualisationClassAttributes(32, "Terminlasts.", "Sammel SEPA", .ibanOwn, .amount, .quantity)
        case .collectiveDebitForeignScheduled:
            return VisualisationClassAttributes(33, "Terminlasts.", "Sammel Ausl.", .accountNumberOwn, .amount, .quantity)
        case .standingOrderNational:
            return VisualisationClassAttributes(34, "Dauerüberw.", "Inland", .accountRecipient, .bankCodeRecipient, .amount)
        case .standingOrderSepa:
            return VisualisationClassAttributes(35, "Dauerüberw.", "SEPA", .ibanRecipient, .amount)
        case .standingOrderForeign:
            return VisualisationClassAttributes(36, "Dauerüberw.", "Ausland", .accountNumberRecipient, .amount)
        case .standingOrderDebitNational:
            return VisualisationClassAttributes(37, "Dauerlasts.", "Inland", .accountNumberPayer, .bankCodePayer, .amount)
        case .standingOrderDebitSepa:
            return VisualisationClassAttributes(38, "Dauerlasts.", "SEPA", .ibanPayer, .amount)
        case .portfolioRetrieval:
            return VisualisationClassAttributes(39, "Bestand", "abfragen")
        case .deleteOrder40:
            return VisualisationClassAttributes(40, "Löschen", "Auftrag", .accountNumberOwn, .amount, .orderId)
        case .stopOrderCreditTransfer41:
            return VisualisationClassAttributes(41, "Aussetzen", "Auftrag", .accountNumberRecipient, .amount)
        case .stopOrderDirectDebit42:
            return VisualisationClassAttributes(42, "Aussetzen", "Auftrag", .accountNumberPayer, .amount)
        case .updateOrderCreditTransfer43:
            return VisualisationClassAttributes(43, "Ändern", "Auftrag", .accountNumberRecipient, .amount)
        case .updateOrderDebitTransfer44:
            return VisualisationClassAttributes(44, "Ändern", "Auftrag", .accountPayer, .amount)
        case .releaseCreditTransfersNational:
            return VisualisationClassAttributes(45, "Freigabe", "Überw. DTAUS", .accountNumberOwn, .amount, .quantity)
        case .releaseDirectDebitsNational:
            return VisualisationClassAttributes(46, "Freigabe", "Lasts. DTAUS", .accountNumberOwn, .amount, .quantity)
        case .releaseCreditTransferForeign:
            return VisualisationClassAttributes(47, "Freigabe", "Überw. DTAZV", .accountNumberOwn, .amount, .quantity)
        case .releaseCreditTransfersSepa:
            return VisualisationClassAttributes(48, "Freigabe", "Überw. SEPA", .ibanOwn, .amount, .quantity)
        case .releaseDirectDebitsSepa:
            return VisualisationClassAttributes(49, "Freigabe", "Lasts. SEPA", .ibanOwn, .amount, .quantity)
        case .releaseFiles:
            return VisualisationClassAttributes(50, "Freigabe", "DSRZ-Dateien", .accountNumberOwn, .amount, .quantity)
        case .electronicStatement:
            return VisualisationClassAttributes(51, "Kontoauszug", "u. Quittung", .accountNumberOwn)
        case .electronicStatementSubscribe:
            return VisualisationClassAttributes(52, "Kontoauszug", "an/abmelden", .accountNumberOwn)
        case .electronicMailboxSubscribe:
            return VisualisationClassAttributes(53, "Postfach", "an/abmelden", .accountNumberOwn)
        case .electronicMailbox:
            return VisualisationClassAttributes(54, "Postkorb", "", .accountNumberOwn)
        case .dataVault:
            return VisualisationClassAttributes(55, "Datentresor", "", .accountNumberOwn)
        case .securitiesBuy:
            return VisualisationClassAttributes(56, "Wertpapier", "Kauf", .isin, .wkn, .pieces)
        case .securitiesSell:
            return VisualisationClassAttributes(57, "Wertpapier", "Verkauf", .isin, .wkn, .pieces)
        case .securitiesTrade:
            return VisualisationClassAttributes(58, "Wertpapier", "Geschäft", .isin, .wkn, .pieces)
        case .contractAsset:
            return VisualisationClassAttributes(59, "Anlage", "Abschluss", .quote, .amount, .rate)
        case .contractLoan:
            return VisualisationClassAttributes(60, "Kredit", "Abschluss", .quote, .amount, .rate)
        case .contractProduct:
            return VisualisationClassAttributes(61, "Produkt", "Kauf", .amount, .rate)
        case .contractInsurance:
            return VisualisationClassAttributes(62, "Versicherung", "Abschluss", .quote, .amount, .rate)
        case .masterDataManagement:
            return VisualisationClassAttributes(63, "Service", "Funktionen", .postCode)
        case .tanManagement:
            return VisualisationClassAttributes(64, "TAN-Medien", "Management", .tanMedia, .mobilePhone, .cardNumber)
        case .chargeMobilePhone:
            return VisualisationClassAttributes(65, "Mobiltelefon", "laden", .mobilePhone, .amount)
        case .chargeChipCard:
            return VisualisationClassAttributes(66, "GeldKarte", "laden", .cardNumber, .amount, .bankCodeCard)
        case .internetPayment67:
            return VisualisationClassAttributes(67, "Zahlung", "Internet", .merchant, .accountNumberRecipient, .amount)
        case .internetMoneyTransfer:
            return VisualisationClassAttributes(68, "Geldtransfer", "Internet", .merchant, .accountNumberRecipient, .amount)
        case .exemptionOrder:
            return VisualisationClassAttributes(69, "Freistellung", "", .amount)
        case .addressChange70:
            return VisualisationClassAttributes(70, "Adresse", "ändern", .address, .mobilePhone)
        case .addressChange71:
            return VisualisationClassAttributes(71, "Adresse", "ändern", .postCode)
        case .creditTransferForeign72:
            return VisualisationClassAttributes(72, "Überweisung", "Ausland", .ibanRecipient, .amount)
        case .creditTransferForeign73:
            return VisualisationClassAttributes(73, "Überweisung", "Ausland", .accountRecipient, .amount)
        case .directDebitReturn74:
            return VisualisationClassAttributes(74, "Rückgabe", "Lastschrift", .ibanOwn, .amount)
        case .deleteOrder75:
            return VisualisationClassAttributes(75, "Löschen", "Auftrag", .ibanOwn, .amount, .orderType)
        case .deleteOrder76:
            return VisualisationClassAttributes(76, "Löschen", "Auftrag", .ibanOwn, .amount, .orderType)
        case .stopOrderCreditTransfer77:
            return VisualisationClassAttributes(77, "Aussetzen", "Auftrag", .ibanOwn, .amount, .orderType)
        case .stopOrderDirectDebit78:
            return VisualisationClassAttributes(78, "Aussetzen", "Auftrag", .ibanPayer, .amount, .orderType)
        case .updateOrderCreditTransfer79:
            return VisualisationClassAttributes(79, "Ändern", "Auftrag", .ibanOwn, .amount, .orderType)
        case .updateOrderDebitTransfer80:
            return VisualisationClassAttributes(80, "Ändern", "Auftrag", .ibanPayer, .amount, .orderType)
        case .internetPayment81:
            return VisualisationClassAttributes(81, "Zahlung", "Internet", .merchant, .amount, .currency)
        }
    }
    
    static var byId : [Int : VisualisationClass] {
        var _byId = [Int : VisualisationClass]()
        VisualisationClass.allCases.forEach {
            _byId[$0.attr.id] = $0
        }
        return _byId
    }
    
    static func forId(id : Int) -> VisualisationClass?{
        return byId[id]
    }
}

class VisualisationClassAttributes {
    let id : Int!
    let visDataLine1 : String!
    let visDataLine2 : String!
    let dataElements : [DataElementType]!
    
    init(_ id : Int, _ visDataLine1: String, _ visDataLine2: String, _ dataElements : DataElementType...){
        self.id = id
        self.visDataLine1 = visDataLine1
        self.visDataLine2 = visDataLine2
        self.dataElements = dataElements
    }
}
