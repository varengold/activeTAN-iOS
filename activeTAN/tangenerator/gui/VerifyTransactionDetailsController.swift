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
import SPFakeBar
import LocalAuthentication

class VerifyTransactionDetailsController : UIViewController, UITableViewDataSource, UITableViewDelegate {

    var rawHHDuc : [UInt8]?
    var hhduc : HHDuc?
    
    // The selected TAN generator for TAN computation
    private var bankingToken : BankingToken?
    
    @IBOutlet weak var topConstraint : NSLayoutConstraint!
    @IBOutlet weak var instructionTAN : UILabel!
    @IBOutlet weak var visualisationClass : UILabel!
    @IBOutlet weak var labelTAN : UILabel!
    @IBOutlet weak var textTAN : UILabel!
    @IBOutlet weak var textTANContainer : UIView!
    @IBOutlet weak var labelATC : UILabel!
    @IBOutlet weak var textATC : UILabel!
    @IBOutlet weak var textATCContainer : UIView!
    @IBOutlet weak var confirmButton : UIButton!
    @IBOutlet weak var dataElementsTable : IntrinsicSizeTableView!
    
    let navBar = SPFakeBarView(style: .stork)
    
    private final let ibanTypes : [DataElementType] = [.ibanOwn, .ibanSender, .ibanRecipient, .ibanPayer]
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        self.visualisationClass.adjustsFontSizeToFitWidth = true
        
        self.dataElementsTable.layer.borderWidth = 1
        self.dataElementsTable.layer.borderColor = UIColor.init(hex: "DDDDDD")?.cgColor
        self.dataElementsTable.layer.cornerRadius = 8
        
        self.topConstraint.constant = self.navBar.height + self.topConstraint.constant
        
