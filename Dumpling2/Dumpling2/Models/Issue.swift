//
//  Issue.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit

/** A model object for Issue */
public class Issue: RLMObject {
    /// Global id of an issue - this is unique for each issue
    dynamic public var globalId = ""
    /// SKU or Apple Id for an issue
    dynamic var appleId = ""
    /// Title of the issue
    dynamic public var title = ""
    /// Description of the issue
    dynamic public var issueDesc = "" //description
    /// Folder saving all the assets for the issue
    dynamic public var assetFolder = ""
    /// Global id of the asset which is the cover image of the issue
    dynamic public var coverImageId = "" //globalId of asset
    /// File URL for the icon image
    dynamic public var iconImageURL = ""
    /// Published date for the issue
    dynamic public var publishedDate = NSDate()
    /// Last updated date for the issue
    dynamic public var lastUpdateDate = ""
    /// Display date for an issue
    dynamic public var displayDate = ""
    /// Custom metadata of the issue
    dynamic public var metadata = ""
    ///Global id of the volume to which the issue belongs (can be blank if this is an independent issue)
    dynamic var volumeId = ""
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    // MARK: Private methods

    // Delete all issues for a volume - this will delete the issues, their assets, articles and article assets
    class func deleteIssuesForVolume(volumeId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "volumeId = %@", volumeId)
        var results = Issue.objectsWithPredicate(predicate)
        
        var issueIds = NSMutableArray()
        for issue in results {
            let singleIssue = issue as! Issue
            issueIds.addObject(singleIssue.globalId)
        }
        
        Article.deleteArticlesForIssues(issueIds)
        Asset.deleteAssetsForIssues(issueIds)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        realm.commitWriteTransaction()
    }
    
    // MARK: Public methods
    
    //MARK: Class methods
    
    /**
    This method uses the SKU/Apple id for an issue and deletes it from the database. All the issue's articles, assets, article assets are deleted from the database and the file system
    
    :brief: Delete an issue
    
    :param:  appleId The SKU/Apple id for the issue
    */
    public class func deleteIssue(appleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "appleId = %@", appleId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        //Delete all assets and articles for the issue
        if issues.count == 1 {
            //older issue
            var currentIssue = issues.firstObject() as! Issue
            //Delete all articles and assets if the issue already exists
            Asset.deleteAssetsForIssue(currentIssue.globalId)
            Article.deleteArticlesFor(currentIssue.globalId)
            
            //Delete issue
            realm.beginWriteTransaction()
            realm.deleteObjects(currentIssue)
            realm.commitWriteTransaction()
        }
    }
    
    /**
    This method returns the Issue object for the most recent issue in the database (sorted by publish date)
    
    :brief: Find most recent issue
    
    :return:  Object for most recent issue
    */
    public class func getNewestIssue() -> Issue? {
        let realm = RLMRealm.defaultRealm()
        
        var results = Issue.allObjects().sortedResultsUsingProperty("publishedDate", ascending: false)
        
        if results.count > 0 {
            var newestIssue = results.firstObject() as! Issue
            return newestIssue
        }
        
        return nil
    }
    
    /**
    This method takes in an SKU/Apple id and returns the Issue object associated with it (or nil if not found in the database)
    
    :brief: Get the issue for a specific Apple id
    
    :param: appleId The SKU/Apple id to search for
    
    :return:  Issue object for the given SKU/Apple id
    */
    public class func getIssueFor(appleId: String) -> Issue? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "appleId = %@", appleId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }
    
    /**
    This method returns all issues for a given volume
    
    :param: volumeId Global id of the volume whose issues have to be retrieved
    
    :return: an array of issues for given volume
    */
    public func getIssuesForVolume(volumeId: String) -> Array<Issue>? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "volumeId = %@", volumeId)
        var issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            var array = Array<Issue>()
            for object in issues {
                let obj: Issue = object as! Issue
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method returns all issues
    
    :return: an array of issues
    */
    public func getIssues() -> Array<Issue>? {
        let realm = RLMRealm.defaultRealm()
        
        var issues: RLMResults = Issue.allObjects()
        
        if issues.count > 0 {
            var array = Array<Issue>()
            for object in issues {
                let obj: Issue = object as! Issue
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    //MARK: Instance methods
    
    /**
    This method saves an issue back to the database
    
    :brief: Save an Issue to the database
    */
    public func saveIssue() {
        let realm = RLMRealm.defaultRealm()
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(self)
        realm.commitWriteTransaction()
    }
    
    /**
    This method returns the value for a specific key from the custom metadata of the issue
    
    :brief: Get value for a specific key from custom meta of an issue
    
    :return: an object for the key from the custom metadata (or nil)
    */
    public func getValue(key: NSString) -> AnyObject? {
        
        var metadata: AnyObject? = Helper.jsonFromString(self.metadata)
        if let metadataDict = metadata as? NSDictionary {
            return metadataDict.valueForKey(key as String)
        }
        
        return nil
    }
    
    /**
    This method returns all issues whose publish date is older than the published date of current issue
    
    :brief: Get all issues older than a specific issue
    
    :return: an array of issues older than the current issue
    */
    public func getOlderIssues() -> Array<Issue>? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "publishedDate < %@", self.publishedDate)
        var issues: RLMResults = Issue.objectsWithPredicate(predicate) as RLMResults
        
        if issues.count > 0 {
            var array = Array<Issue>()
            for object in issues {
                let obj: Issue = object as! Issue
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method returns all issues whose publish date is newer than the published date of current issue
    
    :brief: Get all issues newer than a specific issue

    :return: an array of issues newer than the current issue
    */
    public func getNewerIssues() -> Array<Issue>? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "publishedDate > %@", self.publishedDate)
        var issues: RLMResults = Issue.objectsWithPredicate(predicate) as RLMResults
        
        if issues.count > 0 {
            var array = Array<Issue>()
            for object in issues {
                let obj: Issue = object as! Issue
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
}
