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
import CoreData

class StringEditViewController : UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var editTextField : UITextField!
    
    var managedObject : NSManagedObject?
    var managedObjectStringKey : String?
    
    var maxLength : Int?
    let emptyAllowed : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editTextField.delegate = self
        editTextField.becomeFirstResponder()
        
        
        if let _managedObject = managedObject, let _managedObjectStringKey = managedObjectStringKey {
            let defaultText = _managedObject.value(forKey: _managedObjectStringKey) as! String
            editTextField.text = defaultText
        } else{
            // Not all required attributes set -> abort
            self.navigationController?.popViewController(animated: false)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let newText = editTextField.text else{
            return false
        }
        let trimmedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.count == 0 && !emptyAllowed{
            return false
        }

        textField.resignFirstResponder()
        managedObject?.setValue(trimmedText, forKey: managedObjectStringKey!)
        BankingTokenRepository.save()
        self.navigationController?.popViewController(animated: true)
        
        return true
    }
    
    // Max length on text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let _maxLength = maxLength {
            guard let textFieldText = textField.text,
                let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                    return false
            }
            let substringToReplace = textFieldText[rangeOfTextToReplace]
            let count = textFieldText.count - substringToReplace.count + string.count
            return count <= _maxLength
        }
        return true
    }
}
