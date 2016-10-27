//
//  Issue.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit

/** A model object for Issue */
open class Issue: RLMObject {
    /// Global id of an issue - this is unique for each issue
    dynamic open var globalId = ""
    /// SKU or Apple Id for an issue
    dynamic open var appleId = ""
    /// Title of the issue
    dynamic open var title = ""
    /// Description of the issue
    dynamic open var issueDesc = "" //description
    /// Folder saving all the assets for the issue
    dynamic open var assetFolder = ""
    /// Global id of the asset which is the cover image of the issue
    dynamic open var coverImageId = "" //globalId of asset - for phone
    /// Global id of the asset for cover image on iPad
    dynamic open var coverImageiPadId = ""
    /// Global id of the asset for cover image on iPad Landscape
    dynamic open var coverImageiPadLndId = ""
    /// File URL for the icon image
    dynamic open var iconImageURL = ""
    /// Published date for the issue
    dynamic open var publishedDate = Date()
    /// Last updated date for the issue
    dynamic open var lastUpdateDate = ""
    /// Display date for an issue
    dynamic open var displayDate = ""
    /// Custom metadata of the issue
    dynamic open var metadata = ""
    ///Global id of the volume to which the issue belongs (can be blank if this is an independent issue)
    dynamic open var volumeId = ""
    
    override open class func primaryKey() -> String {
        return "globalId"
    }
    
    //Required for backward compatibility when upgrading to V 0.96.2
    override open class func requiredProperties() -> Array<String> {
        return ["globalId", "appleId", "title", "issueDesc", "assetFolder", "coverImageId", "coverImageiPadId", "coverImageiPadLndId", "iconImageURL", "publishedDate", "lastUpdateDate", "displayDate", "metadata", "volumeId"]
    }
    
    // MARK: Private methods

