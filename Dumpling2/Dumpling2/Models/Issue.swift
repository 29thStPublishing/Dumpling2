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
    
    // MARK: Public methods
    
    //MARK: Class methods
    
    //Delete an issue
    public class func deleteIssue(appleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "appleId = %@", appleId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        //Delete all assets and articles for the issue
        if issues.count == 1 {
            //older issue
            var currentIssue = issues.firstObject() as Issue
            //Delete all articles and assets if the issue already exists
            Asset.deleteAssetsForIssue(currentIssue.globalId)
            Article.deleteArticlesFor(currentIssue.globalId)
            
            //Delete issue
            realm.beginWriteTransaction()
            realm.deleteObjects(currentIssue)
            realm.commitWriteTransaction()
        }
    }
    
    //Find most recent issue
    public class func getNewestIssue() -> Issue? {
        let realm = RLMRealm.defaultRealm()
        
        var results = Issue.allObjects().sortedResultsUsingProperty("publishedDate", ascending: false)
        
        if results.count > 0 {
            var newestIssue = results.firstObject() as Issue
            return newestIssue
        }
        
        return nil
    }
    
    //Get the issue for a specific Apple id
    public class func getIssueFor(appleId: String) -> Issue? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "appleId = %@", appleId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }
    
    //MARK: Instance methods
    
    //Save an Issue to the database
    public func saveIssue() {
        let realm = RLMRealm.defaultRealm()
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(self)
        realm.commitWriteTransaction()
    }
    
    //Get details for a specific key from custom meta of an issue
    public func getValue(key: NSString) -> AnyObject? {
        
        var metadata: AnyObject? = Helper.jsonFromString(self.metadata)
        if let metadataDict = metadata as? NSDictionary {
            return metadataDict.valueForKey(key)
        }
        
        return nil
    }
    
    //Find issue before a given issue
    public func getOlderIssues() -> Array<Issue>? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "publishedDate < %@", self.publishedDate)
        var issues: RLMResults = Issue.objectsWithPredicate(predicate) as RLMResults
        
        if issues.count > 0 {
            var array = Array<Issue>()
            for object in issues {
                let obj: Issue = object as Issue
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    //Find issue newer than a given issue
    public func getNewerIssues() -> Array<Issue>? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "publishedDate > %@", self.publishedDate)
        var issues: RLMResults = Issue.objectsWithPredicate(predicate) as RLMResults
        
        if issues.count > 0 {
            var array = Array<Issue>()
            for object in issues {
                let obj: Issue = object as Issue
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
}
