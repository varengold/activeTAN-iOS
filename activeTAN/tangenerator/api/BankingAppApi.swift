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
import UIKit
import ZXingObjC

class BankingAppApi : UIViewController{
    
    var fileDir : URL?
    var fileContent : String?
    
    // Input params
    var fileName : String?
    var eligibleTokens : [String : BankingToken]?
    
    // Return params
    var tanGeneratorId : String?
    var tan : String?
    var atc : Int32?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appGroupId = Bundle.main.object(forInfoDictionaryKey: "APP_GROUP") as? String
        
        if let _dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId!){
            fileDir = _dir
        } else{
            print("Group identifier invalid")
            finish(status: .canceled)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if fileContent == nil {
            fileContent = readChallengeFile()
            processApiChallenge()
        }
    }
    
    private func processApiChallenge(){
        if fileContent == "" {
            finish(status: .canceled)
            return
        }
        do{
            let jsonData = fileContent!.data(using: .utf8)!
            let challenge = try JSONDecoder().decode(BankingAppChallenge.self, from: jsonData)
            if challenge.status != .pending {
                print("Challenge is no longer pending")
                finish(status: .canceled)
                return
            }
            
            eligibleTokens = findMatchingBankingTokens(tanMediaDescriptions: challenge.tanMediaDescriptions)
            if eligibleTokens!.count == 0 {
                print("This app is not initialized or initialization does not match expected TAN generators")
                finish(status: .canceled)
                return
            }
            
            let decodedQrCode : ZXResult
            do{
                 decodedQrCode = try decodeQrCode(base64Image: challenge.qrCode)
            } catch {
                print("Invalid QR code in api, invalid call?")
                finish(status: .canceled)
                return
            }
            
            do{
                try QrCodeHandler.init(self).handleResult(result: decodedQrCode)
            } catch {
                print("Invalid QR code data")
                finish(status: .canceled)
                return
            }
            
        }catch{
            print("Illegal JSON content")
            finish(status: .canceled)
            return
        }
    }
    
    @objc func onRestart(){
        print("App did become active after it was pushed to background after API call. Try to reload challenge.")
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        fileContent = readChallengeFile()
        if fileContent == "" {
            print("No challenge data. Redirect to init view.")
            redirectToInitView()
        } else {
            print("Challenge data found. Start processing.")
            processApiChallenge()
        }
    }
    
    private func readChallengeFile() -> String {
        let fileUrl = fileDir!.appendingPathComponent(fileName!)
            
        do{
            let json = try String(contentsOf: fileUrl, encoding: .utf8)
            return json
        } catch{
            print("Challenge data not readable")
        }
        return ""
    }
    
    private func decodeQrCode(base64Image : String) throws -> ZXResult{
        let dataDecoded : Data = Data(base64Encoded: base64Image, options: .ignoreUnknownCharacters)!
        let decodedQrCode = UIImage(data: dataDecoded)
        
        let source: ZXLuminanceSource = ZXCGImageLuminanceSource(cgImage: decodedQrCode?.cgImage)
        let binazer = ZXHybridBinarizer(source: source)
        let bitmap = ZXBinaryBitmap(binarizer: binazer)

        let hints = ZXDecodeHints()
        let reader = ZXMultiFormatReader()
        return try reader.decode(bitmap, hints:hints)
    }
    
    private func findMatchingBankingTokens(tanMediaDescriptions : [String]) -> [String : BankingToken]{
        var usableTokensById = [String : BankingToken]()
        for token in BankingTokenRepository.getAllUsable() {
            usableTokensById[token.id!] = token
        }
        
        var usableTokensByMediaDescription = [String : BankingToken]()
        for description in tanMediaDescriptions {
            // Parse Token ID
            // Example description: activeTAN-App XX12-3456-7890
            let descriptionParts = description.split{$0 == " "}.map(String.init)
            if (descriptionParts.count >= 2) {
                let formattedTokenId = descriptionParts[descriptionParts.count - 1]
                let tokenId = BankingToken.parseFormattedSerialNumber(formattedSerialNumber: formattedTokenId)
                if usableTokensById[tokenId] != nil {
                    usableTokensByMediaDescription[description] = usableTokensById[tokenId]
                }
            }
        }
            
        return usableTokensByMediaDescription
    }
    
    private func finish(status : BankingApiResponseStatus){
        let bankingAppUrlScheme = Utils.config(key: "BANKING_APP_URL_SCHEME")
        let strUrl = bankingAppUrlScheme + "://" + fileName!
        if let url = URL(string: strUrl) {
            UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                self.redirectToInitView()
            })
        } else{
            redirectToInitView()
        }
    }
    // Redirect app to initial view controller to prevent showing an empty view controller if e.g. the user navigates to this app manually
    private func redirectToInitView(){
        let window: UIWindow? = (UIApplication.shared.delegate?.window)!
        window?.rootViewController = (UIApplication.shared.delegate as! AppDelegate).initialViewController()
    }
    
    private func startChallenge(hhduc : [UInt8]){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let controller = storyboard.instantiateViewController(withIdentifier: "VerifyTransactionDetailsNavigationController") as! UINavigationController
        
        (controller.viewControllers[0] as! VerifyTransactionDetailsController).rawHHDuc = hhduc
        (controller.viewControllers[0] as! VerifyTransactionDetailsController).usableTokens = Array(eligibleTokens!.values)
        
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: false, completion: nil)
    }
    
    func onChallengeResult(){
        writeApiResponse(status: .released)
    }
    
    func onDeclined(){
        writeApiResponse(status: .declined)
    }
    
    func writeApiResponse(status : BankingAppChallengeStatus){
        fileContent = readChallengeFile()
        
        do{
            let jsonData = fileContent!.data(using: .utf8)!
            var challenge = try JSONDecoder().decode(BankingAppChallenge.self, from: jsonData)
            
            if challenge.status != .pending {
                print("Challenge no longer pending")
                finish(status: .canceled)
                return
            }
            
            if let _tanGeneratorId = tanGeneratorId {
                // Return to the caller only the used TAN generator's TAN media description
                for token in findMatchingBankingTokens(tanMediaDescriptions: challenge.tanMediaDescriptions) {
                    if _tanGeneratorId == token.value.id {
                        challenge.tanMediaDescriptions = [token.key]
                    }
                }
            }
            
            challenge.status = status
            challenge.tan = self.tan
            challenge.atc = self.atc
            
            let fileUrl = fileDir!.appendingPathComponent(fileName!)
            
            let json = try JSONEncoder().encode(challenge)
            
            do{
                let jsonString = String(data: json, encoding: .utf8)!
                try jsonString.write(to: fileUrl, atomically: false, encoding: String.Encoding.utf8)
                finish(status: .ok)
                return
            } catch{
                print("Response data could not be written to file.")
                finish(status: .canceled)
                return
            }
            
        }catch{
            print("Challenge content no longer readable: Illegal JSON content")
            finish(status: .canceled)
            return
        }
    }
}

enum BankingApiResponseStatus : String{
    case canceled
    case ok
}

extension BankingAppApi : BankingQrCodeListener {
    func onTransactionData(hhduc: [UInt8]) {
        startChallenge(hhduc: hhduc)
    }
    
    func onKeyMaterial(hhdkm: [UInt8]) {
        onInvalidBankingQrCode(detailReason: "Key material not supported via api")
    }
    
    func onInvalidBankingQrCode(detailReason: String) {
        print("Invalid QR code data: " + detailReason)
        finish(status: .canceled)
    }
}
