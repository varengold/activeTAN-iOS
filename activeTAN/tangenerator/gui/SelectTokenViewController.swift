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
import SPFakeBar

class SelectTokenViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource  {
    
    @IBOutlet weak var tokenPicker : UIPickerView!
    
    let navBar = SPFakeBarView(style: .small)
    
    var tokens : [BankingToken]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tokenPicker.delegate = self
        self.tokenPicker.dataSource = self
        
        self.navBar.addStatusBarHeight = false
        self.navBar.titleLabel.text = Utils.localizedString("choose_token_title")
        
        self.navBar.leftButton.setTitle("Zurück", for: .normal)
        self.navBar.leftButton.addTarget(self, action: #selector(self.back), for: .touchUpInside)
        self.navBar.rightButton.setTitle(Utils.localizedString("choose_token_done"), for: .normal)
        self.navBar.rightButton.addTarget(self, action: #selector(self.selectToken), for: .touchUpInside)
        
        // If version >= 13, respect dark mode settings
        if #available(iOS 13.0, *), traitCollection.userInterfaceStyle == .dark {
            self.navBar.backgroundColor = .systemGray3
            self.navBar.separatorView.backgroundColor = .systemBackground
        }

        userInterfaceStyleDependantStyling()
        
        self.view.addSubview(self.navBar)
    }

    private func userInterfaceStyleDependantStyling(){
        self.navBar.elementsColor = Utils.color(key: "accent", traitCollection: self.traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        userInterfaceStyleDependantStyling()
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
