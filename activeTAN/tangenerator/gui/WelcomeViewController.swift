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

class WelcomeViewController : ScrollStickyFooterViewController{
    
    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var subtitleLabel : UILabel!
    @IBOutlet weak var instructionLabel : UILabel!
    @IBOutlet weak var actionButton : DefaultButton!
    
    @IBOutlet weak var menuButton : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideNavigationBar()
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationBar.prefersLargeTitles = false
        
        titleLabel.text = Utils.localizedString("welcome_title")
        subtitleLabel.text = Utils.localizedString("welcome_subtitle")
        subtitleLabel.adjustsFontSizeToFitWidth = true
        instructionLabel.text = Utils.localizedString("welcome_start_activation_instruction")
        instructionLabel.adjustsFontSizeToFitWidth = true
        menuButton.setTitle(Utils.localizedString("welcome_menu"), for: .normal)
        menuButton.titleLabel?.adjustsFontSizeToFitWidth = true
        actionButton.setTitle(Utils.localizedString("welcome_start_activation_start"), for: .normal)
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        userInterfaceStyleDependantStyling()
    }
    
    private func userInterfaceStyleDependantStyling(){
        menuButton.tintColor = Utils.color(key: "accent", traitCollection: self.traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        userInterfaceStyleDependantStyling()
    }
    
    @IBAction func goMenu(sender : UIButton){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Menu") as! MenuViewController
        
        let nc = StyledNavigationController(rootViewController: controller)
        
        self.present(nc, animated: true, completion: nil)

    }
}
