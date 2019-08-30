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


class WelcomeViewController : UIViewController{
    
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
        
        titleLabel.text = NSLocalizedString("welcome_title", comment: "")
        subtitleLabel.text = NSLocalizedString("welcome_subtitle", comment:"")
        subtitleLabel.adjustsFontSizeToFitWidth = true
        instructionLabel.text = NSLocalizedString("welcome_start_activation_instruction", comment: "")
        
        menuButton.setTitle(Utils.localizedString("welcome_menu"), for: .normal)
        
        actionButton.setTitle(NSLocalizedString("welcome_start_activation_start", comment: ""), for: .normal)
        
    }
    
    @IBAction func goMenu(sender : UIButton){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Menu") as! MenuViewController

        let nc = UINavigationController(rootViewController: controller)
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        nc.transitioningDelegate = transitionDelegate
        nc.modalPresentationStyle = .custom
        nc.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showCloseButton = true
        
        self.present(nc, animated: true, completion: nil)

    }
}
