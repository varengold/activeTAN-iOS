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

class PartialModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PartialModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class PartialModalPresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = presentingViewController.view.bounds
        let size = CGSize(width: UIScreen.main.bounds.width, height: 250)
        let origin = CGPoint(x: bounds.midX - size.width / 2, y: UIScreen.main.bounds.maxY - size.height)
        return CGRect(origin: origin, size: size)
    }

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        presentedView?.autoresizingMask = [
            .flexibleTopMargin,
            .flexibleBottomMargin,
            .flexibleLeftMargin,
            .flexibleRightMargin
        ]

        presentedView?.translatesAutoresizingMaskIntoConstraints = true
        
        presentedView?.clipsToBounds = true
        presentedView?.layer.cornerRadius = 10.0
        presentedView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    let dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor.black
        return dimmingView
    }()

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        let superview = presentingViewController.view!
        superview.addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            dimmingView.topAnchor.constraint(equalTo: superview.topAnchor)
        ])

        dimmingView.alpha = 0
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.5
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.dimmingView.removeFromSuperview()
        })
    }
}
