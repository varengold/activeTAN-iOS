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

extension BankingToken {
    func displayName() -> String{
        if let _name = name, !_name.isEmpty {
            return _name
        }
        return formattedSerialNumber()
    }
    
    func formattedSerialNumber() -> String {
        return Utils.formatSerialNumber(serialNumber: id!)
    }
    
    static func parseFormattedSerialNumber(formattedSerialNumber : String) -> String {
        return formattedSerialNumber.replacingOccurrences(of: "-", with: "")
    }
    
    func isDefaultBackend() -> Bool {
        return backendId == 0
    }

}
