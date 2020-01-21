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
import LocalAuthentication
import AVFoundation

class InitializeTokenContainerController : UINavigationController {
    var keyComponents : BankingKeyComponents?
    var letterNumber : Int?
    var tokenId : String?
    
    func onInitializationFailed(reasonKey : String, processShouldBeRepeated : Bool, onRepetition: @escaping () -> ()){
        var _reasonKey = reasonKey
        if _reasonKey.count == 0 {
            if checkRequirements() {
                // Requirements have been fulfilled.
                // It is unknown why the initialization has failed.
                _reasonKey = Utils.localizedString("initialization_failed_unknown_reason")
            } else {
                // This method has been called by checkRequirements()
                // with an appropriate reason.
                return
            }
        }
        
        let alert = UIAlertController(
            title: Utils.localizedString("initialization_failed_title"),
            message: Utils.localizedString(_reasonKey),
            preferredStyle: .alert)
        
        if processShouldBeRepeated {
            alert.addAction(UIAlertAction(
                title: Utils.localizedString("repeat"),
                style: .default,
                handler: { action in
                    onRepetition()
            }))
        }
        
        alert.addAction(UIAlertAction(
            title: Utils.localizedString("alert_cancel"),
            style: .destructive,
            handler: {action in
                self.leaveInitializationViews()
        }))
        
        self.present(alert, animated: true)
    }
    
    func checkRequirements() -> Bool {
        // Without the device being secured, we cannot store the banking key in the keychain
        if !LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            onInitializationFailed(reasonKey: "initialization_failed_unprotected_device", processShouldBeRepeated: false, onRepetition: {})
            return false
        }
        
        // Without access to the camera, we cannot scan a banking QR code
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            // access to camera not determined; don't show alert
            return false
        }else if AVCaptureDevice.authorizationStatus(for: .video) !=  .authorized {
            // access to camera denied
            onInitializationFailed(reasonKey: "initialization_failed_no_camera_permission", processShouldBeRepeated: false, onRepetition: {})
            return false
        }
        
        return true
    }
    
    func leaveInitializationViews(){
        self.dismiss(animated: true, completion: {
            // In case of already registered tokens, resume scanning in MainViewController
            NotificationCenter.default.post(name: .resumeScan, object: nil)
        })
    }
}
