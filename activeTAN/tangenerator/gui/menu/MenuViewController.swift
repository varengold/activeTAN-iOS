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

class MenuViewController : UITableViewController{

    var sections : [MenuSection]?
    var tokens : [BankingToken]?
    
    var presentedModally : Bool = false
    
    var manualMenuElements = [
        // Initialization
        MenuElement(
            Utils.localizedString("initialization"),
            slides: getInitializationSlides()
        ),
        // Primary use
        MenuElement(
            Utils.localizedString("instructionPrimaryUseTitle"),
            slides: getPrimaryUseSlides()
        ),
        // Security
        MenuElement(
            Utils.localizedString("instructionSecurityTitle"),
            text: Utils.localizedString("instructionSecurityText")
        )
    ]
    
    var staticMenuElements = [
        // Privacy statement
        MenuElement(
            Utils.localizedString("menu_item_privacy"),
            text: Utils.localizedString("privacy_statement") + String(format: Utils.localizedString("privacy_statement_closing"), Utils.localizedString("bank_name"))
        ),
        // License
        MenuElement(Utils.localizedString("menu_item_copyright"), text: Utils.localizedString("license")),
        // Imprint
        MenuElement(
            Utils.localizedString("menu_item_imprint"),
            text: Utils.localizedString("imprint")
        )
    ]
    
    override func viewDidLoad() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0
        
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        loadTokens()
        initTable()
        
