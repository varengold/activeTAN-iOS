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

class SelectTokenViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource  {
    
    @IBOutlet weak var tokenPicker : UIPickerView!
    
    var tokens : [BankingToken]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tokenPicker.delegate = self
        self.tokenPicker.dataSource = self
        
        self.title = Utils.localizedString("choose_token_title")
        
        let leftButton = UIBarButtonItem(title: Utils.localizedString("nav_button_back"), style: .plain, target: self, action: #selector(self.back))
        self.navigationItem.leftBarButtonItem  = leftButton
        
        let rightButton = UIBarButtonItem(title: Utils.localizedString("choose_token_done"), style: .plain, target: self, action: #selector(self.selectToken))
        self.navigationItem.rightBarButtonItem  = rightButton
        
    }
    
    @objc func back(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func selectToken() {
        let userInfo = [ "token" : tokens![tokenPicker.selectedRow(inComponent: 0)] ]
        NotificationCenter.default.post(name: .tokenSelected, object: nil, userInfo: userInfo)
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: UIPickerView

extension SelectTokenViewController {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return tokens!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
       return 50
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var text : String = tokens![row].displayName()
        
        // If the user has initialized a token for a non-default backend,
        // we must display the backend name for each token.
        if !tokens!.filter({ token in
            return !token.isDefaultBackend()}).isEmpty {
            let backendNames = Utils.localizedString("backend_names").split(separator: "\n")
            let backendName = String(backendNames[Int(tokens![row].backendId)])
            text += "\n" + "(" + backendName + ")"
        }
        
        let label: UILabel
        if let view = view {
            label = view as! UILabel
        } else {
            label = UILabel(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width - 80, height: pickerView.frame.height))
        }

        label.text = text
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()

        return label
    }
}
