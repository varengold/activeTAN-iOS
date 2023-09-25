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

import Foundation
import UIKit

class Utils {
    
    public static func color(key: String, traitCollection: UITraitCollection) -> UIColor {
        let _key : String
        
        // If version >= 13, respect dark mode settings
        if #available(iOS 13.0, *), traitCollection.userInterfaceStyle == .dark {
                _key = "dark_mode_" + key
        } else {
            _key = "light_mode_" + key
        }
        
        if let property = readPlistString(plist: "Colors", key: _key) {
            return UIColor.init(hex: property)!
        }
        return UIColor.clear
    }
    
    public static func config(key: String) -> String{
        if let property = readPlistString(plist : "Config", key: key) {
            return property
        }
        return ""
    }
    
    private static func readPlistString(plist: String, key: String) -> String? {
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: plist, ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
            return nsDictionary![key] as? String
        }
        return nil
    }
    
    public static func configBool(key: String) -> Bool{
        if let property = readPlistBool(plist : "Config", key: key) {
            return property
        }
        return false
    }
    
    private static func readPlistBool(plist: String, key: String) -> Bool? {
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: plist, ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
            return nsDictionary![key] as? Bool
        }
        return nil
    }
    
    public static func configArray(key: String) -> [String]{
        if let property = readPlistArray(plist : "Config", key: key) {
            return property
        }
        return []
    }
    
    private static func readPlistArray(plist: String, key: String) -> [String]? {
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: plist, ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
            return nsDictionary![key] as? [String]
        }
        return nil
    }
    
    static func copyOfRange<T>(arr: [T], from: Int, to: Int) -> [T]? where T: ExpressibleByIntegerLiteral {
        guard from >= 0 && from <= arr.count && from <= to else { return nil }
        
        var to = to
        var padding = 0
        
        if to > arr.count {
            padding = to - arr.count
            to = arr.count
        }
        
        return Array(arr[from..<to]) + [T](repeating: 0, count: padding)
    }
    
    static func formatSerialNumber(serialNumber : String) -> String {
        let input = serialNumber
        
        var result : String = ""
        var i : Int = 0
        for character in input {
            i += 1
            result.append(character)
            if i < 12 && i%4 == 0 {
                result.append("-")
            }
        }
        return result
    }
    
    static func localizedString(_ key: String) -> String {
        let notFound = "*notfound"
        var result = Bundle.main.localizedString(forKey: key, value: notFound, table: "Custom")
        
        if result == notFound {
            result = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        }
        
        return result
    }
    
    static func base64UrlToBase64(base64Url: String) -> String {
        let base64 = base64Url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        return base64
    }
}