        self.title = Utils.localizedString("menu_title")
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadTokens), name: .reloadTokens, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initTable()
        
        // Refresh view after returning from subsequent controllers which modify the data
        tableView.reloadData()
        
        if presentingViewController is WelcomeViewController {
            self.presentedModally = true
            self.showModalDismissButton()
        } else{
            self.presentedModally = false
        }
    }
    
    @objc func loadTokens(){
        tokens = BankingTokenRepository.getTokens()
    }
    
    private func initTable(){
        sections = [MenuSection]()
        
        if tokens!.count > 0 {
            sections?.append(MenuSection(type: MenuViewController.MenuSectionType.coupledAccounts, title: Utils.localizedString("menu_section_settings"), elements: nil))
        }
        
        sections?.append(MenuSection(type: MenuViewController.MenuSectionType.staticViews, title: Utils.localizedString("menu_item_instruction"), elements: manualMenuElements))
        
        sections?.append(MenuSection(type: MenuViewController.MenuSectionType.staticViews, title: Utils.localizedString("menu_section_info"), elements: staticMenuElements))
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections![section].title
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sections![section].type
        
        if sectionType == MenuSectionType.coupledAccounts{
            // Coupled accounts
            return tokens!.count
        } else if sectionType == MenuSectionType.staticViews {
            // Menu text views
            return sections![section].elements!.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = sections![indexPath.section].type
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        cell.textLabel!.font = .preferredFont(forTextStyle: .body) // adapt text size to accessibility settings

        if sectionType == MenuSectionType.coupledAccounts {
            // Coupled accounts
            cell.textLabel!.text = tokens![indexPath.row].name
            cell.detailTextLabel!.text = tokens![indexPath.row].formattedSerialNumber()
        } else if sectionType == MenuSectionType.staticViews {
            // Menu text views
            let menuElement = sections![indexPath.section].elements![indexPath.row]
            cell.textLabel!.text = menuElement.title
            cell.detailTextLabel!.text = ""
        }
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionType = sections![indexPath.section].type
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if sectionType == MenuSectionType.coupledAccounts {
            // Coupled accounts
            let controller = storyboard.instantiateViewController(withIdentifier: "TokenSettings") as! TokenSettingsViewController
            controller.bankingToken = tokens![indexPath.row]
            self.navigationController!.pushViewController(controller, animated: true)
        } else if sectionType == MenuSectionType.staticViews {
            // Menu text views
            let menuElement = sections![indexPath.section].elements![indexPath.row]
            
            if menuElement.slides != nil && menuElement.slides!.count > 0 {
                // View with How-To-Slides
                let controller = storyboard.instantiateViewController(withIdentifier: "MenuHowToSlides") as! MenuHowToSlidesController
                controller.title = menuElement.title
                controller.slides = menuElement.slides!
                if presentedModally {
                    controller.showModalDismissButton()
                }
                self.navigationController!.pushViewController(controller, animated: true)
            } else{
                // Default text view
                let controller = storyboard.instantiateViewController(withIdentifier: "MenuDetailView") as! MenuDetailViewController
                controller.title = menuElement.title
                controller.text = menuElement.text
                if presentedModally {
                    controller.showModalDismissButton()
                }
                self.navigationController!.pushViewController(controller, animated: true)
            }
        }
        
    }
    
    static func getInitializationSlides() -> [HowToSlide]{
        var slides = [HowToSlide]()
        
        let slide0 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide0.imageView.image = UIImage(named: "activation_0")
        slide0.headlineLabel.text = Utils.localizedString("instructionStep0")
        slide0.descriptionLabel.text = Utils.localizedString("instructionGoToTanAdmin")
        slides.append(slide0)
        
        let slide1 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide1.imageView.image = UIImage(named: "activation_1")
        slide1.headlineLabel.text = Utils.localizedString("instructionStep1")
        slide1.descriptionLabel.text = Utils.localizedString("instructionScanLetter")
        slides.append(slide1)
        
        let slide2 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide2.imageView.image = UIImage(named: "activation_2")
        slide2.headlineLabel.text = Utils.localizedString("instructionStep2")
        slide2.descriptionLabel.text = Utils.localizedString("instructionEnterSerial")
        slides.append(slide2)
        
        let slide3 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide3.imageView.image = UIImage(named: "activation_3")
        slide3.headlineLabel.text = Utils.localizedString("instructionStep3")
        slide3.descriptionLabel.text = Utils.localizedString("instructionScanQrScreen")
        slides.append(slide3)
        
        let slide4 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide4.imageView.image = UIImage(named: "activation_4")
        slide4.headlineLabel.text = Utils.localizedString("instructionStep4")
        slide4.descriptionLabel.text = Utils.localizedString("instructionEnterStartTan")
        slides.append(slide4)
        
        return slides
    }

    static func getPrimaryUseSlides() -> [HowToSlide]{
        var slides = [HowToSlide]()
        
        let slide0 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide0.imageView.image = UIImage(named: "usage_0")
        slide0.headlineLabel.text = Utils.localizedString("instructionStep0")
        slide0.descriptionLabel.text = Utils.localizedString("instructionEnterOrder")
        slides.append(slide0)
        
        let slide1 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide1.imageView.image = UIImage(named: "usage_1")
        slide1.headlineLabel.text = Utils.localizedString("instructionStep1")
        slide1.descriptionLabel.text = Utils.localizedString("instructionScanQrScreen")
        slides.append(slide1)
        
        let slide2 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide2.imageView.image = UIImage(named: "usage_2")
        slide2.headlineLabel.text = Utils.localizedString("instructionStep2")
        slide2.descriptionLabel.text = Utils.localizedString("instructionCheckOrder")
        slides.append(slide2)
        
        let slide3 = Bundle.main.loadNibNamed("HowToSlide", owner: self, options: nil)?.first as! HowToSlide
        slide3.imageView.image = UIImage(named: "usage_3")
        slide3.headlineLabel.text = Utils.localizedString("instructionStep3")
        slide3.descriptionLabel.text = Utils.localizedString("instructionEnterTan")
        slides.append(slide3)
        
        return slides
    }
        
    enum MenuSectionType {
        case coupledAccounts
        case staticViews
    }
    
    struct MenuSection {
        var type: MenuSectionType
        var title: String
        var elements : [MenuElement]?
    }
}

extension Notification.Name {
    static let reloadTokens = Notification.Name("reloadTokens")
}
