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
import SPFakeBar

class SelectTokenViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource  {
    
    @IBOutlet weak var tokenPicker : UIPickerView!
    
    let navBar = SPFakeBarView(style: .small)
    
    var tokens : [BankingToken]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        self.tokenPicker.delegate = self
        self.tokenPicker.dataSource = self
        
        self.navBar.addStatusBarHeight = false
        self.navBar.titleLabel.text = NSLocalizedString("choose_token_title", comment: "")
        
        self.navBar.leftButton.setTitle("Zurück", for: .normal)
        self.navBar.leftButton.addTarget(self, action: #selector(self.back), for: .touchUpInside)
        self.navBar.rightButton.setTitle(NSLocalizedString("choose_token_done", comment: ""), for: .normal)
        self.navBar.rightButton.addTarget(self, action: #selector(self.selectToken), for: .touchUpInside)
        
        self.view.addSubview(self.navBar)
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
