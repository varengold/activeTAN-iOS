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

class MenuDetailViewController : UIViewController {

    var text: String?
    var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        createTextLabel()
    }
    
    private func createTextLabel() {
        textLabel = UILabel(frame: view.bounds)
        textLabel.numberOfLines = 0 // multiline text
        textLabel.lineBreakMode = .byWordWrapping
        
        do {
            // Interpret text as html
            let attrStr = try NSAttributedString(
                data: text!.data(using: String.Encoding.unicode)!,
                options: [ NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil)
            
            // Apply standard settings to font family and size (e.g. accessibility settings)
            let preferredFont = UIFont.preferredFont(forTextStyle: .body)
            
            // Reduce text size proportionally to the preset size
            let newFont = UIFontMetrics.default.scaledFont(for: UIFont.init(name: preferredFont.familyName, size: preferredFont.pointSize*0.8)! )
            
            // Apply font family and size to text; keep other html elements
            let mattrStr = NSMutableAttributedString(attributedString: attrStr)
            mattrStr.beginEditing()
            mattrStr.enumerateAttribute(.font, in: NSRange(location: 0, length: mattrStr.length), options: .longestEffectiveRangeNotRequired) { (value, range, _) in
                if let oFont = value as? UIFont, let newFontDescriptor = oFont.fontDescriptor.withFamily(newFont.familyName).withSymbolicTraits(oFont.fontDescriptor.symbolicTraits) {
                    let nFont = UIFont(descriptor: newFontDescriptor, size: newFont.pointSize)
                    mattrStr.removeAttribute(.font, range: range)
                    mattrStr.addAttribute(.font, value: nFont, range: range)
                }
            }
            mattrStr.endEditing()
            
            textLabel.attributedText = mattrStr
        } catch let error {
            print("Error presenting settings detail view text: \(error)")
            return
        }
        
        // Add label to view (within ScrollView)
        
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(textLabel)
        view.addSubview(scrollView)
        
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 0),
            scrollView.bottomAnchor.constraint(equalToSystemSpacingBelow: guide.bottomAnchor, multiplier: 0),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor)
        ])

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalToSystemSpacingBelow: scrollView.topAnchor, multiplier: 2.0),
            textLabel.bottomAnchor.constraint(equalToSystemSpacingBelow: scrollView.bottomAnchor, multiplier: 2.0),
            textLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        ])
    }
    
}
