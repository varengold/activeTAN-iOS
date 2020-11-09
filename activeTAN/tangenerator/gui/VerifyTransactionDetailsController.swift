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
import LocalAuthentication

class VerifyTransactionDetailsController : ScrollStickyFooterViewController, UITableViewDataSource, UITableViewDelegate {

    var rawHHDuc : [UInt8]?
    var hhduc : HHDuc?
    
    // The selected TAN generator for TAN computation
    private var bankingToken : BankingToken?
    
    // Flag, indicating whether this view controller has been started from the BankingAppApi.
    // If yes, the generated TAN will be returned to the caller instead of being displayed.
    private var startedFromApi : Bool?
    var bankingAppApi : BankingAppApi?
    
    var usableTokens : [BankingToken]?
    
    @IBOutlet weak var instructionTAN : UILabel!
    @IBOutlet weak var visualisationClass : UILabel!
    @IBOutlet weak var labelTAN : UILabel!
    @IBOutlet weak var textTAN : UILabel!
    @IBOutlet weak var textTANContainer : UIView!
    @IBOutlet weak var labelATC : UILabel!
    @IBOutlet weak var textATC : UILabel!
    @IBOutlet weak var textATCContainer : UIView!
    @IBOutlet weak var textExhaust : UILabel!
    @IBOutlet weak var textExhaustContainer : UIView!
    @IBOutlet weak var confirmButton : UIButton!
    @IBOutlet weak var dataElementsTable : IntrinsicSizeTableView!
    @IBOutlet weak var outputContainerHeight : NSLayoutConstraint!
    private let outputElementDistance = CGFloat(30)
    
    private final let ibanTypes : [DataElementType] = [.ibanOwn, .ibanSender, .ibanRecipient, .ibanPayer]
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.visualisationClass.adjustsFontSizeToFitWidth = true
        
