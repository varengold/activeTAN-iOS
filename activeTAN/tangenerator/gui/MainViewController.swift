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
import SPStorkController
import AVFoundation

/*
 View controller to scan a QR code with the smartphone's camera.
 This view controller is the main entry point for this app, if a banking token is already stored.
 
 There are two use cases for this view controller:
    - Scan transaction details to compute a TAN. This is the main use case after initialization.
    - Scan the activation letter to start initialization of an additional TAN generator.

 This view controller accepts either transaction details or an activation letter.
 Depending on the QR code this will start either the TAN generation or initialization respectively.
*/
class MainViewController : BankingQrCodeScannerViewController, BankingQrCodeListener {
    
    @IBOutlet weak var cameraAccessInformation : UILabel!
    @IBOutlet weak var rightBarButton : UIBarButtonItem!
    
    // MARK: Life Circles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listener = self
        
        localizeBackButton()
        
        self.cameraAccessInformation.isHidden = true
        self.cameraAccessInformation.text = Utils.localizedString("main_no_camera_permission")
        
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationBar.prefersLargeTitles = false
        
        self.rightBarButton.title = Utils.localizedString("menu_title")
        
        // Logo
        let logo = UIImage(named: "logo_nav_title")
        let imageView = UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        
        // Wrap image view in properly sized view to make sure, it's not so large for the navigation bar
        let logoHeight = self.navigationController!.navigationBar.frame.height-10
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: logoHeight, height: logoHeight))
        imageView.frame = titleView.bounds
        titleView.addSubview(imageView)
        
        self.navigationItem.titleView = titleView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if BankingTokenRepository.getAllUsable().count == 0 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "Welcome")
            self.present(controller, animated: false, completion: nil)
        } else{
            NotificationCenter.default.addObserver(self, selector: #selector(resumeScan), name: .resumeScan, object: nil)
            startScan()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if AVCaptureDevice.authorizationStatus(for: .video) !=  .authorized {
            cameraAccessInformation.isHidden = false
        } else{
            self.startScan()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.removeObserver(self, name: .resumeScan, object: nil)
        isScanning = false
    }

    @objc func resumeScan(){
        addBackgroundForegroundNotifications()
        startScan()
    }
}

// MARK: BankingQrCodeListener{

extension MainViewController {
    func onTransactionData(hhduc: [UInt8]) {
            removeBackgroundForegroundNotifications()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let controller = storyboard.instantiateViewController(withIdentifier: "VerifyTransactionDetails") as! VerifyTransactionDetailsController
            
            controller.rawHHDuc = hhduc
            
            let transitionDelegate = SPStorkTransitioningDelegate()
            transitionDelegate.hideIndicatorWhenScroll = true
            transitionDelegate.tapAroundToDismissEnabled = false
            transitionDelegate.hapticMoments = [.willPresent, .willDismissIfRelease]
            controller.transitioningDelegate = transitionDelegate
            controller.modalPresentationStyle = .custom
            controller.modalPresentationCapturesStatusBarAppearance = true
            
            self.present(controller, animated: true, completion: nil)
        
    }
    
    func onKeyMaterial(hhdkm: [UInt8]) {
        if hhdkm.count >= 1 && KeyMaterialType(rawValue: hhdkm[0])! == KeyMaterialType.LETTER {
            let alert = UIAlertController(title: NSLocalizedString("additional_letter_qr_code", comment: ""), message: NSLocalizedString("add_additional_token", comment: ""), preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("button_cancel_add_additional_token", comment: ""),
                style: .cancel,
                handler: { action in
                    
                    self.startScan()
            }))
            
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("button_continue_add_additional_token", comment: ""),
                style: .default,
                handler: { action in
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    
                    let controller = storyboard.instantiateViewController(withIdentifier: "InitializeTokenStep1") as! InitializeTokenStep1ViewController
                    controller.rawLetterKeyMaterial = hhdkm
                    
                    let navController = InitializeTokenContainerController(rootViewController: controller)
                    
                    self.present(navController, animated: true, completion: nil)
                    
            }))
            self.present(alert, animated: true)
        } else{
            onInvalidBankingQrCode(detailReason: "Portal key scanned outside initialization process")
        }
            
    }

    func onInvalidBankingQrCode(detailReason: String) {
        print("Invalid banking qr code: \(detailReason)")
        
        let alert = UIAlertController(
            title: NSLocalizedString("invalid_banking_qr", comment: ""),
            message: nil,
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("repeat", comment: ""),
            style: .default,
            handler: { action in
                self.startScan()
        }))
        
        self.present(alert, animated: true)
    }

}

extension Notification.Name {
    static let resumeScan = Notification.Name("resumeScan")
}