    // Delete all issues for a volume - this will delete the issues, their assets, articles and article assets
    class func deleteIssuesForVolume(_ volumeId: String) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "volumeId = %@", volumeId)
        let results = Issue.objects(with: predicate)
        
        var issueIds = [String]()
        for issue in results {
            let singleIssue = issue as! Issue
            issueIds.append(singleIssue.globalId)
        }
        
        Article.deleteArticlesForIssues(issueIds)
        Asset.deleteAssetsForIssues(issueIds)
        
        realm.beginWriteTransaction()
        realm.deleteObjects(results)
        do {
            try realm.commitWriteTransaction()
            Relation.deleteRelations(issueIds, articleId: nil, assetId: nil)
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
    open class func deleteIssue(_ appleId: NSString) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "appleId = %@", appleId)
        let issues = Issue.objects(with: predicate)
        
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
                Relation.deleteRelations([currentIssue.globalId], articleId: nil, assetId: nil)
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
    open class func getNewestIssue() -> Issue? {
        _ = RLMRealm.default()
        
        let results = Issue.allObjects().sortedResults(usingProperty: "publishedDate", ascending: false)
        
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
    open class func getIssueFor(_ appleId: String) -> Issue? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "appleId = %@", appleId)
        let issues = Issue.objects(with: predicate)
        
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
    open class func getIssues(_ volumeId: String?) -> Array<Issue>? {
        _ = RLMRealm.default()

        var issues: RLMResults<RLMObject>
        if let volId = volumeId {
            let predicate = NSPredicate(format: "volumeId = %@", volId)
            issues = Issue.objects(with: predicate)
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
    open class func getIssue(_ issueId: String) -> Issue? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "globalId = %@", issueId)
        let issues = Issue.objects(with: predicate)
        
        if issues.count > 0 {
            return issues.firstObject() as? Issue
        }
        
        if issueId.isEmpty {
            let issue = Issue()
            issue.assetFolder = "/Documents"
            return issue
        }
        
        return nil
    }
    
    //MARK: Instance methods
    
    open func downloadIssueArticles() {
        self.downloadIssueArticles(nil)
    }
    /**
    This method downloads articles for the issue
    */
    open func downloadIssueArticles(_ timestamp: String?) {
        lLog("Download issues articles for \(self.globalId)")
        var assetFolder = self.assetFolder
        if assetFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            assetFolder = docsDir as String
        }
        else {
            assetFolder = assetFolder.replacingOccurrences(of: "/\(self.appleId)", with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
        }
        let issueHandler = IssueHandler(folder: assetFolder as NSString)!
        
        var requestURL = "\(baseURL)issues/\(self.globalId)"
        if let time = timestamp {
            requestURL += "/since/\(time)"
        }
        
        issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: self.globalId as NSCopying)
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:Any?, error:Error?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //NSLog("ISSUE DETAILS: \(issueDetails)")
                    //Download articles for the issue
                    let articles = issueDetails.object(forKey: "articles") as! NSArray
                    if articles.count > 0 {
                        var articleList = ""
                        for (index, articleDict) in articles.enumerated() {
                            let articleDictionary = articleDict as! NSDictionary
                            //Insert article
                            //Add article and its assets to Issue dictionary
                            let articleId = articleDictionary.value(forKey: "id") as! String
                            Relation.createRelation(self.globalId, articleId: articleId, assetId: nil, placement: index + 1)
                            if let existingArticle = Article.getArticle(articleId, appleId: nil) {
                                var lastUpdatedDate = Date()
                                if let updateDate: String = existingArticle.getValue("updateDate") as? String {
                                    lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                                }
                                var newUpdateDate = Date()
                                if let updated = articleDictionary.value(forKey: "updated") as? NSDictionary {
                                    if let date = updated.value(forKey: "date") as? String {
                                        newUpdateDate = Helper.publishedDateFromISO(date)
                                    }
                                }
                                if newUpdateDate.compare(lastUpdatedDate) != ComparisonResult.orderedDescending {
                                    existingArticle.downloadArticleAssets(issueHandler)
                                }
                            }
                            articleList += articleId
                            if index < (articles.count - 1) {
                                articleList += ","
                            }
                            issueHandler.updateStatusDictionary(self.volumeId, issueId: self.globalId, url: "\(baseURL)articles/\(articleId)", status: 0)
                        }
                        //Send request to get all articles info in 1 call
                        if articleList.hasSuffix(",") {
                            articleList = articleList.substring(to: articleList.characters.index(before: articleList.endIndex))
                        }
                        if !articleList.isEmpty {
                            Article.createArticlesForIds(articleList, issue: self, delegate: issueHandler)
                        }
                    }
                    
                    issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: requestURL, status: 1)
                }
            }
            else if let err = error {
                print("Error: " + err.localizedDescription)
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: requestURL, status: 2)
            }
        }
    }
    
    /**
    This method downloads assets for the issue (only issue assets, not article assets)
    */
    open func downloadIssueAssets() {
        lLog("Download issues assets for \(self.globalId)")
        var assetFolder = self.assetFolder
        if assetFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            assetFolder = docsDir as String
        }
        else {
            assetFolder = assetFolder.replacingOccurrences(of: "/\(self.appleId)", with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
        }
        let issueHandler = IssueHandler(folder: assetFolder as NSString)!
        
        let requestURL = "\(baseURL)issues/\(self.globalId)"
        
        issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: self.globalId as NSCopying)
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:Any?, error:Error?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //Download assets for the issue
                    let issueMedia = issueDetails.object(forKey: "media") as! NSArray
                    if issueMedia.count > 0 {
                        var assetList = ""
                        var assetArray = [String]()
                        
                        for (index, assetDict) in issueMedia.enumerated() {
                            let assetDictionary = assetDict as! NSDictionary
                            
                            let assetid = assetDictionary.value(forKey: "id") as! String
                            Relation.createRelation(self.globalId, articleId: nil, assetId: assetid, placement: index + 1)
                            assetList += assetid
                            if index < (issueMedia.count - 1) {
                                assetList += ","
                            }
                            assetArray.append(assetid)
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        var deleteAssets = [String]()
                        if let assets = Asset.getAssetsFor(self.globalId, articleId: "", volumeId: nil, type: nil) {
                            for asset in assets {
                                if let _ = assetArray.index(of: asset.globalId) {}
                                else {
                                    deleteAssets.append(asset.globalId)
                                }
                            }
                        }
                        if deleteAssets.count > 0 {
                            Asset.deleteAssets(deleteAssets)
                        }
                        
                        Asset.downloadAndCreateAssetsForIds(assetList, issue: self, articleId: "", delegate: issueHandler)
                    }
                    
                    issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)issues/\(self.globalId)", status: 1)
                }
            }
            else if let err = error {
                print("Error: " + err.localizedDescription)
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)issues/\(self.globalId)", status: 2)
            }
        }
    }
    
    /**
     This method downloads assets for the issue and its articles
     */
    open func downloadAllAssets() {
        lLog("Download all assets for \(self.globalId)")
        var assetFolder = self.assetFolder
        if assetFolder.hasPrefix("/Documents") {
            var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let docsDir: NSString = docPaths[0] as NSString
            assetFolder = docsDir as String
        }
        else {
            assetFolder = assetFolder.replacingOccurrences(of: "/\(self.appleId)", with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
        }
        let issueHandler = IssueHandler(folder: assetFolder as NSString)!
        
        let requestURL = "\(baseURL)issues/\(self.globalId)"
        
        issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: self.globalId as NSCopying)
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:Any?, error:Error?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allIssues: NSArray = response.value(forKey: "issues") as! NSArray
                if let issueDetails: NSDictionary = allIssues.firstObject as? NSDictionary {
                    //Download assets for the issue
                    let issueMedia = issueDetails.object(forKey: "media") as! NSArray
                    if issueMedia.count > 0 {
                        var assetList = ""
                        var assetArray = [String]()
                        for (index, assetDict) in issueMedia.enumerated() {
                            let assetDictionary = assetDict as! NSDictionary
                            
                            let assetid = assetDictionary.value(forKey: "id") as! String
                            Relation.createRelation(self.globalId, articleId: nil, assetId: assetid, placement: index + 1)
                            assetList += assetid
                            if index < (issueMedia.count - 1) {
                                assetList += ","
                            }
                            assetArray.append(assetid)
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        var deleteAssets = [String]()
                        if let assets = Asset.getAssetsFor(self.globalId, articleId: "", volumeId: nil, type: nil) {
                            for asset in assets {
                                if let _ = assetArray.index(of: asset.globalId) {}
                                else {
                                    deleteAssets.append(asset.globalId)
                                }
                            }
                        }
                        if deleteAssets.count > 0 {
                            Asset.deleteAssets(deleteAssets)
                        }
                        Asset.downloadAndCreateAssetsForIds(assetList, issue: self, articleId: "", delegate: issueHandler)
                    }
                    
                    if let articles = issueDetails.object(forKey: "articles") as? NSArray {
                        for articleDict in articles {
                            let articleId = (articleDict as! NSDictionary).value(forKey: "id") as! String
                            
                            if let article = Article.getArticle(articleId, appleId: nil) {
                                article.downloadArticleAssets(issueHandler)
                            }
                        }
                    }
                    issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)issues/\(self.globalId)", status: 1)
                }
            }
            else if let err = error {
                print("Error: " + err.localizedDescription)
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)issues/\(self.globalId)", status: 2)
            }
        }
    }
    
    /**
    This method saves an issue back to the database
    
    :brief: Save an Issue to the database
    */
    open func saveIssue() {
        let realm = RLMRealm.default()
        
        realm.beginWriteTransaction()
        realm.addOrUpdate(self)
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
    open func getValue(_ key: NSString) -> AnyObject? {
        
        let metadata: AnyObject? = Helper.jsonFromString(self.metadata)
        if let metadataDict = metadata as? NSDictionary {
            return metadataDict.value(forKey: key as String) as AnyObject?
        }
        
        return nil
    }
    
    /**
    This method returns all issues whose publish date is older than the published date of current issue
    
    :brief: Get all issues older than a specific issue
    
    :return: an array of issues older than the current issue
    */
    open func getOlderIssues() -> Array<Issue>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "publishedDate < %@", self.publishedDate as CVarArg)
        let issues: RLMResults = Issue.objects(with: predicate) as RLMResults
        
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
    open func getNewerIssues() -> Array<Issue>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "publishedDate > %@", self.publishedDate as CVarArg)
        let issues: RLMResults = Issue.objects(with: predicate) as RLMResults
        
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
