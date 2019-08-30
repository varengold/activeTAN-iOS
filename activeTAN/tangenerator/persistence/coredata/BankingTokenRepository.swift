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

import Foundation
import UIKit
import CoreData

class BankingTokenRepository {

    static var managedContext : NSManagedObjectContext {
        let appDelegate: AppDelegate
        if Thread.current.isMainThread {
            appDelegate = UIApplication.shared.delegate as! AppDelegate
        } else {
            appDelegate = DispatchQueue.main.sync {
                return UIApplication.shared.delegate as! AppDelegate
            }
        }
        return appDelegate.persistentContainer.viewContext
    }
    
    static func insertNewToken(id: String, name: String, keyAlias : String) throws {
        let entity = NSEntityDescription.entity(forEntityName: "BankingToken", in: managedContext)!
        let bankingToken = NSManagedObject(entity: entity, insertInto: managedContext)
        
        bankingToken.setValue(id, forKey: "id")
        bankingToken.setValue(name, forKey: "name")
        bankingToken.setValue(keyAlias, forKey: "keyAlias")
        bankingToken.setValue(0, forKey: "transactionCounter")
        bankingToken.setValue(Date(), forKey: "createdOn")
        
        save()
    }
    
    static func readToken(keyAlias: String) throws -> BankingToken{
        let request = NSFetchRequest<BankingToken>(entityName: "BankingToken")

        request.predicate = NSPredicate(format: "keyAlias == %@", keyAlias)
        
        let bankingToken = try managedContext.fetch(request).first!
        return bankingToken
    }
    
    static func getTokens() -> [BankingToken]{
        let request = NSFetchRequest<BankingToken>(entityName: "BankingToken")
        
        return try! managedContext.fetch(request)
    }
    
    static func getAllUsable() -> [BankingToken]{
        let unfilteredTokens = getTokens()
        
        var filteredTokens = [BankingToken]()
        
        for bankingToken in unfilteredTokens {
            if isUsable(bankingToken: bankingToken){
                filteredTokens.append(bankingToken)
            } else{
                print("Not usable token \(String(describing: bankingToken.id)) found")
            }
        }
        
        return filteredTokens
    }
    
    static func isUsable(bankingToken : BankingToken) -> Bool{
        do {
            let encryptedKey = try SecurityHandler.loadFromKeychain(key: bankingToken.keyAlias!)
            let algorithm : SecKeyAlgorithm = SecurityHandler.enclaveAlgorithm
            
            // decrypt key
            let privateKey = try SecurityHandler.getPrivateKey()
            _ = try SecurityHandler.decrypt(encrypted: encryptedKey!, privateKey: privateKey, algorithm: algorithm)
            return true
        } catch{
            return false
        }
    }
    
    static func deleteToken(keyAlias: String) throws {
        managedContext.delete(try readToken(keyAlias: keyAlias))
        save()
    }
    
    static func deleteAllData(_ entity:String) throws {
        let results = getTokens()
        
        for object in results {
            guard let objectData = object as? NSManagedObject else {continue}
            managedContext.delete(objectData)
        }
        save()
    }
    
    // Increase the transaction counter of a banking token persistently.
    static func incTransactionCounter(token : BankingToken) throws {
        token.transactionCounter = token.transactionCounter + 1
        token.lastUsed = Date()
        
        save()
    }

    
    static func save() {
        try! managedContext.save()
    }
}