        self.navBar.titleLabel.text = NSLocalizedString("verify_transaction_details_title", comment: "")
        self.navBar.leftButton.setTitle(NSLocalizedString("nav_button_back", comment: ""), for: .normal)
        self.navBar.leftButton.addTarget(self, action: #selector(self.dismissAction), for: .touchUpInside)
        self.navBar.rightButton.setTitle(NSLocalizedString("verify_transaction_nav_button_done", comment: ""), for: .normal)
        self.navBar.rightButton.addTarget(self, action: #selector(self.dismissAction), for: .touchUpInside)
        self.navBar.rightButton.isHidden = true
        
        view.addSubview(self.navBar)
        
        textTANContainer.layer.cornerRadius = 8
        textTANContainer.clipsToBounds = true
        textTANContainer.isHidden = true
        labelTAN.text = NSLocalizedString("labelTAN", comment: "")
        labelTAN.adjustsFontSizeToFitWidth = true
        
        textATCContainer.layer.cornerRadius = 8
        textATCContainer.clipsToBounds = true
        textATCContainer.isHidden = true
        labelATC.text = NSLocalizedString("labelATC", comment: "")
        labelATC.adjustsFontSizeToFitWidth = true
        
        instructionTAN.adjustsFontSizeToFitWidth = true
        
        self.confirmButton.setTitle(NSLocalizedString("confirm_transaction_details", comment: ""), for: .normal)
        
        guard let _rawHHDuc = rawHHDuc else {
            self.navigationController?.popViewController(animated: false)
            return
        }
  
        do {
            hhduc = try HHDuc.parse(rawBytes: _rawHHDuc)
        } catch HHDuc.UnsupportedDataFormatError.error(let message){
            print(message)
            self.view.isHidden = true // Prevent view elements from being presented
            showDismissalAlert()
            return
        } catch {
            print("Unexpected error")
            self.view.isHidden = true // Prevent view elements from being presented
            showDismissalAlert()
            return
        }
        if let visClass = hhduc!.visualisationClass {
            visualisationClass.text = getString(visualisationClass : visClass)
            self.textATCContainer.removeFromSuperview()
            // TODO
        } else{
            visualisationClass.text = NSLocalizedString("synchronize_tan_generator", comment: "")
            // TODO
        }
        
        if (hhduc?.getDataElementTypes().isEmpty)! {
            instructionTAN.text = NSLocalizedString("verify_transaction_without_details", comment: "")
        } else{
            instructionTAN.text = NSLocalizedString("verify_transaction_with_details", comment: "")
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(setToken(_:)), name: .tokenSelected, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self, name: .tokenSelected, object: nil)
        NotificationCenter.default.post(name: .resumeScan, object: nil)
    }
    
    @objc func setToken(_ notification: Notification){
        guard let token = notification.userInfo?["token"] as? BankingToken else { return }
        print("Token \(token.keyAlias!) selected")
        self.bankingToken = token
        onTokenSelected()
    }
    
    
    @objc func dismissAction(){
        self.dismiss(animated: true, completion: nil)
    }
    
    private func showDismissalAlert(){
        let alert = UIAlertController(title: NSLocalizedString("unsupported_data_format_title", comment: ""), message: NSLocalizedString("unsupported_data_format_message", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", comment: ""), style: .default, handler: { action in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
 
    private func getString(visualisationClass : VisualisationClass) -> String {
        let name = String(format: "VC%02d", visualisationClass.attr.id)
        return getString(name)
    }
    
    private func getString(dataElementType : DataElementType) -> String {
        let name = String(format: "DE%02d", dataElementType.attr.id)
        return getString(name)
    }
    
    private func getString(_ name : String) -> String {
        return NSLocalizedString(name, comment: "")
    }
    
    private func computeTan(token : BankingToken) throws -> Int {
        let hhduc = try HHDuc.parse(rawBytes: rawHHDuc!)
        
        try BankingTokenRepository.incTransactionCounter(token: token)
        return try TanGenerator.generateTan(token: token, hhduc: hhduc)
    }
    
    private func computeFormattedTan(token : BankingToken) throws -> String {
        let tan = try computeTan(token: token)
        
        return TanGenerator.formatTAN(tan: tan)
    }
    
    @IBAction func confirmButtonAction(_ sender: UIButton){
        let usableTokens = BankingTokenRepository.getAllUsable()
        
        if usableTokens.count > 1 {
            // Select token to use
            goSelectToken(tokens: usableTokens)
        } else if usableTokens.count == 1{
            // Use only existing token
            bankingToken = usableTokens.first
            onTokenSelected()
        } else{
            // No token available
            let alert = UIAlertController(title: NSLocalizedString("no_tokens_available_title", comment: ""), message: NSLocalizedString("no_tokens_available_message", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", comment: ""), style: .default, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func goSelectToken(tokens : [BankingToken]){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let controller = storyboard.instantiateViewController(withIdentifier: "SelectToken") as! SelectTokenViewController

        controller.tokens = tokens
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        transitionDelegate.hideIndicatorWhenScroll = true
        transitionDelegate.tapAroundToDismissEnabled = false
        transitionDelegate.hapticMoments = [.willPresent, .willDismissIfRelease]
        transitionDelegate.customHeight = 250
        transitionDelegate.showIndicator = false
        transitionDelegate.swipeToDismissEnabled = false
        controller.transitioningDelegate = transitionDelegate
        controller.modalPresentationStyle = .custom
        controller.modalPresentationCapturesStatusBarAppearance = true

        self.present(controller, animated: true, completion: nil)
    }
    
    private func getFormattedTransactionCounter(token : BankingToken) -> String{
        return String(token.transactionCounter)
    }

    private func onTokenSelected(){
        if bankingToken!.confirmDeviceCredentialsToUse {
            let myContext = LAContext()
            var authError: NSError?
            
            if myContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
                myContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: Utils.localizedString("authorize_to_generate_tan")) { success, evaluateError in
                    DispatchQueue.main.async {
                        if success {
                            print("Credentials successfully confirmed")
                            self.onTokenReadyToUse()
                        } else {
                            print("Credentials not confirmed")
                            self.showAuthFailedAlert()
                            
                        }
                    }
                }
            } else{
                print("Cannot evaluate policy for owner authentication")
                self.showAuthFailedAlert()
            }

        }else{
            onTokenReadyToUse()
        }
    }
    
    private func showAuthFailedAlert(){
        let alert = UIAlertController(title: NSLocalizedString("device_auth_failed", comment: ""), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", comment: ""), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func onTokenReadyToUse() {
        var tan : String
        do {
            tan = try computeFormattedTan(token: bankingToken!)
        } catch HHDuc.UnsupportedDataFormatError.error(let message){
            print("Cannot compute TAN: \(message)")
            return
        } catch SecurityHandlerError.error(let message){
            print("Cannot compute TAN: \(message)")
            return
        } catch {
            print("Unexpected error computing TAN")
            return
        }
        
        self.textTAN.text = tan
        self.textTANContainer.popIn()
        
        if textATCContainer != nil {
            self.textATC.text = getFormattedTransactionCounter(token: bankingToken!)
            self.textATCContainer.popIn()
        }
        
        self.confirmButton.isHidden = true
        self.instructionTAN.isHidden = true
        
        self.navBar.leftButton.isHidden = true
        self.navBar.rightButton.isHidden = false
    }

}

// MARK: TableView

extension VerifyTransactionDetailsController {
    
    private func getNonEmptyDataElementTypes() -> [DataElementType] {
        var nonEmptyDataElementTypes = [DataElementType]()
        if let _hhduc = hhduc {
            for element in _hhduc.getDataElementTypes() {
                let value = try! _hhduc.getDataElement(type: element)
                if !value.isEmpty {
                    nonEmptyDataElementTypes.append(element)
                }
            }
        }
        return nonEmptyDataElementTypes
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNonEmptyDataElementTypes().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "DataElement", for: indexPath) as! VerifyTransactionDetailsCell
        let type = getNonEmptyDataElementTypes()[indexPath.row]
        var value = try! hhduc!.getDataElement(type: type)
        
        if ibanTypes.contains(type) {
            var iban : String = ""
            
            for blockStart in stride(from: 0, to: value.count, by: 4) {
                if blockStart > 0 {
                    iban.append(" ")
                }
                
                let blockEnd = min(0, (value.count-blockStart-4) * -1)
                
                let start = value.index(value.startIndex, offsetBy: blockStart)
                let end = value.index(value.endIndex, offsetBy: blockEnd)
                
                iban.append(String(value[start..<end]))
            }
            value = iban
        }
        
        
        if type.attr.format == DataElementTypeAttributes.Format.numeric {
            // Make numbers respect the device's locale
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let number =  value.replacingOccurrences(of: ",", with: ".")
            if let formattedNumber = formatter.number(from: number), let formattedString = formatter.string(from: formattedNumber) {
                value = formattedString
            }
        }
        
        cell.labelLabel?.text = getString(dataElementType: type)
        cell.valueLabel?.text = value
        return cell
    }
    
}

extension Notification.Name {
    static let tokenSelected = Notification.Name("tokenSelected")
}
