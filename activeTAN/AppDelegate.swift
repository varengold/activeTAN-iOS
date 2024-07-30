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
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    weak var scannerNavigation : UIViewController?
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "activeTAN")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                
                fatalError("Unresolved error, \((error as NSError).userInfo)")
            }
        })
        return container
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.window?.rootViewController = initialViewController()
        
        return true
    }
    
    func initialViewController() -> UIViewController{
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if BankingTokenRepository.getAllUsable().count == 0 {
            return storyboard.instantiateViewController(withIdentifier: "Welcome") as! WelcomeViewController
        }else{
            // ScannerNavigation should only be instantiated once to avoid multiple registration of observers.
            if scannerNavigation == nil{
                scannerNavigation = storyboard.instantiateViewController(withIdentifier: "ScannerNavigation")
            }
            return scannerNavigation!
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // Entry point for app when accessed via URL scheme by banking app for TAN generation.
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BankingAppApi") as! BankingAppApi
        controller.fileName = url.host?.removingPercentEncoding
        self.window?.rootViewController = controller
            
        return true
    }
    
    // Entry point for app when accessed via Universal Link
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        let emailInitializationEnabled = Utils.configBool(key: "email_initialization_enabled")
        
        guard emailInitializationEnabled else {
            print("Email initialization not enabled")
            return false
        }
        
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: false) else {
            print("Failure during url component parsing")
            return false
        }

        // Check for specific URL components that you need.
        var bqrEncoded : String
        if (components.fragment != nil) {
            // New version:
            // key material is encoded as an url fragment
            bqrEncoded = components.fragment!
        } else if (components.query != nil) {
            // Old version (for backwards compatibility):
            // key material has been encoded as an url query
            bqrEncoded = components.query!
        } else {
            print("Url without parameter")
            return false
        }
        
        var detectedBackendId : Int?
        let backendApiUrls = Utils.configArray(key: "backend_api_url")
        for (backendId, backendApiUrl) in backendApiUrls.enumerated() {
            let backendApiUrlComponents = NSURLComponents(url: URL(string: backendApiUrl)!, resolvingAgainstBaseURL: false)!
            
            // The app link refers to a landing page in the online banking application,
            // which also hosts the api for this app.
            // The online banking application can be identified by the domain
            // and the first path segment.
            let host1 = backendApiUrlComponents.host!
            let host2 = components.host!
            let firstPathUrl1 = backendApiUrlComponents.path!.components(separatedBy: "/")[1]
            let firstPathUrl2 = components.path!.components(separatedBy: "/")[1]
            if host1 == host2 && firstPathUrl1 == firstPathUrl2 {
                detectedBackendId = backendId
                break
            }
        }
        if detectedBackendId == nil {
            print("could not identify backend")
            return false
        }
        
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InitializeTokenFromAppLink") as! InitializeTokenFromAppLinkViewController
        
        controller.base64QrCode = Utils.base64UrlToBase64(base64Url: bqrEncoded)
        controller.backendId = detectedBackendId

        let navController = InitializeTokenContainerController(rootViewController: controller)

        self.window?.rootViewController = navController
        return true
    }
}

