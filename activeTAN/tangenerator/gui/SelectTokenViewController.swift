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
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return tokens![row].displayName()
    }
}
