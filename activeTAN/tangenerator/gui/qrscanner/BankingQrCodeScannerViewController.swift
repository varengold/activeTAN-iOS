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
import ZXingObjC

class BankingQrCodeScannerViewController : UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var scanView: UIView?
    @IBOutlet weak var scanImage: UIImageView!
    
    private var capture: ZXCapture?
    var isScanning: Bool?
    private var captureSizeTransform: CGAffineTransform?
    var listener : BankingQrCodeListener?
    private var observerNotificationsAdded = false
    
    // MARK: Life Circles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupQRCapture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupScanView()
        applyRectOfInterest()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scanImage?.addPulseAnimation()
        addBackgroundForegroundNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeBackgroundForegroundNotifications()
    }
    
    @objc func startScan(){
        print("Start scan")
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.isScanning = true
            weakSelf.capture?.start()
        }
    }
    
    @objc func stopScan(){
        print("Stop scan")
        capture?.stop()
        isScanning = false
    }
    
    func addBackgroundForegroundNotifications(){
        if !observerNotificationsAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(stopScan), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(startScan), name: UIApplication.didBecomeActiveNotification, object: nil)
            observerNotificationsAdded = true
        }
    }
    
    func removeBackgroundForegroundNotifications(){
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        observerNotificationsAdded = false
    }
}

// MARK: Helpers

extension BankingQrCodeScannerViewController {
    
    private func setupQRCapture() {
        isScanning = false
        
        capture = ZXCapture()
        guard let _capture = capture else { return }
        _capture.camera = _capture.back()
        _capture.focusMode =  .continuousAutoFocus
        _capture.delegate = self
    }
    
    private func setupScanView() {
        guard let _capture = capture else { return }
        
        guard let _scanView = scanView else { return }
        _scanView.layer.addSublayer(_capture.layer)
        _scanView.clipsToBounds = true
        self.view.bringSubviewToFront(_scanView)
        
        // position capture layer centered inside scan view
        let xPos, yPos : CGFloat
        if _scanView.frame.width < view.frame.width {
            xPos = (view.frame.width-_scanView.frame.width/2) * -1
        } else{
            xPos = view.frame.origin.x
        }
        if _scanView.frame.height < view.frame.height {
            yPos = ((view.frame.height-_scanView.frame.height)/2) * -1
        } else{
            yPos = view.frame.origin.y
        }
        _capture.layer.frame = CGRect(x: xPos, y: yPos, width: view.frame.width, height: view.frame.height)
        
        
        if let _scanImage = self.scanImage {
            _scanView.bringSubviewToFront(_scanImage)
        }
        
    }
    
    func applyRectOfInterest(){
        let rectOfInterest : CGRect
        if let _scanImage = scanImage {
            rectOfInterest = _scanImage.frame
        } else if let _scanView = scanView{
            rectOfInterest = _scanView.frame
        } else {
            return
        }
        
        let captureSize = getCaptureResolution()
        
        let ratio = captureSize.height / self.view.frame.height
        
        let d1 = (captureSize.height - scanView!.frame.height * ratio ) / 2
        let x = (scanView!.frame.height - rectOfInterest.height - rectOfInterest.origin.y) * ratio + d1
        
        let d2 = (captureSize.width - scanView!.frame.width * ratio) / 2
        let y = (scanView!.frame.width - rectOfInterest.width - rectOfInterest.origin.x) * ratio + d2
        
        let width = rectOfInterest.height * ratio
        
        let height = rectOfInterest.width * ratio
        
        capture?.scanRect = CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func getCaptureResolution() -> CGSize {
        var resolution = CGSize(width: 0, height: 0)
        
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
        
        let orientation = UIApplication.shared.statusBarOrientation
        let portraitOrientation = orientation == .portrait || orientation == .portraitUpsideDown
        
        if let formatDescription = device?.activeFormat.formatDescription {
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            resolution = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
            if portraitOrientation {
                resolution = CGSize(width: resolution.height, height: resolution.width)
            }
        }
        
        return resolution
    }
}

// MARK: ZXCaptureDelegate

extension BankingQrCodeScannerViewController : ZXCaptureDelegate {
    
    func captureCameraIsReady(_ capture: ZXCapture!) {
        isScanning = true
    }
    
    func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        guard let listener = listener else{
            return
        }
        guard let result = result, isScanning == true else { return }
        if result.barcodeFormat != kBarcodeFormatQRCode {
            return
        }
        
        stopScan()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let qrCodeHandler = QrCodeHandler(listener)
        
        do{
            try qrCodeHandler.handleResult(result: result)
        } catch NoBankingQrCodeError.error(let message){
            listener.onInvalidBankingQrCode(detailReason: message)
        } catch {
            listener.onInvalidBankingQrCode(detailReason: "unknown error")
        }
    }
    
}
