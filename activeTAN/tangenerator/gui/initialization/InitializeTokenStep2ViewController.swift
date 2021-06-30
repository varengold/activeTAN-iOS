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

class InitializeTokenStep2ViewController : BankingQrCodeScannerViewController, BankingQrCodeListener{
    
    // MARK: Properties
    
    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var hintLabel : UILabel!
    
    var initializeTokenContainer : InitializeTokenContainerController!
    
    // MARK: Life Circles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localizeBackButton()
        
        if let navigationController = self.navigationController as? InitializeTokenContainerController {
            initializeTokenContainer = navigationController
        } else{
            fatalError()
        }
        
        listener = self
        
        titleLabel.text = Utils.localizedString("initialization")
        hintLabel.text = Utils.localizedString(Utils.configBool(key: "email_initialization_enabled") ? "scan_screen_qr_code_not_email" : "scan_screen_qr_code_not_letter")
        hintLabel.adjustsFontSizeToFitWidth = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if initializeTokenContainer.checkRequirements() {
            self.startScan()
        }
    }
    
    private func saveBankingToken(keyComponents : BankingKeyComponents, completion: (_ initialTAN:Int) -> Void){
        let algorithm : SecKeyAlgorithm = SecurityHandler.enclaveAlgorithm
        
        do{
            let secretKey = try keyComponents.combine()
            
            // retrieve/generate enclave key for encryption of secret key
            if !SecurityHandler.isUsableKeypairAvailable() {
                // generate key pair
                let publicKey = try SecurityHandler.generateKeyPair()
                try SecurityHandler.savePublicKey(publicKey: publicKey)
            }
            // retrieve public key for encryption
            let publicKey = try SecurityHandler.getPublicKey()

            // encrypt
            let encryptedSecretKey = try SecurityHandler.encrypt(plain: Data(bytes: secretKey, count: secretKey.count), publicKey: publicKey, algorithm: algorithm)
            
            // save to keychain
            let uuid = UUID().uuidString // internal uuid for token
            try SecurityHandler.saveToKeychain(key: uuid, data: encryptedSecretKey)
            
            try BankingTokenRepository.insertNewToken(id: initializeTokenContainer.tokenId!, name: Utils.localizedString("default_token_name"), keyAlias: uuid)
            
            let token = try BankingTokenRepository.readToken(keyAlias: uuid)

            completion(try TanGenerator.generateTanForInitialization(token: token))
        }catch{
            print(error)
            // Delete key pair to prevent future problems using enclave functions
            try? SecurityHandler.deletePrivateKey()
            try? SecurityHandler.deletePublicKey()
        }
    }
    
}

// MARK: Process steps

extension InitializeTokenStep2ViewController {
    private func doStepCreateBankingToken(hhdkmPortal : [UInt8]){
        // Verify the portal key
        let portalKeyMaterial : HHDkm
        
        do {
            portalKeyMaterial = try HHDkm(rawBytes: hhdkmPortal)
        } catch {
            onInvalidBankingQrCode(detailReason: "not a valid portal key")
            return
        }
        
        if portalKeyMaterial.letterNumber != initializeTokenContainer.letterNumber {
            // A wrong letter has been scanned in the first step
            initializeTokenContainer.onInitializationFailed(reasonKey: Utils.configBool(key: "email_initialization_enabled") ? "initialization_failed_wrong_email":"initialization_failed_wrong_letter", processShouldBeRepeated: false, onRepetition: {self.startScan()})
            return
        }
        
        if portalKeyMaterial.deviceSerialNumber != initializeTokenContainer.tokenId {
            // The user has entered a wrong serial number in the banking frontend after step 1.
            initializeTokenContainer.onInitializationFailed(reasonKey: "initialization_failed_wrong_serial", processShouldBeRepeated: true, onRepetition: {self.startScan()})
            return
        }
        
        // Apply the portal key
        initializeTokenContainer.keyComponents!.portalKeyComponent = portalKeyMaterial.aesKeyComponent
        
        saveBankingToken(keyComponents: initializeTokenContainer.keyComponents!) {
            (initialTAN) -> Void in
            doGoShowInitialTAN(tan: initialTAN)
        }
        
    }
    
    func doGoShowInitialTAN(tan : Int){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "InitializeTokenStep3") as! InitializeTokenStep3ViewController
        controller.initialTAN = tan
        initializeTokenContainer.pushViewController(controller, animated: true)
    }
}

// MARK: BankingQrCodeListener

extension InitializeTokenStep2ViewController{
    
    func onTransactionData(hhduc: [UInt8]) {
        onInvalidBankingQrCode(detailReason: "no transaction data allowed during initialization");
    }
    
    func onKeyMaterial(hhdkm: [UInt8]) {
        if initializeTokenContainer.checkRequirements() {
            if (hhdkm.count >= 1 && KeyMaterialType(rawValue: hhdkm[0]) == KeyMaterialType.PORTAL) {
                doStepCreateBankingToken(hhdkmPortal: hhdkm)
                return
            }
            
            onInvalidBankingQrCode(detailReason: "not a portal key")
        }
    }
    
    func onInvalidBankingQrCode(detailReason: String) {
        print("the user did not scan the portal QR code: \(detailReason)")
        
        // Instead of cancelling the ongoing process or restarting the whole process,
        // the user may repeat the portal QR code scanning.
        let alert = UIAlertController(
            title: Utils.localizedString("initialization_failed_wrong_qr_code"),
            message: Utils.localizedString("scan_screen_qr_code"),
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: Utils.localizedString("repeat"),
            style: .default,
            handler: { action in
                self.startScan()
        }))
        
        alert.addAction(UIAlertAction(
            title: Utils.localizedString("alert_cancel"),
            style: .destructive,
            handler: {action in
                self.initializeTokenContainer.leaveInitializationViews()
                self.removeBackgroundForegroundNotifications()
        }))
        
        self.present(alert, animated: true)
    }
    
}
