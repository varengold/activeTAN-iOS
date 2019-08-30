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

class InitializeTokenStep3ViewController : UIViewController {

    @IBOutlet weak var containerView : UIView!
    @IBOutlet weak var titleLabel : UILabel!
    @IBOutlet weak var descriptionLabel : UILabel!
    @IBOutlet weak var hintLabel : UILabel!
    @IBOutlet weak var tanContainer : UIView!
    @IBOutlet weak var labelTan : UILabel!
    @IBOutlet weak var textTan : UILabel!
    @IBOutlet weak var actionButton : DefaultButton?

    var initialTAN : Int?
    
    // MARK: Life Circles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = NSLocalizedString("initialization", comment: "")
        
        self.descriptionLabel.text = NSLocalizedString("initialization_portal_scanned", comment: "")
        self.descriptionLabel.adjustsFontSizeToFitWidth = true
        
        self.hintLabel.text = NSLocalizedString("enter_initial_tan", comment: "") + "\n\n" + NSLocalizedString("initialization_completed", comment: "")
        self.hintLabel.adjustsFontSizeToFitWidth = true
        
        labelTan.text = NSLocalizedString("initial_tan", comment: "")
        labelTan.adjustsFontSizeToFitWidth = true
        textTan.text = TanGenerator.formatTAN(tan: initialTAN!)
        
        tanContainer.layer.cornerRadius = 8
        tanContainer.clipsToBounds = true
        
        actionButton?.setTitle(NSLocalizedString("initialization_action_finished", comment: ""), for: .normal)
        actionButton?.hide()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            self.actionButton?.fadeIn()
        })
    }
}