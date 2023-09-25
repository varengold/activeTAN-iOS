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
import ZXingObjC

class InitializeTokenFromAppLinkViewController : UIViewController {
    var base64QrCode : String?
    
    var backendId : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let qrCodeData = Data(base64Encoded:base64QrCode!) {
            do{
                try QrCodeHandler.init(self).handleResult(binary: qrCodeData.bytes)
            } catch {
                finish()
                return
            }
        }else{
            finish()
        }
    }
    
    private func startInitialization(hhdkm : [UInt8]){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let controller = storyboard.instantiateViewController(withIdentifier: "InitializeTokenStep1") as! InitializeTokenStep1ViewController
        controller.rawLetterKeyMaterial = hhdkm
        controller.initializeTokenContainer.backendId = backendId!
        controller.showBackendName = (backendId != 0)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Utils.localizedString("gen_cancel"), style: .done, target: self, action: #selector(redirectToInitView))
        
        let navController = InitializeTokenContainerController(rootViewController: controller)
        navController.modalPresentationStyle = .fullScreen
        
        self.present(navController, animated: false, completion: nil)
    }
    
    @objc private func redirectToInitView(){
        let window: UIWindow? = (UIApplication.shared.delegate?.window)!
        window?.rootViewController = (UIApplication.shared.delegate as! AppDelegate).initialViewController()
    }
    
    private func finish(){
        redirectToInitView()
    }
}

extension InitializeTokenFromAppLinkViewController : BankingQrCodeListener {
    
    
    func onTransactionData(hhduc: [UInt8]) {
        onInvalidBankingQrCode(detailReason: "Transaction data not supported via api")
    }
    
    func onKeyMaterial(hhdkm: [UInt8]) {
        startInitialization(hhdkm: hhdkm)
    }
    
    func onInvalidBankingQrCode(detailReason: String) {
        print("Invalid QR code data: " + detailReason)
        finish()
    }
}
