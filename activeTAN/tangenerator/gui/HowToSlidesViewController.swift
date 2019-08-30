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

class HowToSlidesViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView : UIScrollView!
    @IBOutlet weak var pageControl : UIPageControl!
    
    var slides : [HowToSlide]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localizeBackButton()
        
        scrollView.delegate = self
        
        if let _slides = slides {
            setupScrollView(slides: _slides)
        }
        
        pageControl.currentPage = 0
        view.bringSubviewToFront(pageControl)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        slides[0].descriptionScrollView.flashScrollIndicators()
    }
    
    private func setupScrollView(slides : [HowToSlide]) {
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: scrollView.contentSize.height)
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
            scrollView.addSubview(slides[i])
        }
        
        pageControl.numberOfPages = slides.count
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let _slides = slides {
            let pageIndex = Int(round(scrollView.contentOffset.x/view.frame.width))
            pageControl.currentPage = pageIndex
            
            if pageIndex >= 0 && pageIndex < _slides.count {
                _slides[pageIndex].descriptionScrollView.flashScrollIndicators()
            }
        }
    }
    
}