        self.dataElementsTable.layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            self.dataElementsTable.layer.borderColor = UIColor.systemGray4.cgColor
            self.dataElementsTable.separatorColor = UIColor.systemGray4
        } else {
            self.dataElementsTable.layer.borderColor = UIColor.init(hex: "DDDDDD")?.cgColor
            self.dataElementsTable.separatorColor = UIColor.init(hex: "DDDDDD")
        }
        self.dataElementsTable.layer.cornerRadius = 8
        
        startedFromApi = (self.presentingViewController is BankingAppApi)
        
        if startedFromApi! {
            bankingAppApi = (self.presentingViewController as! BankingAppApi)
            self.title = (Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String)
            let leftButton = UIBarButtonItem(image: UIImage(systemName: "qrcode.viewfinder"), style: .plain, target: self, action: #selector(self.cancelApiCall))
            self.navigationItem.leftBarButtonItem  = leftButton
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundAfterApiCall), name: UIApplication.didEnterBackgroundNotification, object: nil)
        } else {
            self.title = Utils.localizedString("verify_transaction_details_title")
            let leftButton = UIBarButtonItem(title: Utils.localizedString("nav_button_back"), style: .plain, target: self, action: #selector(self.dismissAction))
            self.navigationItem.leftBarButtonItem  = leftButton
            usableTokens = BankingTokenRepository.getAllUsable()
        }
        
        textTANContainer.layer.cornerRadius = 8
        textTANContainer.clipsToBounds = true
        textTANContainer.isHidden = true
        labelTAN.text = Utils.localizedString("labelTAN")
        labelTAN.adjustsFontSizeToFitWidth = true
        textTAN.adjustsFontSizeToFitWidth = true
        
        textATCContainer.layer.cornerRadius = 8
        textATCContainer.clipsToBounds = true
        textATCContainer.isHidden = true
        labelATC.text = Utils.localizedString("labelATC")
        labelATC.adjustsFontSizeToFitWidth = true
        textATC.adjustsFontSizeToFitWidth = true
        
        textExhaustContainer.layer.cornerRadius = 8
        textExhaustContainer.clipsToBounds = true
        textExhaustContainer.isHidden = true
        
        instructionTAN.adjustsFontSizeToFitWidth = true
        
        confirmButton.setTitle(Utils.localizedString("confirm_transaction_details"), for: .normal)
        confirmButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
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
            visualisationClass.text = Utils.localizedString("synchronize_tan_generator")
            // TODO
        }
        
        if (hhduc?.getDataElementTypes().isEmpty)! {
            instructionTAN.text = Utils.localizedString("verify_transaction_without_details")
        } else{
            instructionTAN.text = Utils.localizedString("verify_transaction_with_details")
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
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func didEnterBackgroundAfterApiCall(){
        print("App did enter background after API call.")
        self.dismiss(animated: false, completion: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(bankingAppApi!, selector: #selector(bankingAppApi!.onRestart), name: UIApplication.didBecomeActiveNotification, object: nil)
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
    
    @objc func cancelApiCall(){
        print("API call canceled by user")
        bankingAppApi!.onDeclined()
    }
    
    private func showDismissalAlert(){
        let alert = UIAlertController(title: Utils.localizedString("unsupported_data_format_title"), message: Utils.localizedString("unsupported_data_format_message"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Utils.localizedString("alert_ok"), style: .default, handler: { action in
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
        return Utils.localizedString(name)
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
        if usableTokens!.count > 1 {
            // Select token to use
            goSelectToken(tokens: usableTokens!)
        } else if usableTokens!.count == 1{
            // Use only existing token
            bankingToken = usableTokens!.first
            onTokenSelected()
        } else{
            // No token available
            let alert = UIAlertController(title: Utils.localizedString("no_tokens_available_title"), message: Utils.localizedString("no_tokens_available_message"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Utils.localizedString("alert_ok"), style: .default, handler: { action in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func goSelectToken(tokens : [BankingToken]){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let controller = storyboard.instantiateViewController(withIdentifier: "SelectTokenNavigationController") as! UINavigationController

        (controller.viewControllers[0] as! SelectTokenViewController).tokens = tokens

        let transitionDelegate = PartialModalTransitioningDelegate()
        controller.modalPresentationStyle = .custom
        controller.modalTransitionStyle = .coverVertical
        controller.transitioningDelegate = transitionDelegate
        
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
        let alert = UIAlertController(title: Utils.localizedString("device_auth_failed"), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Utils.localizedString("alert_ok"), style: .default, handler: nil))
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
        
        if startedFromApi! {
            // When called from the banking app, we do not show the TAN, but return it to the caller
            returnTan(tan: tan)
        } else{
            showTan(tan: tan)
        }
    }
    
    private func returnTan(tan : String){
        bankingAppApi!.tanGeneratorId = bankingToken!.id
        bankingAppApi!.tan = tan
        if textATCContainer != nil {
            bankingAppApi!.atc = bankingToken!.transactionCounter
        }
        
        if BankingTokenRepository.isExhausted(bankingToken: bankingToken!) || BankingTokenRepository.isSoonExhausted(bankingToken: bankingToken!){
            // We need to show a warning before returning to the banking app.
            // This warning would usually be displayed below the TAN,
            // but since we return to the banking app immediately it would be not visible.
            // This, we use a dialog instead.
            
            let title = BankingTokenRepository.isExhausted(bankingToken: bankingToken!) ? Utils.localizedString("exhausted_generator_label") : Utils.localizedString("soon_exhausted_generator_label")
            let message = BankingTokenRepository.isExhausted(bankingToken: bankingToken!) ? Utils.localizedString("exhausted_generator_description") : Utils.localizedString("soon_exhausted_generator_description")
            
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(
                title: Utils.localizedString("ok"),
                style: .default,
                handler: { action in
                    self.bankingAppApi!.onChallengeResult()
            }))
            
            self.present(alert, animated: true)
        } else{
            bankingAppApi!.onChallengeResult()
        }
    }
    
    private func showTan(tan : String){
        self.textTAN.text = tan
        self.textTANContainer.popIn()
        self.outputContainerHeight.constant = self.textTANContainer.frame.height + outputElementDistance
        
        if textATCContainer != nil {
            self.textATC.text = getFormattedTransactionCounter(token: bankingToken!)
            self.textATCContainer.popIn()
            self.outputContainerHeight.constant += self.textATCContainer.frame.height + outputElementDistance
        }
        
        if BankingTokenRepository.isExhausted(bankingToken: bankingToken!) {
            self.textExhaust.text = Utils.localizedString("exhausted_generator_description")
            self.textExhaustContainer.popIn()
            self.outputContainerHeight.constant += self.textExhaustContainer.frame.height + outputElementDistance
        } else if BankingTokenRepository.isSoonExhausted(bankingToken: bankingToken!) {
            self.textExhaust.text = Utils.localizedString("soon_exhausted_generator_description")
            self.textExhaustContainer.popIn()
            self.outputContainerHeight.constant += self.textExhaustContainer.frame.height + outputElementDistance
        }
        
        self.stickyFooter.isHidden = true
        self.view.layoutIfNeeded()
        resetBottomPadding()
        
        // Show/hide buttons in navigation bar
        self.navigationItem.setLeftBarButtonItems(nil, animated: true)
        let rightButton = UIBarButtonItem(title: Utils.localizedString("verify_transaction_nav_button_done"), style: .plain, target: self, action: #selector(self.dismissAction))
        self.navigationItem.rightBarButtonItem  = rightButton
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
        cell.labelLabel?.adjustsFontSizeToFitWidth = true
        cell.valueLabel?.text = value
        cell.valueLabel?.adjustsFontSizeToFitWidth = true
        return cell
    }
    
}

extension Notification.Name {
    static let tokenSelected = Notification.Name("tokenSelected")
}
