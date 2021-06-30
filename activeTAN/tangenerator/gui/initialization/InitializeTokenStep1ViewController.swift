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

class InitializeTokenStep1ViewController : ScrollStickyFooterViewController{
    
    // MARK: Properties
    
    @IBOutlet weak var containerView : UIView!
    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var serialNumberContainer : UIView!
    @IBOutlet weak var labelSerialNumber : UILabel!
    @IBOutlet weak var serialNumber : UILabel!
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var descriptionLabel : UILabel!
    @IBOutlet weak var hintLabel : UILabel!
    @IBOutlet weak var actionButton : DefaultButton!
    
    var rawLetterKeyMaterial : [UInt8]?
    // Algorithm used to encrypt the uploaded data of a POST request.
    let apiUploadEncryptionAlgorithm : SecKeyAlgorithm = .rsaEncryptionOAEPSHA1
    //  Algorithm used to sign the encrypted request and response data payload.
    let apiDownloadSignatureAlgorithm : SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA512
    // Response HTTP header field which contains the signature in BASE64 encoding.
    let apiSignatureHeader = "X-Signature"
    
    let apiUserAgent : String = Bundle.main.bundleIdentifier! + "/" + String(Int(Bundle.main.infoDictionary?["CFBundleVersion"] as! String)!) + " iOS/" + UIDevice.current.systemVersion
    var apiKey : SecKey?
    var session : URLSession?
    
    var initializeTokenContainer : InitializeTokenContainerController!
    
    var demoMode : Bool = false
    let demoTokenId = "XX0123456789"
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localizeBackButton()
        
        if let navigationController = self.navigationController as? InitializeTokenContainerController {
            initializeTokenContainer = navigationController
        } else{
            fatalError()
        }
        
        self.containerView.isHidden = true
        
        self.titleLabel.text = Utils.localizedString("initialization")
        
        self.descriptionLabel.text = Utils.configBool(key: "email_initialization_enabled") ? Utils.localizedString("initialization_email_scanned") : Utils.localizedString("initialization_letter_scanned")
        self.descriptionLabel.adjustsFontSizeToFitWidth = true
        
        self.serialNumberContainer.layer.cornerRadius = 8
        self.serialNumberContainer.clipsToBounds = true
        self.labelSerialNumber.text = Utils.localizedString("label_serial_number")
        self.labelSerialNumber.adjustsFontSizeToFitWidth = true
        self.serialNumber.adjustsFontSizeToFitWidth = true
        
        self.hintLabel.text = Utils.localizedString("enter_serial_number") + "\n\n" + Utils.localizedString("go_to_scan_qr_code")
        self.hintLabel.adjustsFontSizeToFitWidth = true

        self.stickyFooter.hide()
        self.actionButton.setTitle(Utils.localizedString("next_step"), for: .normal)
        
        doStartProcess()
    }
    
    @IBAction func onStep1Continue(sender: UIButton){
        doStepScanPortalKey()
    }

}

// MARK: Process steps

extension InitializeTokenStep1ViewController {
    
    private func doStartProcess(){
        guard let rawBytes = rawLetterKeyMaterial else{
            return
        }
        
        let letterKeyMaterial : HHDkm
        do {
            letterKeyMaterial = try HHDkm(rawBytes: rawBytes)
            
        } catch{
            return
        }
        
        initializeTokenContainer.keyComponents = BankingKeyComponents()
        initializeTokenContainer.keyComponents!.letterKeyComponent = letterKeyMaterial.aesKeyComponent
        initializeTokenContainer.letterNumber = letterKeyMaterial.letterNumber
        
        doStepUploadEncryptedDeviceKey()
    }
    
    private func doStepUploadEncryptedDeviceKey(){
        loadApiKey()
        prepareConnection()
        
        do {
            try uploadData(){
                (result: Data) in
                var tokenId = String(data: result, encoding: .utf8)!
                if self.demoMode {
                    tokenId = self.demoTokenId
                }
                self.initializeTokenContainer.tokenId = tokenId
                DispatchQueue.main.async {
                    self.doShowTokenId()
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
                        self.stickyFooter.fadeIn()
                    })
                }
            }
        }catch{
            
        }
    }
    
    private func doShowTokenId(){
        self.activityIndicator.isHidden = true
        self.serialNumber.text = Utils.formatSerialNumber(serialNumber: self.initializeTokenContainer.tokenId!)
        self.containerView.isHidden = false
    }
    
    private func doStepScanPortalKey(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "InitializeTokenStep2") as! InitializeTokenStep2ViewController
        initializeTokenContainer.pushViewController(controller, animated: true)
    }
}

