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

class HowToInitializeViewController : HowToSlidesViewController{
    @IBOutlet weak var actionButton : DefaultButton!
    @IBOutlet weak var rightBarButton : UIBarButtonItem!
    
    override func viewDidLoad() {
        self.setupSlides()
        super.viewDidLoad()
        
        self.actionButton.setTitle(Utils.localizedString("next_step"), for: .normal)
        
        self.rightBarButton.title = Utils.localizedString("nav_button_back")
    }
    
    func setupSlides(){
        slides = MenuViewController.getInitializationSlides()
    }
    
    @IBAction func dismissVC(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func startInitialization(_ sender : Any) {
        performSegue(withIdentifier: "startInitialization", sender: nil)
    }
 
}
