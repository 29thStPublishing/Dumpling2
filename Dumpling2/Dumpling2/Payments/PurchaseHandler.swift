//
//  PurchaseHandler.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 10/06/15.
//  Copyright (c) 2015 29th Street. All rights reserved.
//

import Foundation

/** Class handling purchases */
public class PurchaseHandler: NSObject {
    
    var defaultFolder: NSString!
    
    // MARK: Initializers
    
    /**
    Initializes the PurchaseHandler with the given folder. This is where the database and assets will be saved. The method expects to find a key `ClientKey` in the project's Info.plist with your client key. If none is found, the method returns a nil
    
    - parameter folder: The folder where the database is
    */
    public init?(folder: NSString){
        super.init()
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
        let mainBundle = NSBundle.mainBundle()
        if let key: String = mainBundle.objectForInfoDictionaryKey("ClientKey") as? String {
            clientKey = key
        }
        else {
            return nil
        }
    }
    
    /**
    Initializes the PurchaseHandler with the Documents directory. This is where the database should be
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(clientkey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        self.defaultFolder = "/Documents" //docsDir
        clientKey = clientKey as String
        
        let defaultRealmPath = "\(docsDir)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
    }
    
    /**
    Initializes the PurchaseHandler with a custom directory. This is where the database is. The API key is used for making calls to the Magnet API
    
    - parameter folder: The folder where the database is
    
    - parameter clientkey: Client API key to be used for making calls to the Magnet API
    */
    public init(folder: NSString, clientkey: NSString) {
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        
        if folder.hasPrefix(docsDir as String) {
            //Documents directory path - just save the /Documents... in defaultFolder
            let folderPath = folder.stringByReplacingOccurrencesOfString(docsDir as String, withString: "/Documents")
            self.defaultFolder = folderPath
        }
        else {
            self.defaultFolder = folder
        }
        clientKey = clientkey as String
        
        let defaultRealmPath = "\(folder)/default.realm"
        let realmConfiguration = RLMRealmConfiguration.defaultConfiguration()
        realmConfiguration.path = defaultRealmPath
        RLMRealmConfiguration.setDefaultConfiguration(realmConfiguration)
        //RLMRealm.setDefaultRealmPath(defaultRealmPath)
        
    }
    
    /**
    This method adds a purchase to the database
    
    - parameter purchase: The Purchase object
    */
    public func addPurchase(purchase: Purchase) {
        
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(purchase)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error adding purchase: \(error)")
        }
    }
    
    /**
    The method returns an array of purchases made on this device - for a specific user or all purchases
    
    - parameter userId: The user identity for which purchases are to be retrieved. Pass nil for returning all purchases
    */
    public func getPurchases(userId: String?) -> Array<Purchase>? {
        _ = RLMRealm.defaultRealm()
        
        var purchases: RLMResults
        
        if let identity = userId {
            let predicate = NSPredicate(format: "userIdentity = %@", identity)
            purchases = Purchase.objectsWithPredicate(predicate) as RLMResults
        }
        else {
            purchases = Purchase.allObjects() as RLMResults
        }
        
        if purchases.count > 0 {
            var array = Array<Purchase>()
            for object in purchases {
                let obj: Purchase = object as! Purchase
                array.append(obj)
            }
            
            return array
        }
        
        return nil
        
    }
    
    /**
    This method accepts a Purchase's key and value for purchase search. It retrieves all purchases which meet these conditions and returns them in an array.
    
    The key and value are needed. userId is optional
    
    - parameter key: The key whose values need to be searched. Please ensure this has the same name as the properties available
    
    - parameter value: The value of the key for the purchases to be retrieved
    
    - parameter userId: The user identity for which purchases are to be retrieved. Pass nil for ignoring this
    
    :return: an array of purchases fulfiling the conditions
    */
    public class func getPurchasesFor(key: String, value: String, userId: String?) -> Array<Purchase>? {
        _ = RLMRealm.defaultRealm()
        
        var subPredicates = Array<NSPredicate>()
        
        let testPurchase = Purchase()
        let properties: NSArray = testPurchase.objectSchema.properties
        
        var foundProperty = false
        for property: RLMProperty in properties as! [RLMProperty] {
            let propertyName = property.name
            if propertyName == key {
                //This is the property we are looking for
                foundProperty = true
                break
            }
        }
        
        if foundProperty {
            //This is a property
            let keyPredicate = NSPredicate(format: "%K = %@", key, value)
            subPredicates.append(keyPredicate)
        }
        else {
            //Could not find the key. Return nil
            return nil
        }
        
        if !Helper.isNilOrEmpty(userId) {
            let userPredicate = NSPredicate(format: "userIdentity = %@", userId!)
            subPredicates.append(userPredicate)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            var purchases: RLMResults
            
            purchases = Purchase.objectsWithPredicate(searchPredicate) as RLMResults
            
            if purchases.count > 0 {
                var array = Array<Purchase>()
                for object in purchases {
                    let obj: Purchase = object as! Purchase
                    array.append(obj)
                }
                return array
            }
        }
        
        return nil
    }
    
    /**
    This method accepts a purchase object and returns the associated article, issue or volume object
    
    - parameter purchase: The Purchase object
    
    :return: corresponding volume, issue or article object or nil if none found
    */
    public class func getPurchase(purchase: Purchase) -> AnyObject? {
        _ = RLMRealm.defaultRealm()
        
        let globalId = purchase.globalId
        let type = purchase.type
        
        switch type {
        case "volume":
            let vol = Volume.getVolume(globalId)
            return vol
            
        case "issue":
            let issue = Issue.getIssue(globalId)
            return issue
            
        case "article":
            let article = Article.getArticle(globalId, appleId: nil)
            return article
            
        default:
            return nil
        }
    }
}