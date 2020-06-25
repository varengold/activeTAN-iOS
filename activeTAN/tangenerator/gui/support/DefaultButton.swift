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

class DefaultButton : UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        style()
    }
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
        style()
    }
    
    // custom styles for default button
    private func style(){
        userInterfaceStyleDependantStyling()
        self.setTitleColor(UIColor.white, for: .normal)
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.contentEdgeInsets = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        self.titleLabel?.font = UIFont.boldSystemFont(ofSize: (self.titleLabel?.font.pointSize)!)
    }
    
    private func userInterfaceStyleDependantStyling(){
        self.setBackgroundColor(color: Utils.color(key: "action", traitCollection: self.traitCollection), forState: .normal)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        userInterfaceStyleDependantStyling()
    }
}
