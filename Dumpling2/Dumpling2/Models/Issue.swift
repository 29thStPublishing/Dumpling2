//
//  Issue.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
//import Realm

//Issue object
public class Issue: RLMObject {
    dynamic public var globalId = ""
    dynamic var appleId = ""
    dynamic public var title = ""
    dynamic public var issueDesc = "" //description
    dynamic public var assetFolder = ""
    dynamic public var coverImageId = "" //globalId of asset
    dynamic public var iconImageURL = ""
    dynamic public var publishedDate = NSDate()
    dynamic public var lastUpdateDate = ""
    dynamic public var displayDate = ""
    dynamic public var metadata = ""
    //dynamic var magazine = Magazine()
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    //Get details for a specific key from custom meta of an issue
    public func getValue(key: NSString) -> AnyObject? {
        
        var metadata: AnyObject? = Helper.jsonFromString(self.metadata)
        if let metadataDict = metadata as? NSDictionary {
            return metadataDict.valueForKey(key)
        }
        
        return nil
    }
    
    
    // MARK: Public methods
    
    //Delete an issue
    public class func deleteIssue(appleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "appleId = '%@'", appleId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        //Delete all assets and articles for the issue
        if issues.count == 1 {
            //older issue
            var currentIssue = issues.firstObject() as Issue
            //Delete all articles and assets if the issue already exists
            Article.deleteArticlesFor(currentIssue.globalId)
            
            //Delete issue
            realm.beginWriteTransaction()
            realm.deleteObjects(currentIssue)
            realm.commitWriteTransaction()
        }
    }
    
    public class func getNewestIssue() -> Issue? {
        let realm = RLMRealm.defaultRealm()
        
        //TODO: Check why arraySortedByProperty doesnt work
        //var results = Issue.allObjects().arraySortedByProperty("publishedDate", ascending: true)
        return nil
    }
}
