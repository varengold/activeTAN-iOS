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

class ScrollStickyFooterViewController : UIViewController {
    
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var stickyFooter : StickyFooter!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if scrollView.contentSize.height + stickyFooter.frame.height > scrollView.frame.height {
            stickyFooter.blurBackground()
            if let bottomConstraint = scrollView.constraintWithIdentifier("bottom") {
                bottomConstraint.constant = stickyFooter.frame.height
            }
        }else{
            stickyFooter.unblurBackground()
            resetBottomPadding()
        }
    }
    
    func resetBottomPadding(){
        if let bottomConstraint = scrollView.constraintWithIdentifier("bottom") {
            bottomConstraint.constant = 0
        }
    }
}