// MARK: API call functions

extension InitializeTokenStep1ViewController {
    
    private func loadApiKey(){
        do {
            let filepath = Bundle.main.path(forResource: "api_key", ofType: "pem")!
            var rawKey = try String(contentsOfFile: filepath)
            if let range = rawKey.range(of: "-----BEGIN PUBLIC KEY-----") {
                rawKey.removeSubrange(range)
            }
            if let range = rawKey.range(of: "-----END PUBLIC KEY-----") {
                rawKey.removeSubrange(range)
            }
            
            let decodedKey = Data(base64Encoded: rawKey, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
            
            apiKey = try SecurityHandler.restoreKey(keyData: decodedKey)
        } catch {
            print("API Key could not be loaded")
            fatalError()
        }
    }
    
    private func prepareConnection(){
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpAdditionalHeaders = [
            "User-Agent": apiUserAgent,
            "Accept": "text/*",
            "Content-Type": "application/octet-stream"
        ]
        session = URLSession(configuration: sessionConfiguration)
    }
    
    private func uploadData(completion: @escaping (_ result: Data) -> Void) throws {
        guard let publicKey = apiKey else{
            throw CallFailedError.error("api key not loaded")
        }
        guard let _session = session else{
            throw CallFailedError.error("connection has not be initialized");
        }
        
        do {
            let bankingKeyComponents = BankingKeyComponents()
            bankingKeyComponents.generateDeviceKeyComponent()
            initializeTokenContainer.keyComponents!.deviceKeyComponent = bankingKeyComponents.deviceKeyComponent
            let plainDeviceKeyComponent = Data(bytes: bankingKeyComponents.deviceKeyComponent!, count: bankingKeyComponents.deviceKeyComponent!.count)
            
            let encryptedDeciveKey = try SecurityHandler.encrypt(plain: plainDeviceKeyComponent, publicKey: publicKey, algorithm: apiUploadEncryptionAlgorithm)
            
            guard let url = URL(string: Utils.config(key: Bundle.main.object(forInfoDictionaryKey: "API_KEY_URL") as! String)) else {return}
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = encryptedDeciveKey
            _session.dataTask(with: request){(data, response, error) in
                if let response = response {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode != 201 {
                            self.onError(detailReason: "HTTP Code \(httpResponse.statusCode) retrieved")
                            return
                        }
                        let signature = Data(base64Encoded: httpResponse.allHeaderFields[self.apiSignatureHeader]! as! String)
                        do{
                            var myData = encryptedDeciveKey
                            myData.append(data!)
                            let d = try SecurityHandler.verifySignature(data: myData, signature: signature!, publicKey: publicKey, algorithm: self.apiDownloadSignatureAlgorithm)
                            if d {
                                completion(data!)
                            }
                        }catch {
                            self.onError(detailReason: "Verifying server signature failed")
                        }
                    }
                }
            }.resume()
        }catch{
            self.onError(detailReason: "Unexpected error")
        }
    }
    
    func onError(detailReason: String) {
        print("retrieving token failed: \(detailReason)")
        
        // Instead of cancelling the ongoing process or restarting the whole process,
        // the user may repeat the letter QR code scanning.
        let alert = UIAlertController(
            title: Utils.localizedString("initialization_failed_title"),
            message: Utils.localizedString("initialization_failed_unknown_reason"),
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: Utils.localizedString("repeat"),
            style: .default,
            handler: { action in
                self.initializeTokenContainer.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(
            title: Utils.localizedString("alert_cancel"),
            style: .destructive,
            handler: {action in
                self.initializeTokenContainer.leaveInitializationViews()
        }))
        
        self.present(alert, animated: true)
    }
}

public enum CallFailedError : Error {
    case error(String)
}
