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

import UIKit

class InitializeTokenStep0ViewController : BankingQrCodeScannerViewController{

    var initializeTokenContainer : InitializeTokenContainerController!
    
    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var hintLabel : UILabel!
    
    // MARK: Life Circles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localizeBackButton()
        
        if let navigationController = self.navigationController as? InitializeTokenContainerController {
            initializeTokenContainer = navigationController
        } else{
            fatalError()
        }
        
        self.titleLabel.text = NSLocalizedString("initialization", comment: "")
        self.hintLabel.text = NSLocalizedString("scan_letter_qr_code", comment: "")
        
        listener = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if initializeTokenContainer.checkRequirements() {
            self.startScan()
        }
    }
}

extension InitializeTokenStep0ViewController : BankingQrCodeListener {
    func onTransactionData(hhduc: [UInt8]) {
        print("Transaction data found: Display Error")
        onInvalidBankingQrCode(detailReason: "no transaction data allowed during initialization")
    }
    
    func onKeyMaterial(hhdkm: [UInt8]) {
        if initializeTokenContainer.checkRequirements() {
            if hhdkm.count >= 1 {
                let type = KeyMaterialType(rawValue: hhdkm[0])!
                if type == KeyMaterialType.LETTER || type == KeyMaterialType.DEMO {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let controller = storyboard.instantiateViewController(withIdentifier: "InitializeTokenStep1") as! InitializeTokenStep1ViewController
                    controller.rawLetterKeyMaterial = hhdkm
                    if type == KeyMaterialType.DEMO {
                        controller.demoMode = true
                    }
                    initializeTokenContainer.pushViewController(controller, animated: true)
                    return
                }
            }
            onInvalidBankingQrCode(detailReason: "not a letter key")
        }
    }
    
    func onInvalidBankingQrCode(detailReason: String) {
        print("the user did not scan the letter QR code: \(detailReason)")
        
        // Instead of cancelling the ongoing process or restarting the whole process,
        // the user may repeat the portal QR code scanning.
        let alert = UIAlertController(
            title: NSLocalizedString("initialization_failed_wrong_qr_code", comment: ""),
            message: NSLocalizedString("scan_letter_qr_code", comment: ""),
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("repeat", comment: ""),
            style: .default,
            handler: { action in
                self.startScan()
        }))
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("alert_cancel", comment: ""),
            style: .destructive,
            handler: {action in
                self.initializeTokenContainer.leaveInitializationViews()
                self.removeBackgroundForegroundNotifications()
        }))
        
        self.present(alert, animated: true)
    }
    
}
