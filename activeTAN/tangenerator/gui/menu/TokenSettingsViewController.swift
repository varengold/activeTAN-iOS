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

class TokenSettingsViewController : UITableViewController {
    
    var bankingToken : BankingToken?
    
    @IBOutlet weak var labelExhaustedToken : UILabel!
    @IBOutlet weak var labelInvalidKey : UILabel!
    @IBOutlet weak var labelTokenName : UILabel!
    @IBOutlet weak var valueTokenName : UILabel!
    @IBOutlet weak var labelTokenId : UILabel!
    @IBOutlet weak var valueTokenId : UILabel!
    @IBOutlet weak var labelCreatedOn : UILabel!
    @IBOutlet weak var valueCreatedOn : UILabel!
    @IBOutlet weak var labelLastUsed : UILabel!
    @IBOutlet weak var valueLastUsed : UILabel!
    @IBOutlet weak var labelProtectUsage : UILabel!
    @IBOutlet weak var labelDeleteToken : UILabel!
    
    @IBOutlet weak var confirmDeviceCredentialsToUseSwitch : UISwitch!
    
    var hasInvalidKey : Bool = false
    var isExhausted : Bool = false
    
    static let tokenNameMaxLength : Int = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.largeTitleDisplayMode = .never
        
        labelTokenName.text = Utils.localizedString("menu_token_name")
        labelTokenId.text = Utils.localizedString("menu_serial_number")
        labelCreatedOn.text = Utils.localizedString("active_since_label")
        labelLastUsed.text = Utils.localizedString("last_used_label")
        labelProtectUsage.text = Utils.localizedString("protect_usage")
        labelDeleteToken.text = Utils.localizedString("delete_token")
        
        labelInvalidKey.text = Utils.localizedString("invalidated_key_description")
        labelExhaustedToken.text = Utils.localizedString("exhausted_generator_description")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Call here to refresh view after returning from subsequent controllers which modify the data
        fillTableView()
    }
    
    func fillTableView() {
        guard let _bankingToken = bankingToken else{
            return
        }
        
        hasInvalidKey = BankingTokenRepository.hasValidKey(bankingToken: _bankingToken)
        isExhausted = BankingTokenRepository.isExhausted(bankingToken: _bankingToken)
        
        valueTokenName.text = _bankingToken.name
        valueTokenId.text = _bankingToken.formattedSerialNumber()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        valueCreatedOn.text = dateFormatter.string(from: _bankingToken.createdOn!)
        if let lastUsed = _bankingToken.lastUsed {
            valueLastUsed.text = dateFormatter.string(from: lastUsed)
        } else{
            valueLastUsed.text = "–"
        }
        
        confirmDeviceCredentialsToUseSwitch.setOn(_bankingToken.confirmDeviceCredentialsToUse, animated: false)
        confirmDeviceCredentialsToUseSwitch.addTarget(self, action: #selector(confirmDeviceCredentialsToUseSwitchChanged), for: UIControl.Event.valueChanged)
    }
    
    @objc func confirmDeviceCredentialsToUseSwitchChanged(_switch: UISwitch){
        let on = _switch.isOn
        
        let myContext = LAContext()
        var authError: NSError?
        
        if on {
            // Use device credentials
            
            if myContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
                // Ask for policy evaluation here to ask user for e.g. face id persmission at first use.
                myContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: Utils.localizedString("authorize_to_lock_token")) {
                    success, evaluateError in
                    if success {
                        // Save setting
                        self.bankingToken!.setValue(true, forKey: "confirmDeviceCredentialsToUse")
                        BankingTokenRepository.save()
                        return
                    }else{
                        self.setSwitch(_switch, on: false, animated: false)
                    }
                }
            } else{
                self.setSwitch(_switch, on: false, animated: false)
            }
            
        } else{
            // Don't use device credentials
            if myContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
                myContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: Utils.localizedString("authorize_to_unlock_token")) { success, evaluateError in
                    DispatchQueue.main.async {
                        if success {
                            // Save setting
                            self.bankingToken!.setValue(false, forKey: "confirmDeviceCredentialsToUse")
                            BankingTokenRepository.save()
                        }else{
                            self.setSwitch(_switch, on: true, animated: false)
                        }
                    }
                }
            }
        }
    }
    
    private func setSwitch(_ _switch: UISwitch, on : Bool, animated: Bool){
        // UI api must not be called from background thread
        DispatchQueue.main.async {
            _switch.setOn(on, animated: animated)
        }
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 { // edit token name
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "StringEdit") as! StringEditViewController
            controller.managedObject = bankingToken
            controller.managedObjectStringKey = "name"
            controller.maxLength = TokenSettingsViewController.tokenNameMaxLength
            self.navigationController!.pushViewController(controller, animated: true)
        }
        else if indexPath.section  == 3 && indexPath.row == 0 { // delete token
            tableView.deselectRow(at: indexPath, animated: false)
            deleteTokenAlert()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Hide table view cell with invalidated key message, if token is usable
        if hasInvalidKey && indexPath.section == 3 && indexPath.row == 1 {
            // Workaround for table views with static content: set height of cell to 0 if cell shouldn't be displayed
            return 0
        }
        if !isExhausted && indexPath.section == 3 && indexPath.row == 2 {
            // Workaround for table views with static content: set height of cell to 0 if cell shouldn't be displayed
            return 0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return Utils.localizedString("menu_token_title")
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return Utils.localizedString("do_protect_usage_description")
        }
        return nil
    }
    
    private func deleteTokenAlert(){
        var title = Utils.localizedString("message_delete_token_confirmation")
        if !Utils.configBool(key: "email_initialization_enabled") {
            title += " " + Utils.localizedString("message_delete_token_letter_warning")
        }
        let alert = UIAlertController(
            title: String.localizedStringWithFormat(title),
            message: nil,
            preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(
            title: String.localizedStringWithFormat(Utils.localizedString("button_cancel_delete_token")),
            style: .cancel,
            handler: nil))
        alert.addAction(UIAlertAction(
            title: String.localizedStringWithFormat(Utils.localizedString("button_confirm_delete_token")),
            style: .destructive,
            handler: { action in
            
            self.deleteTokenFromCoreDataAndKeychain()
            NotificationCenter.default.post(name: .reloadTokens, object: nil)
            self.navigationController!.popViewController(animated: false)
        }))
        
        self.present(alert, animated: true)
    }
    
    private func deleteTokenFromCoreDataAndKeychain(){
        do {
            let keyAlias = self.bankingToken!.keyAlias!
            
            try BankingTokenRepository.deleteToken(keyAlias: keyAlias)
            
            try SecurityHandler.deleteFromKeychain(key: keyAlias)
            
        } catch {
            // TODO
        }
    }

}
