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
    dynamic public var appleId = ""
    /// Title of the issue
    dynamic public var title = ""
    /// Description of the issue
    dynamic public var issueDesc = "" //description
    /// Folder saving all the assets for the issue
    dynamic public var assetFolder = ""
    /// Global id of the asset which is the cover image of the issue
    dynamic public var coverImageId = "" //globalId of asset - for phone
    /// Global id of the asset for cover image on iPad
    dynamic public var coverImageiPadId = ""
    /// Global id of the asset for cover image on iPad Landscape
    dynamic public var coverImageiPadLndId = ""
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
    dynamic public var volumeId = ""
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    //Required for backward compatibility when upgrading to V 0.96.2
    override public class func requiredProperties() -> Array<String> {
        return ["globalId", "appleId", "title", "issueDesc", "assetFolder", "coverImageId", "coverImageiPadId", "coverImageiPadLndId", "iconImageURL", "publishedDate", "lastUpdateDate", "displayDate", "metadata", "volumeId"]
    }
    
    // MARK: Private methods

    // Delete all issues for a volume - this will delete the issues, their assets, articles and article assets
    class func deleteIssuesForVolume(volumeId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "volumeId = %@", volumeId)
        let results = Issue.objectsWithPredicate(predicate)
        
        let issueIds = NSMutableArray()
        for issue in results {
            let singleIssue = issue as! Issue
            issueIds.addObject(singleIssue.globalId)
        }
        
        Article.deleteArticlesForIssues(issueIds)
        Asset.deleteAssetsForIssues(issueIds)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error deleting issues for volume: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    // MARK: Public methods
    
    //MARK: Class methods
    
    /**
    This method uses the SKU/Apple id for an issue and deletes it from the database. All the issue's articles, assets, article assets are deleted from the database and the file system
    
    :brief: Delete an issue
    
    - parameter  appleId: The SKU/Apple id for the issue
    */
    public class func deleteIssue(appleId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "appleId = %@", appleId)
        let issues = Issue.objectsWithPredicate(predicate)
        
        //Delete all assets and articles for the issue
        if issues.count == 1 {
            //older issue
            let currentIssue = issues.firstObject() as! Issue
            //Delete all articles and assets if the issue already exists
            Asset.deleteAssetsForIssue(currentIssue.globalId)
            Article.deleteArticlesFor(currentIssue.globalId)
            
            //Delete issue
            realm.beginWriteTransaction()
            realm.deleteObjects(currentIssue)
            do {
                try realm.commitWriteTransaction()
            } catch let error {
                NSLog("Error deleting issue: \(error)")
            }
            //realm.commitWriteTransaction()
        }
    }
    
    /**
    This method returns the Issue object for the most recent issue in the database (sorted by publish date)
    
    :brief: Find most recent issue
    
    :return:  Object for most recent issue
    */
    public class func getNewestIssue() -> Issue? {
        _ = RLMRealm.defaultRealm()
        
        let results = Issue.allObjects().sortedResultsUsingProperty("publishedDate", ascending: false)
        
        if results.count > 0 {
            let newestIssue = results.firstObject() as! Issue
            return newestIssue
        }
        
        return nil
    }
    
    /**
    This method takes in an SKU/Apple id and returns the Issue object associated with it (or nil if not found in the database)
    
    :brief: Get the issue for a specific Apple id
    
    - parameter appleId: The SKU/Apple id to search for
    
    :return:  Issue object for the given SKU/Apple id
    */
    public class func getIssueFor(appleId: String) -> Issue? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "appleId = %@", appleId)
        let issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }
    
    /**
    This method returns all issues for a given volume or if volumeId is nil, all issues
    
    - parameter volumeId: Global id of the volume whose issues have to be retrieved
    
    :return: an array of issues for given volume or all issues if volumeId is nil
    */
    public class func getIssues(volumeId: String?) -> Array<Issue>? {
        _ = RLMRealm.defaultRealm()

        var issues: RLMResults
        if let volId = volumeId {
            let predicate = NSPredicate(format: "volumeId = %@", volId)
            issues = Issue.objectsWithPredicate(predicate)
        }
        else {
            issues = Issue.allObjects()
        }
        
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
    This method inputs the global id of an issue and returns the Issue object
    
    - parameter  issueId: The global id for the issue
    
    :return: issue object for the global id. Returns nil if the issue is not found
    */
    public class func getIssue(issueId: String) -> Issue? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "globalId = %@", issueId)
        let issues = Issue.objectsWithPredicate(predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        return nil
    }
    
    //MARK: Instance methods
    
    /**
    This method downloads articles for the issue
    */
    public func downloadIssueArticles() {
        lLog("Download issues articles for \(self.globalId)")
        var assetFolder = self.assetFolder
        if assetFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            assetFolder = docsDir as String
        }
        else {
            assetFolder = assetFolder.stringByReplacingOccurrencesOfString("/\(self.appleId)", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        }
        let issueHandler = IssueHandler(folder: assetFolder)!
        
        let requestURL = "\(baseURL)issues/\(self.globalId)"
        
        issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: self.globalId)
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //Download articles for the issue
                    let articles = issueDetails.objectForKey("articles") as! NSArray
                    if articles.count > 0 {
                        var articleList = ""
                        for (index, articleDict) in articles.enumerate() {
                            //Insert article
                            //Add article and its assets to Issue dictionary
                            let articleId = articleDict.valueForKey("id") as! String
                            articleList += articleId
                            if index < (articles.count - 1) {
                                articleList += ","
                            }
                            issueHandler.updateStatusDictionary(self.volumeId, issueId: self.globalId, url: "\(baseURL)articles/\(articleId)", status: 0)
                            //Article.createArticleForId(articleId, issue: self, placement: index+1, delegate: issueHandler)
                        }
                        //Send request to get all articles info in 1 call
                        Article.createArticlesForIds(articleList, issue: self, delegate: issueHandler)
                    }
                    
                    issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: requestURL, status: 1)
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: requestURL, status: 2)
            }
        }
    }
    
    /**
    This method downloads assets for the issue (only issue assets, not article assets)
    */
    public func downloadIssueAssets() {
        lLog("Download issues assets for \(self.globalId)")
        var assetFolder = self.assetFolder
        if assetFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            assetFolder = docsDir as String
        }
        else {
            assetFolder = assetFolder.stringByReplacingOccurrencesOfString("/\(self.appleId)", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        }
        let issueHandler = IssueHandler(folder: assetFolder)!
        
        let requestURL = "\(baseURL)issues/\(self.globalId)"
        
        //issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: requestURL, status: 0)
        issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: self.globalId)
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //Download assets for the issue
                    let issueMedia = issueDetails.objectForKey("media") as! NSArray
                    if issueMedia.count > 0 {
                        var assetList = ""
                        for (index, assetDict) in issueMedia.enumerate() {
                            let assetid = assetDict.valueForKey("id") as! String
                            assetList += assetid
                            if index < (issueMedia.count - 1) {
                                assetList += ","
                            }
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        Asset.downloadAndCreateAssetsForIds(assetList, issue: self, articleId: "", delegate: issueHandler)
                    }
                    
                    issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)issues/\(self.globalId)", status: 1)
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)issues/\(self.globalId)", status: 2)
            }
        }
    }
    
    /**
     This method downloads assets for the issue and its articles
     */
    public func downloadAllAssets() {
        lLog("Download all assets for \(self.globalId)")
        var assetFolder = self.assetFolder
        if assetFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            assetFolder = docsDir as String
        }
        else {
            assetFolder = assetFolder.stringByReplacingOccurrencesOfString("/\(self.appleId)", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        }
        let issueHandler = IssueHandler(folder: assetFolder)!
        
        let requestURL = "\(baseURL)issues/\(self.globalId)"
        
        //issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: requestURL, status: 0)
        issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: self.globalId)
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.valueForKey("issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //Download assets for the issue
                    let issueMedia = issueDetails.objectForKey("media") as! NSArray
                    if issueMedia.count > 0 {
                        var assetList = ""
                        for (index, assetDict) in issueMedia.enumerate() {
                            let assetid = assetDict.valueForKey("id") as! String
                            assetList += assetid
                            if index < (issueMedia.count - 1) {
                                assetList += ","
                            }
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        Asset.downloadAndCreateAssetsForIds(assetList, issue: self, articleId: "", delegate: issueHandler)
                    }
                    
                    if let articles = issueDetails.objectForKey("articles") as? NSArray {
                        for articleDict in articles {
                            let articleId = articleDict.valueForKey("id") as! String
                            
                            if let article = Article.getArticle(articleId, appleId: nil) {
                                //issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)articles/\(articleId)", status: 0)
                                article.downloadArticleAssets(issueHandler)
                            }
                        }
                    }
                    issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)issues/\(self.globalId)", status: 1)
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)issues/\(self.globalId)", status: 2)
            }
        }
    }
    
    /**
    This method saves an issue back to the database
    
    :brief: Save an Issue to the database
    */
    public func saveIssue() {
        let realm = RLMRealm.defaultRealm()
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(self)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving issue: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
    This method returns the value for a specific key from the custom metadata of the issue
    
    :brief: Get value for a specific key from custom meta of an issue
    
    :return: an object for the key from the custom metadata (or nil)
    */
    public func getValue(key: NSString) -> AnyObject? {
        
        let metadata: AnyObject? = Helper.jsonFromString(self.metadata)
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
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "publishedDate < %@", self.publishedDate)
        let issues: RLMResults = Issue.objectsWithPredicate(predicate) as RLMResults
        
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
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "publishedDate > %@", self.publishedDate)
        let issues: RLMResults = Issue.objectsWithPredicate(predicate) as RLMResults
        
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
