//
//  Article.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit

var assetPattern: String = "<!-- \\[ASSET: .+\\] -->"
var assetPatternParts: [String] = ["<!-- [ASSET: ", "] -->"]

/** A model object for Articles */
public class Article: RLMObject {
    /// Global id of an article - this is unique for each article
    dynamic public var globalId = ""
    /// Article title
    dynamic public var title = ""
    /// Article description
    dynamic public var articleDesc = "" //description
    dynamic public var slug = ""
    dynamic public var dek = ""
    /// Article content
    dynamic public var body = ""
    /// Permanent link to the article
    dynamic public var permalink = "" //keeping URLs as string - we might need to append parts to get the final
    /// Article URL
    dynamic public var url = ""
    /// URL to the article's source
    dynamic public var sourceURL = ""
    /// Article author's name
    dynamic public var authorName = ""
    /// Link to the article author's profile
    dynamic public var authorURL = ""
    /// Article author's bio
    dynamic public var authorBio = ""
    /// Section under which the article falls
    dynamic public var section = ""
    /// Type of article
    dynamic public var articleType = ""
    /// Keywords which the article falls under
    dynamic public var keywords = ""
    /// Article commentary
    dynamic public var commentary = ""
    /// Article published date
    dynamic public var date = NSDate()
    /// Article metadata
    dynamic public var metadata = ""
    dynamic public var versionStashed = ""
    /// Placement of the article in an issue
    dynamic public var placement = 0
    /// URL for the article's feature image
    dynamic public var mainImageURL = ""
    /// URL for the article's thumbnail image
    dynamic public var thumbImageURL = ""
    /// Status of article (published or not)
    dynamic public var isPublished = false
    /// Whether the article is featured for the given issue or not
    dynamic public var isFeatured = false
    /// Global id for the issue the article belongs to. This can be blank for independent articles
    dynamic public var issueId = ""
    ///SKU/Apple id for the article - will be used when articles are sold individually
    dynamic public var appleId = ""
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    //Required for backward compatibility when upgrading to V 0.96.2
    override public class func requiredProperties() -> Array<String> {
        return ["globalId", "title", "articleDesc", "slug", "dek", "body", "permalink", "url", "sourceURL", "authorName", "authorURL", "authorBio", "section", "articleType", "keywords", "commentary", "date", "metadata", "versionStashed", "placement", "mainImageURL", "thumbImageURL", "isPublished", "isFeatured", "issueId", "appleId"]
    }
    
    //Add article
    class func createArticle(article: NSDictionary, issue: Issue, placement: Int) {
        let realm = RLMRealm.defaultRealm()
        
        let currentArticle = Article()
        currentArticle.globalId = article.objectForKey("global_id") as! String
        currentArticle.title = article.objectForKey("title") as! String
        currentArticle.body = article.objectForKey("body") as! String
        currentArticle.articleDesc = article.objectForKey("description") as! String
        currentArticle.url = article.objectForKey("url") as! String
        currentArticle.section = article.objectForKey("section") as! String
        currentArticle.authorName = article.objectForKey("author_name") as! String
        currentArticle.sourceURL = article.objectForKey("source") as! String
        currentArticle.dek = article.objectForKey("dek") as! String
        currentArticle.authorURL = article.objectForKey("author_url") as! String
        currentArticle.authorBio = article.objectForKey("author_bio") as! String
        currentArticle.keywords = article.objectForKey("keywords") as! String
        currentArticle.commentary = article.objectForKey("commentary") as! String
        currentArticle.articleType = article.objectForKey("type") as! String
        
        let updateDate = article.objectForKey("date_last_updated") as! String
        if updateDate != "" {
            currentArticle.date = Helper.publishedDateFromISO(updateDate)
        }
        
        if let sku = article.objectForKey("sku") as? String {
            currentArticle.appleId = sku
        }
        
        let meta = article.valueForKey("meta") as! NSDictionary
        if let published = meta.valueForKey("published") as? NSNumber {
            currentArticle.isPublished = published.boolValue
        }
        
        let metadata: AnyObject! = article.objectForKey("customMeta")
        if metadata.isKindOfClass(NSDictionary) {
            currentArticle.metadata = Helper.stringFromJSON(metadata)! //metadata.JSONString()!
        }
        else {
            currentArticle.metadata = metadata as! String
        }
        
        currentArticle.issueId = issue.globalId
        currentArticle.placement = placement
        let bundleVersion: AnyObject? = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String)
        currentArticle.versionStashed = bundleVersion as! String
        
        //Featured or not
        if let featuredDict = article.objectForKey("featured") as? NSDictionary {
            //If the key doesn't exist, the article is not featured (default value)
            if featuredDict.objectForKey(issue.globalId)?.integerValue == 1 {
                currentArticle.isFeatured = true
            }
        }
        
        //Insert article images
        if let orderedArray = article.objectForKey("images")?.objectForKey("ordered") as? NSArray {
            if orderedArray.count > 0 {
                for (index, imageDict) in orderedArray.enumerate() {
                    Asset.createAsset(imageDict as! NSDictionary, issue: issue, articleId: currentArticle.globalId, placement: index+1)
                }
            }
        }
        
        //Set thumbnail for article
        if let firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: currentArticle.globalId, volumeId: nil) {
            currentArticle.thumbImageURL = firstAsset.globalId as String
        }
        
        //Insert article sound files
        if let orderedArray = article.objectForKey("sound_files")?.objectForKey("ordered") as? NSArray {
            if orderedArray.count > 0 {
                for (index, soundDict) in orderedArray.enumerate() {
                    Asset.createAsset(soundDict as! NSDictionary, issue: issue, articleId: currentArticle.globalId, sound: true, placement: index+1)
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(currentArticle)
        do {
            try realm.commitWriteTransaction()
            Relation.createRelation(currentArticle.issueId, articleId: currentArticle.globalId, assetId: nil)
        } catch let error {
            NSLog("Error creating article: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    //Get article details from API and create
    class func createArticleForId(articleId: NSString, issue: Issue?, placement: Int, delegate: AnyObject?) {
        
        let requestURL = "\(baseURL)articles/\(articleId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                
                addArticle(articleInfo, issue: issue, placement: placement, delegate: delegate)
            }
            else if let err = error {
                print("Error: " + err.description)
                if delegate != nil {
                    //Mark article as done - even if with errors
                    if let issue = issue {
                        (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: requestURL, status: 2)
                    }
                    else {
                        (delegate as! IssueHandler).updateStatusDictionary("", issueId: articleId as String, url: requestURL, status: 2)
                    }
                }
            }
            
        }
    }
    
    //Get details for multiple comma-separate article ids from API and create
    class func createArticlesForIds(articleIds: String, issue: Issue?, delegate: AnyObject?) {
        
        let requestURL = "\(baseURL)articles/\(articleIds)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                
                for (index, articleInfo) in allArticles.enumerate() {
                    addArticle(articleInfo as! NSDictionary, issue: issue, placement: index + 1, delegate: delegate)
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                if delegate != nil {
                    //Mark all articles from the list as done with errors
                    let arr = articleIds.characters.split(",").map { String($0) }
                    for articleId in arr {
                        if let issue = issue {
                            (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)articles/\(articleId)", status: 2)
                        }
                        else {
                            (delegate as! IssueHandler).updateStatusDictionary("", issueId: articleId, url: "\(baseURL)articles/\(articleId)", status: 2)
                        }
                    }
                }
            }
            
        }
    }
    
    //Get details for multiple comma-separate article ids from API and create
    class func createArticlesForIdsWithThumb(articleIds: String, issue: Issue?, delegate: AnyObject?) {
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)articles/\(articleIds)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                
                for (index, articleInfo) in allArticles.enumerate() {
                    let gid = articleInfo.valueForKey("id") as! String
                    let meta = articleInfo.objectForKey("meta") as! NSDictionary
                    
                    if let existingArticle = Article.getArticle(gid, appleId: nil) {
                        if let updateDate: String = existingArticle.getValue("updateDate") as? String {
                            let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                            var newUpdatedDate = NSDate()
                            if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                                if let dt: String = updated["date"] as? String {
                                    newUpdatedDate = Helper.publishedDateFromISO(dt)
                                }
                            }
                            if newUpdatedDate.compare(lastUpdatedDate) != NSComparisonResult.OrderedDescending {
                                Relation.createRelation(existingArticle.issueId, articleId: existingArticle.globalId, assetId: nil)
                                existingArticle.downloadArticleAssets(delegate as? IssueHandler)
                                if delegate != nil {
                                    //Mark article as done
                                    if let issue = issue {
                                        (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)articles/\(gid)", status: 3)
                                    }
                                    else {
                                        (delegate as! IssueHandler).updateStatusDictionary("", issueId: gid, url: "\(baseURL)articles/\(gid)", status: 3)
                                    }
                                }
                                continue // go to the next for loop iteration
                                //Don't download if already downloaded and not updated
                            }
                        }
                    }
                    let currentArticle = Article()
                    currentArticle.globalId = gid
                    currentArticle.placement = index + 1
                    if let articleIssue = issue {
                        currentArticle.issueId = articleIssue.globalId
                    }
                    else {
                        if let issue = Issue.getIssue("") {
                            currentArticle.issueId = issue.globalId
                        }
                        else {
                            let issue = Issue()
                            issue.assetFolder = "/Documents"
                            currentArticle.issueId = issue.globalId
                        }
                    }
                    currentArticle.title = articleInfo.valueForKey("title") as! String
                    currentArticle.body = articleInfo.valueForKey("body") as! String
                    currentArticle.articleDesc = articleInfo.valueForKey("description") as! String
                    currentArticle.authorName = articleInfo.valueForKey("authorName") as! String
                    currentArticle.authorURL = articleInfo.valueForKey("authorUrl") as! String
                    currentArticle.authorBio = articleInfo.valueForKey("authorBio") as! String
                    currentArticle.url = articleInfo.valueForKey("sharingUrl") as! String
                    currentArticle.section = articleInfo.valueForKey("section") as! String
                    currentArticle.articleType = articleInfo.valueForKey("type") as! String
                    currentArticle.commentary = articleInfo.valueForKey("commentary") as! String
                    currentArticle.slug = articleInfo.valueForKey("slug") as! String
                    
                    if let sku = articleInfo.valueForKey("sku") as? String {
                        currentArticle.appleId = sku
                    }
                    
                    let featured = meta.valueForKey("featured") as! NSNumber
                    currentArticle.isFeatured = featured.boolValue
                    if let published = meta.valueForKey("published") as? NSNumber {
                        currentArticle.isPublished = published.boolValue
                    }
                    
                    if let publishedDate = meta.valueForKey("publishedDate") as? String {
                        currentArticle.date = Helper.publishedDateFromISO2(publishedDate)
                    }
                    
                    if let metadata: AnyObject = articleInfo.objectForKey("customMeta") {
                        if metadata.isKindOfClass(NSDictionary) {
                            currentArticle.metadata = Helper.stringFromJSON(metadata)!
                        }
                        else {
                            currentArticle.metadata = metadata as! String
                        }
                    }
                    
                    let keywords = articleInfo.objectForKey("keywords") as! NSArray
                    if keywords.count > 0 {
                        currentArticle.keywords = Helper.stringFromJSON(keywords)!
                    }
                    
                    //Add all assets of the article (will add images and sound)
                    let articleMedia = articleInfo.objectForKey("media") as! NSArray
                    if articleMedia.count > 0 {
                        let assetDict = articleMedia.firstObject
                        let assetid = assetDict!.valueForKey("id") as! String
                        if delegate != nil {
                            if let issue = issue {
                                Relation.createRelation(issue.globalId, articleId: currentArticle.globalId, assetId: assetid)
                                (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                            }
                            else {
                                Relation.createRelation(nil, articleId: currentArticle.globalId, assetId: assetid)
                                (delegate as! IssueHandler).updateStatusDictionary("", issueId: currentArticle.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                            }
                        }
                        currentArticle.thumbImageURL = assetid as String
                        Asset.downloadAndCreateAssetsForIds(assetid, issue: Issue.getIssue(currentArticle.issueId), articleId: currentArticle.globalId, delegate: delegate)
                    }
                    
                    realm.beginWriteTransaction()
                    realm.addOrUpdateObject(currentArticle)
                    do {
                        try realm.commitWriteTransaction()
                        Relation.createRelation(currentArticle.issueId, articleId: currentArticle.globalId, assetId: nil)
                    } catch let error {
                        NSLog("Error saving issue: \(error)")
                    }
                    //realm.commitWriteTransaction()
                    
                    if delegate != nil {
                        //Mark article as done
                        if let issue = issue {
                            (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)articles/\(currentArticle.globalId)", status: 1)
                        }
                        else {
                            (delegate as! IssueHandler).updateStatusDictionary("", issueId: currentArticle.globalId, url: "\(baseURL)articles/\(currentArticle.globalId)", status: 1)
                        }
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                if delegate != nil {
                    //Mark all articles from the list as done with errors
                    let arr = articleIds.characters.split(",").map { String($0) }
                    for articleId in arr {
                        if let issue = issue {
                            (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)articles/\(articleId)", status: 2)
                        }
                        else {
                            (delegate as! IssueHandler).updateStatusDictionary("", issueId: articleId, url: "\(baseURL)articles/\(articleId)", status: 2)
                        }
                    }
                }
            }
            
        }
    }
    
    class func deleteArticlesForIssues(issues: NSArray) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId IN %@", issues)
        let articles = Article.objectsInRealm(realm, withPredicate: predicate)
        
        let articleIds = NSMutableArray()
        //go through each article and delete all assets associated with it
        for article in articles {
            let article = article as! Article
            articleIds.addObject(article.globalId)
        }

        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete articles
        realm.beginWriteTransaction()
        realm.deleteObjects(articles)
        do {
            try realm.commitWriteTransaction()
            Relation.deleteRelations(issues as? [String], articleId: nil, assetId: nil)
        } catch let error {
            NSLog("Error deleting articles for issues: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
    This method accepts an article's global id, gets its details from Magnet API and adds it to the database.
    
    :brief: Get Article from API and add to the database
    
    - parameter  articleId: The global id for the article
    
    - parameter delegate: Used to update the status of article download
    */
    class func createIndependentArticle(articleId: String, delegate: AnyObject?) {
        let requestURL = "\(baseURL)articles/\(articleId)"
        lLog("Create independent article")
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                self.addArticle(articleInfo, issue: nil, placement: 0, delegate: delegate)
                
            }
            else if let err = error {
                //Update article status - error
                if delegate != nil {
                    (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: requestURL, status: 2)
                }
                print("Error: " + err.description)
            }
        }
    }
    
    //Add article with given issue global id
    class func createArticle(articleId: String, issueId: String, delegate: AnyObject?) {
        let requestURL = "\(baseURL)articles/\(articleId)"
        lLog("Article \(articleId)")
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                let issue = Issue.getIssue(issueId)
                self.addArticle(articleInfo, issue: issue, placement: 0, delegate: delegate)
                
            }
            else if let err = error {
                //Update article status - error
                if delegate != nil {
                    (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: articleId, url: requestURL, status: 2)
                }
                print("Error: " + err.description)
            }
        }
    }
    
    //MARK: Class methods
    
    //Create article not associated with any issue
    //The structure expected for the dictionary is the same as currently used in Magnet
    //Images will be stored in Documents folder by default for such articles
    class func addArticle(article: NSDictionary, issue: Issue?, placement: Int, delegate: AnyObject?) {
        let realm = RLMRealm.defaultRealm()
        
        let gid = article.valueForKey("id") as! String
        let meta = article.objectForKey("meta") as! NSDictionary
        
        var finalPlacement = placement
        
        if let existingArticle = Article.getArticle(gid, appleId: nil) {
            finalPlacement = existingArticle.placement
            
            if let updateDate: String = existingArticle.getValue("updateDate") as? String {
                let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                var newUpdatedDate = NSDate()
                if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                    if let dt: String = updated["date"] as? String {
                        newUpdatedDate = Helper.publishedDateFromISO(dt)
                    }
                }
                if newUpdatedDate.compare(lastUpdatedDate) != NSComparisonResult.OrderedDescending {
                    Relation.createRelation(existingArticle.issueId, articleId: gid, assetId: nil)
                    //Check if the image is not downloaded - then download again
                    existingArticle.downloadArticleAssets(delegate as? IssueHandler)
                    if delegate != nil {
                        if issue != nil {
                            (delegate as! IssueHandler).updateStatusDictionary(issue!.volumeId, issueId: issue!.globalId, url: "\(baseURL)articles/\(gid)", status: 3)
                        }
                        else {
                            (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: gid, url: "\(baseURL)articles/\(gid)", status: 3)
                        }
                    }
                    return
                    //Don't download if already downloaded and not updated
                }
            }
        }
        
        let currentArticle = Article()
        currentArticle.globalId = gid
        currentArticle.title = article.valueForKey("title") as! String
        currentArticle.body = article.valueForKey("body") as! String
        currentArticle.articleDesc = article.valueForKey("description") as! String
        currentArticle.authorName = article.valueForKey("authorName") as! String
        currentArticle.authorURL = article.valueForKey("authorUrl") as! String
        currentArticle.authorBio = article.valueForKey("authorBio") as! String
        currentArticle.url = article.valueForKey("sharingUrl") as! String
        currentArticle.section = article.valueForKey("section") as! String
        currentArticle.articleType = article.valueForKey("type") as! String
        currentArticle.commentary = article.valueForKey("commentary") as! String
        currentArticle.slug = article.valueForKey("slug") as! String
        currentArticle.placement = finalPlacement
        
        if let sku = article.valueForKey("sku") as? String {
            currentArticle.appleId = sku
        }
        
        let featured = meta.valueForKey("featured") as! NSNumber
        currentArticle.isFeatured = featured.boolValue
        if let published = meta.valueForKey("published") as? NSNumber {
            currentArticle.isPublished = published.boolValue
        }
        
        var publishDateSave = false
        if let publishedDate = meta.valueForKey("publishedDate") as? String {
            if !publishedDate.isEmpty {
                currentArticle.date = Helper.publishedDateFromISO2(publishedDate)
                publishDateSave = true
            }
        } //For Gothamist

        if !publishDateSave {
            //Download the article again
            createArticleForId(gid, issue: issue, placement: placement, delegate: delegate)
            return
        }
        /*var updated = meta.valueForKey("updated") as! NSDictionary
        if let updateDate: String = updated.valueForKey("date") as? String {
            currentArticle.date = Helper.publishedDateFromISO(updateDate)
        }*/
        
        if let metadata: AnyObject = article.objectForKey("customMeta") {
            if metadata.isKindOfClass(NSDictionary) {
                let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                if let updated: Dictionary<String, AnyObject> = meta.objectForKey("updated") as? Dictionary {
                    if let updateDate: String = updated["date"] as? String {
                        metadataDict.setObject(updateDate, forKey: "updateDate")
                        if !publishDateSave {
                            currentArticle.date = Helper.publishedDateFromISO(updateDate)
                        }
                    }
                }
                currentArticle.metadata = Helper.stringFromJSON(metadataDict)!
            }
            else {
                currentArticle.metadata = metadata as! String
            }
        }
        
        let keywords = article.objectForKey("keywords") as! NSArray
        if keywords.count > 0 {
            currentArticle.keywords = Helper.stringFromJSON(keywords)!
        }
        
        var currIssue = Issue()
        if issue != nil {
            currIssue = issue!
        }
        else {
            currIssue.assetFolder = "/Documents"
        }
        currentArticle.issueId = currIssue.globalId
        
        //Add all assets of the article (will add images and sound)
        let articleMedia = article.objectForKey("media") as! NSArray
        if articleMedia.count > 0 {
            var assetList = ""
            var assetArray = [String]()
            for (index, assetDict) in articleMedia.enumerate() {
                //Download images and create Asset object for issue
                let assetid = assetDict.valueForKey("id") as! String
                assetList += assetid
                if index < (articleMedia.count - 1) {
                    assetList += ","
                }
                if delegate != nil {
                    if issue != nil {
                        Relation.createRelation(currentArticle.issueId, articleId: currentArticle.globalId, assetId: assetid)
                        (delegate as! IssueHandler).updateStatusDictionary(currIssue.volumeId, issueId: currIssue.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                    }
                    else {
                        Relation.createRelation(nil, articleId: currentArticle.globalId, assetId: assetid)
                        (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: currentArticle.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                    }
                }
                assetArray.append(assetid)
                
                if index == 0 {
                    currentArticle.thumbImageURL = assetid
                }
            }
            var deleteAssets = [String]()
            if let assets = Asset.getAssetsFor(currIssue.globalId, articleId: currentArticle.globalId, volumeId: nil, type: nil) {
                for asset in assets {
                    if let _ = assetArray.indexOf(asset.globalId) {}
                    else {
                        deleteAssets.append(asset.globalId)
                    }
                }
            }
            if deleteAssets.count > 0 {
                Asset.deleteAssets(deleteAssets)
            }
            
            Asset.downloadAndCreateAssetsForIds(assetList, issue: currIssue, articleId: currentArticle.globalId, delegate: delegate)
        }
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(currentArticle)
        do {
            try realm.commitWriteTransaction()
            Relation.createRelation(currentArticle.issueId, articleId: currentArticle.globalId, assetId: nil)
        } catch let error {
            NSLog("Error adding article: \(error)")
        }
        //realm.commitWriteTransaction()
        
        //Article downloaded (not necessarily assets)
        if delegate != nil {
            if issue != nil {
                (delegate as! IssueHandler).updateStatusDictionary(currIssue.volumeId, issueId: currIssue.globalId, url: "\(baseURL)articles/\(currentArticle.globalId)", status: 1)
            }
            else {
                (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: currentArticle.globalId, url: "\(baseURL)articles/\(currentArticle.globalId)", status: 1)
            }
        }
    }
    
    // MARK: Public methods
    
    /**
    This method accepts an issue's global id and deletes all articles from the database which belong to that issue
    
    :brief: Delete articles and assets for a specific issue
    
    - parameter  issueId: The global id of the issue whose articles have to be deleted
    */
    public class func deleteArticlesFor(issueId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId = %@", issueId)
        let articles = Article.objectsWithPredicate(predicate)
        
        var articleIds = [String]()
        //go through each article and delete all assets associated with it
        for article in articles {
            let article = article as! Article
            articleIds.append(article.globalId)
        }
        
        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete articles
        realm.beginWriteTransaction()
        realm.deleteObjects(articles)
        do {
            try realm.commitWriteTransaction()
            Relation.deleteRelations(nil, articleId: articleIds, assetId: nil)
        } catch let error {
            NSLog("Error deleting articles: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
    This method accepts an issue's global id, type of article to be found and type of article to be excluded. It retrieves all articles which meet these conditions and returns them in an array.
    
    All parameters are optional. At least one of the parameters is needed when making this call. The parameters follow AND conditions
    
    :brief: Get all articles fulfiling certain conditions
    
    - parameter  issueId: The global id of the issue whose articles have to be searched
    
    - parameter type: The article type which should be searched and returned
    
    - parameter excludeType: The article type which should not be included in the search
    
    - parameter count: Number of articles to be returned
    
    - parameter page: Page number (will be used with count)
    
    :return: an array of articles fulfiling the conditions sorted by date
    */
    public class func getArticlesFor(issueId: NSString?, type: String?, excludeType: String?, count: Int, page: Int) -> Array<Article>? {
        let relations = Relation.allObjects()
        if relations.count == 0 {
            Relation.addAllArticles()
            Relation.addAllAssets()
        }
        
        _ = RLMRealm.defaultRealm()
        
        var subPredicates = Array<NSPredicate>()
        
        if issueId != nil {
            var articleIds = [String]()
            articleIds = Relation.getArticlesForIssue(issueId! as String)
            
            if articleIds.count > 0 {
                let predicate = NSPredicate(format: "globalId IN %@", articleIds)
                subPredicates.append(predicate)
            }
        }
        
        if type != nil {
            let typePredicate = NSPredicate(format: "articleType = %@", type!)
            subPredicates.append(typePredicate)
        }
        if excludeType != nil {
            let excludePredicate = NSPredicate(format: "articleType != %@", excludeType!)
            subPredicates.append(excludePredicate)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            var articles: RLMResults
            
            articles = Article.objectsWithPredicate(searchPredicate).sortedResultsUsingProperty("date", ascending: false)
            
            if articles.count > 0 {
                var array = Array<Article>()
                for object in articles {
                    if let obj = object as? Article {
                        array.append(obj)
                    }
                }
                
                //If count > 0, return only values in that range
                if count > 0 {
                    let startIndex = page * count
                    if startIndex >= array.count {
                        return nil
                    }
                    let endIndex = (array.count > startIndex+count) ? (startIndex + count - 1) : (array.count - 1)
                    let slicedArray = Array(array[startIndex...endIndex])
                    
                    return slicedArray
                }
                return array
            }
        }
        else {
            //Everything is nil, return all articles
            let articles = Article.allObjects().sortedResultsUsingProperty("date", ascending: false)
            
            if articles.count > 0 {
                var array = Array<Article>()
                for object in articles {
                    if let obj = object as? Article {
                        array.append(obj)
                    }
                }
                
                //If count > 0, return only values in that range
                if count > 0 {
                    let startIndex = page * count
                    if startIndex >= array.count {
                        return nil
                    }
                    let endIndex = (array.count > startIndex+count) ? (startIndex + count - 1) : (array.count - 1)
                    let slicedArray = Array(array[startIndex...endIndex])
                    
                    return slicedArray
                }
                return array
            }
        }
        
        return nil
    }
    
    /**
    This method accepts an issue's global id and the key and value for article search. It retrieves all articles which meet these conditions and returns them in an array.
    
    The key and value are needed. Other articles are optional. To ignore pagination, pass the count as 0
    
    - parameter  issueId: The global id of the issue whose articles have to be searched
    
    - parameter key: The key whose values need to be searched. Please ensure this has the same name as the properties available. The value can be any of the Article properties, keywords or customMeta keys
    
    - parameter value: The value of the key for the articles to be retrieved. If sending multiple keywords, use a comma-separated string with no spaces e.g. keyword1,keyword2,keyword3
    
    - parameter count: Number of articles to be returned
    
    - parameter page: Page number (will be used with count)
    
    :return: an array of articles fulfiling the conditions sorted by date
    */
    public class func getArticlesFor(issueId: NSString?, key: String, value: String, count: Int, page: Int) -> Array<Article>? {
        _ = RLMRealm.defaultRealm()
        
        lLog("Articles for \(key) = \(value)")
        var articleIds = [String]()
        if let issueId = issueId {
            articleIds = Relation.getArticlesForIssue(issueId as String)
        }
        var subPredicates = Array<NSPredicate>()
        
        if articleIds.count > 0 {
            let predicate = NSPredicate(format: "globalId IN %@", articleIds)
            subPredicates.append(predicate)
        }
        let testArticle = Article()
        let properties: NSArray = testArticle.objectSchema.properties
        
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
            if key == "keywords" {
                let keywords: [String] = value.componentsSeparatedByString(",")
                var keywordPredicates = Array<NSPredicate>()
                for keyword in keywords {
                    let subPredicate = NSPredicate(format: "keywords CONTAINS %@", keyword)
                    keywordPredicates.append(subPredicate)
                }
                let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: keywordPredicates)
                subPredicates.append(orPredicate)
            }
            else {
                let keyPredicate = NSPredicate(format: "%K = %@", key, value)
                subPredicates.append(keyPredicate)
            }
        }
        else {
            //Is a customMeta key
            let checkString = "\"\(key)\":\"\(value)\""
            let subPredicate = NSPredicate(format: "metadata CONTAINS %@", checkString)
            subPredicates.append(subPredicate)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            var articles: RLMResults
            
            articles = Article.objectsWithPredicate(searchPredicate).sortedResultsUsingProperty("date", ascending: false) as RLMResults
            
            if articles.count > 0 {
                var array = Array<Article>()
                for object in articles {
                    let obj: Article = object as! Article
                    array.append(obj)
                }
                
                //If count > 0, return only values in that range
                if count > 0 {
                    let startIndex = page * count
                    if startIndex >= array.count {
                        return nil
                    }
                    let endIndex = (array.count > startIndex+count) ? (startIndex + count - 1) : (array.count - 1)
                    let slicedArray = Array(array[startIndex...endIndex])
                    
                    return slicedArray
                }
                return array
            }
        }
        
        return nil
    }
    
    /**
    This method inputs the global id or Apple id of an article and returns the Article object
    
    - parameter  articleId: The global id for the article
    
    - parameter appleId: The apple id/SKU for the article
    
    :return: article object for the global/Apple id. Returns nil if the article is not found
    */
    public class func getArticle(articleId: String?, appleId: String?) -> Article? {
        _ = RLMRealm.defaultRealm()
        
        var predicate: NSPredicate
        if !Helper.isNilOrEmpty(articleId) {
            predicate = NSPredicate(format: "globalId = %@", articleId!)
        }
        else if !Helper.isNilOrEmpty(appleId) {
            predicate = NSPredicate(format: "appleId = %@", appleId!)
        }
        else {
            return nil
        }

        let articles = Article.objectsWithPredicate(predicate)
        
        if articles.count > 0 {
            return articles.firstObject() as? Article
        }
        
        return nil
    }
    
    /**
    This method accepts an issue's global id and returns all articles for an issue (or if nil, all issues) with specific keywords
    
    :brief: Get all articles for an issue with specific keywords
    
    - parameter  keywords: An array of String values with keywords that the article should have. If any of the keywords match, the article will be selected
    
    - parameter issueId: Global id for the issue which the articles must belong to. This parameter is optional
    
    :return: an array of articles fulfiling the conditions
    */
    public class func searchArticlesWith(keywords: [String], issueId: String?) -> Array<Article>? {
        _ = RLMRealm.defaultRealm()
        
        lLog("Search articles with \(keywords)")
        
        var subPredicates = Array<NSPredicate>()
        
        for keyword in keywords {
            let subPredicate = NSPredicate(format: "keywords CONTAINS %@", keyword)
            subPredicates.append(subPredicate)
        }
        
        let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
        
        subPredicates.removeAll()
        subPredicates.append(orPredicate)
        
        if issueId != nil {
            let articleIds = Relation.getArticlesForIssue(issueId! as String)
            if articleIds.count > 0 {
                let predicate = NSPredicate(format: "globalId IN %@", articleIds)
                subPredicates.append(predicate)
            }
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            let articles: RLMResults = Article.objectsWithPredicate(searchPredicate) as RLMResults
            
            if articles.count > 0 {
                var array = Array<Article>()
                for object in articles {
                    let obj: Article = object as! Article
                    array.append(obj)
                }
                return array
            }
        }
        
        return nil
    }
    
    /**
    This method accepts an issue's global id and returns all articles for the issue which are featured
    
    :brief: Get all  featured articles for a specific issue
    
    - parameter issueId: Global id for the issue whose featured articles are needed
    
    :return: an array of featured articles for the issue
    */
    public class func getFeaturedArticlesFor(issueId: NSString) -> Array<Article>? {
        _ = RLMRealm.defaultRealm()
        
        let articleIds = Relation.getArticlesForIssue(issueId as String)
        if articleIds.count > 0 {
            let predicate = NSPredicate(format: "globalId IN %@ AND isFeatured == true", articleIds)
            let articles: RLMResults = Article.objectsWithPredicate(predicate) as RLMResults
            
            if articles.count > 0 {
                var array = Array<Article>()
                for object in articles {
                    let obj: Article = object as! Article
                    array.append(obj)
                }
                return array
            }
        }
        return nil
    }
    
    /**
    This method accepts a regular expression which should be used to identify placeholders for assets in an article body.
    The default asset pattern is `<!-- \\[ASSET: .+\\] -->`
    
    :brief: Change the asset pattern
    
    - parameter newPattern: The regex to identify pattern for asset placeholders
    */
    public class func setAssetPattern(newPattern: String) {
        assetPattern = newPattern
    }
    
    /**
    This method returns all articles whose publish date is before the published date provided
    
    - parameter date: The date to compare publish dates with
    
    :return: an array of articles older than the given date
    */
    public class func getOlderArticles(date: NSDate) -> Array<Article>? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "date < %@", date)
        let articles: RLMResults = Article.objectsWithPredicate(predicate) as RLMResults
        
        if articles.count > 0 {
            var array = Array<Article>()
            for object in articles {
                let obj: Article = object as! Article
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method returns all articles whose publish date is after the published date provided
    
    - parameter date: The date to compare publish dates with
    
    :return: an array of articles newer than the given date
    */
    public class func getNewerArticles(date: NSDate) -> Array<Article>? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "date > %@", date)
        let articles: RLMResults = Article.objectsWithPredicate(predicate) as RLMResults
        
        if articles.count > 0 {
            var array = Array<Article>()
            for object in articles {
                let obj: Article = object as! Article
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    //MARK: Instance methods
    
    /**
    This method refreshes the given article by downloading it again
    */
    public func refreshArticle(handler: IssueHandler?) {
        let realm = RLMRealm.defaultRealm()
        let requestURL = "\(baseURL)articles/\(self.globalId)"
        let networkManager = LRNetworkManager.sharedInstance
        
        if handler != nil {
            if !self.issueId.isEmpty {
                handler!.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: "\(baseURL)issues/\(self.issueId)"), forKey: self.issueId)
                handler!.updateStatusDictionary("", issueId: self.issueId, url: requestURL, status: 0)
            }
            else {
                handler!.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: self.globalId)
                handler!.updateStatusDictionary("", issueId: self.globalId, url: requestURL, status: 0)
            }
        }
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                
                realm.beginWriteTransaction()
                
                let articleInfo = allArticles.firstObject as! NSDictionary
                //self.globalId = articleInfo.valueForKey("id") as! String
                self.title = articleInfo.valueForKey("title") as! String
                self.body = articleInfo.valueForKey("body") as! String
                self.articleDesc = articleInfo.valueForKey("description") as! String
                self.authorName = articleInfo.valueForKey("authorName") as! String
                self.authorURL = articleInfo.valueForKey("authorUrl") as! String
                self.authorBio = articleInfo.valueForKey("authorBio") as! String
                self.url = articleInfo.valueForKey("sharingUrl") as! String
                self.section = articleInfo.valueForKey("section") as! String
                self.articleType = articleInfo.valueForKey("type") as! String
                self.commentary = articleInfo.valueForKey("commentary") as! String
                self.slug = articleInfo.valueForKey("slug") as! String
                
                let meta = articleInfo.objectForKey("meta") as! NSDictionary
                let featured = meta.valueForKey("featured") as! NSNumber
                self.isFeatured = featured.boolValue
                if let published = meta.valueForKey("published") as? NSNumber {
                    self.isPublished = published.boolValue
                }
                
                if let publishedDate = meta.valueForKey("publishedDate") as? String {
                    self.date = Helper.publishedDateFromISO2(publishedDate)
                }
                
                if let metadata: AnyObject = articleInfo.objectForKey("customMeta") {
                    if metadata.isKindOfClass(NSDictionary) {
                        self.metadata = Helper.stringFromJSON(metadata)!
                    }
                    else {
                        self.metadata = metadata as! String
                    }
                }
                
                let keywords = articleInfo.objectForKey("keywords") as! NSArray
                if keywords.count > 0 {
                    self.keywords = Helper.stringFromJSON(keywords)!
                }
                
                realm.addOrUpdateObject(self)
                do {
                    try realm.commitWriteTransaction()
                } catch let error {
                    NSLog("Error saving issue: \(error)")
                }
                //realm.commitWriteTransaction()
                
                if handler != nil {
                    //Mark article as done
                    if !self.issueId.isEmpty {
                        handler!.updateStatusDictionary("", issueId: self.issueId, url: requestURL, status: 1)
                    }
                    else {
                        handler!.updateStatusDictionary("", issueId: self.globalId, url: requestURL, status: 1)
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                if handler != nil {
                    //Mark all articles from the list as done with errors
                    if !self.issueId.isEmpty {
                        handler!.updateStatusDictionary("", issueId: self.issueId, url: requestURL, status: 2)
                    }
                    else {
                        handler!.updateStatusDictionary("", issueId: self.globalId, url: requestURL, status: 2)
                    }
                }
            }
            
            if handler != nil {
                if !self.issueId.isEmpty {
                    handler!.updateStatusDictionary("", issueId: self.issueId, url: "\(baseURL)issues/\(self.issueId)", status: 1)
                }
                else {
                    handler!.updateStatusDictionary("", issueId: self.globalId, url: requestURL, status: 1)
                }
            }
        }
    }
    
    /**
    This method deletes a stand-alone article and all assets for the given article
    */
    
    public func deleteArticle() {
        let realm = RLMRealm.defaultRealm()
        
        //Delete all assets for the article
        let articleIds = NSMutableArray()
        articleIds.addObject(self.globalId)
        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete article
        realm.beginWriteTransaction()
        realm.deleteObject(self)
        do {
            try realm.commitWriteTransaction()
            Relation.deleteRelations(nil, articleId: [self.globalId], assetId: nil)
        } catch let error {
            NSLog("Error deleting article: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    
    /**
    This method downloads assets for the article
    */
    public func downloadArticleAssets(delegate: IssueHandler?) {
        lLog("Download assets for \(self.globalId)")
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        var assetFolder = docsDir as String
        
        let issueIds = Relation.getIssuesForArticle(self.globalId)
        var issue = Issue()
        if issueIds.count == 0 {
            issue.assetFolder = "/Documents"
        }
        else {
            issue = Issue.getIssue(issueIds.first!)!
            let folder = issue.assetFolder
            if folder.hasPrefix("/Documents") {
            }
            else if !folder.isEmpty {
                assetFolder = folder.stringByReplacingOccurrencesOfString("/\(issue.appleId)", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
            }
        }
        
        let requestURL = "\(baseURL)articles/\(self.globalId)"
        
        var issueHandler: IssueHandler
        if delegate != nil {
            issueHandler = delegate!
        }
        else {
            issueHandler = IssueHandler(folder: assetFolder)!
            issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: self.globalId)
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                
                //Add all assets of the article
                let articleMedia = articleInfo.objectForKey("media") as! NSArray
                if articleMedia.count > 0 {
                    var assetList = ""
                    var assetArray = [String]()
                    for (index, assetDict) in articleMedia.enumerate() {
                        //Download images and create Asset object for issue
                        let assetid = assetDict.valueForKey("id") as! String
                        Relation.createRelation(nil, articleId: self.globalId, assetId: assetid)
                        assetList += assetid
                        if index < (articleMedia.count - 1) {
                            assetList += ","
                        }
                        assetArray.append(assetid)
                        if delegate != nil {
                            Relation.createRelation(issue.globalId, articleId: self.globalId, assetId: assetid)
                            issueHandler.updateStatusDictionary(nil, issueId: issue.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        else {
                            Relation.createRelation(nil, articleId: self.globalId, assetId: assetid)
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                    }
                    var deleteAssets = [String]()
                    if let assets = Asset.getAssetsFor(issue.globalId, articleId: self.globalId, volumeId: nil, type: nil) {
                        for asset in assets {
                            if let _ = assetArray.indexOf(asset.globalId) {}
                            else {
                                deleteAssets.append(asset.globalId)
                            }
                        }
                    }
                    if deleteAssets.count > 0 {
                        Asset.deleteAssets(deleteAssets)
                    }
                    
                    Asset.downloadAndCreateAssetsForIds(assetList, issue: issue, articleId: self.globalId, delegate: issueHandler)
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)articles/\(self.globalId)", status: 2)
            }
            
        }
    }
    
    /**
     This method downloads assets for the article
     */
    public func downloadFirstAsset(delegate: IssueHandler?) {
        lLog("Download first asset for \(self.globalId)")
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        var assetFolder = docsDir as String
        
        let issueIds = Relation.getIssuesForArticle(self.globalId)
        var issue = Issue()
        if issueIds.count == 0 {
            issue.assetFolder = "/Documents"
        }
        else {
            issue = Issue.getIssue(issueIds.first!)!
            let folder = issue.assetFolder
            if folder.hasPrefix("/Documents") {
            }
            else if !folder.isEmpty {
                assetFolder = folder.stringByReplacingOccurrencesOfString("/\(issue.appleId)", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
            }
        }
        
        let requestURL = "\(baseURL)articles/\(self.globalId)"
        
        var issueHandler: IssueHandler
        if delegate != nil {
            issueHandler = delegate!
        }
        else {
            issueHandler = IssueHandler(folder: assetFolder)!
            issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(bool: false) , forKey: requestURL), forKey: self.globalId)
        }
        
        if !self.thumbImageURL.isEmpty {
            if delegate != nil {
                issueHandler.updateStatusDictionary(nil, issueId: self.issueId, url: "\(baseURL)media/\(self.thumbImageURL)", status: 0)
            }
            else {
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(self.thumbImageURL)", status: 0)
            }
            Asset.downloadAndCreateAsset(self.thumbImageURL, issue: issue, articleId: self.globalId as String, placement: 1, delegate: issueHandler)
            return
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                
                //Add all assets of the article
                let articleMedia = articleInfo.objectForKey("media") as! NSArray
                if articleMedia.count > 0 {
                    if let assetDict = articleMedia.firstObject {
                        let assetid = assetDict.valueForKey("id") as! String
                        Relation.createRelation(nil, articleId: self.globalId, assetId: assetid)
                        if delegate != nil {
                            issueHandler.updateStatusDictionary(nil, issueId: self.issueId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        else {
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        Asset.downloadAndCreateAsset(assetid, issue: issue, articleId: self.globalId as String, placement: 1, delegate: issueHandler)
                    }
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)articles/\(self.globalId)", status: 2)
            }
            
        }
    }
    
    /**
    This method can be called on an Article object to save it back to the database
    
    :brief: Save an Article to the database
    */
    public func saveArticle() {
        let realm = RLMRealm.defaultRealm()
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(self)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving article: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    /**
    This method replaces the asset placeholders in the body of the Article with actual assets using HTML codes
    Images are replaced with HTML img tags, Audio and Video with HTML audio and video tags respectively
    
    :brief: Replace asset pattern with actual assets in an Article body
    
    :return: HTML body of the article with actual assets in place of placeholders
    */
    public func replacePatternsWithAssets() -> NSString {
        //Should work for images, audio, video or any other types of assets
        let regex = try? NSRegularExpression(pattern: assetPattern, options: NSRegularExpressionOptions.CaseInsensitive)
        
        let articleBody = self.body
        
        var updatedBody: NSString = articleBody
        
        if let matches: [NSTextCheckingResult] = regex?.matchesInString(articleBody, options: [], range: NSMakeRange(0, articleBody.characters.count)) {
            if matches.count > 0 {
                for match: NSTextCheckingResult in matches {
                    let matchRange = match.range
                    let range = NSRange(location: matchRange.location, length: matchRange.length)
                    var matchedString: NSString = (articleBody as NSString).substringWithRange(range) as NSString
                    let originallyMatched = matchedString
                    
                    //Get global id for the asset
                    for patternPart in assetPatternParts {
                        matchedString = matchedString.stringByReplacingOccurrencesOfString(patternPart, withString: "", options: [], range: NSMakeRange(0, matchedString.length))
                    }
                    
                    //Find asset with the global id
                    if let asset = Asset.getAsset(matchedString as String) {
                        //Use the asset - generate an HTML with the asset file URL (image, audio, video)
                        let originalAssetPath = asset.getAssetPath()
                        let fileURL: NSURL! = NSURL(fileURLWithPath: originalAssetPath!)
                        
                        //Replace with HTML tags
                        var finalHTML = "<div class='article_image'>"
                        if asset.type == "image" {
                            finalHTML += "<img src='\(fileURL)' alt='Tap to enlarge image' />"
                        }
                        else if asset.type == "sound" {
                            finalHTML += "<audio src='\(fileURL)' controls='controls' />"
                        }
                        else if asset.type == "video" {
                            finalHTML += "<video src='\(fileURL)' controls />"
                        }
                        
                        //Add caption and source
                        var captionSource = ""
                        if asset.source != "" {
                            captionSource += "<span class='source'>\(asset.source)</span>"
                        }
                        if asset.caption != "" {
                            captionSource += "<span class='caption'>\(asset.caption)</span>"
                        }
                        if captionSource != "" {
                            finalHTML += "<div class='article_caption'>\(captionSource)</div>"
                        }
                        finalHTML += "</div>" //closing div
                        
                        //Special case - the asset was enclosed in paragraph tags
                        //Move opening paragraph tag after the asset html in that case
                        if matchRange.location >= 3 && articleBody.characters.count > 3 {
                            let possibleMatchRange = NSMakeRange(matchRange.location - 3, 3)
                            
                            if updatedBody.substringWithRange(possibleMatchRange) == "<p>" {
                                updatedBody = updatedBody.stringByReplacingCharactersInRange(possibleMatchRange, withString: "")
                                finalHTML += "<p>"
                            }
                        }
                        
                        updatedBody = updatedBody.stringByReplacingOccurrencesOfString(originallyMatched as String, withString: finalHTML)
                    }
                    else {
                        //Asset hasn't been downloaded yet (or record created)
                        updatedBody = updatedBody.stringByReplacingOccurrencesOfString(originallyMatched as String, withString: "")
                    }
                }
            }
        }
        
        return updatedBody
    }
    
    /**
    This method returns all articles for an issue whose publish date is newer than the published date of current article
    
    :brief: Get all articles newer than a specific article
    
    :return: an array of articles newer than the current article (in the same issue)
    */
    public func getNewerArticles() -> Array<Article>? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "date > %@", self.date)
        let articles: RLMResults = Article.objectsWithPredicate(predicate) as RLMResults
        
        if articles.count > 0 {
            var array = Array<Article>()
            for object in articles {
                let obj: Article = object as! Article
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method returns all articles for an issue whose publish date is before the published date of current article
    
    :brief: Get all articles older than a specific article
    
    :return: an array of articles older than the current article (in the same issue)
    */
    public func getOlderArticles() -> Array<Article>? {
        _ = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "date < %@", self.date)
        let articles: RLMResults = Article.objectsWithPredicate(predicate) as RLMResults
        
        if articles.count > 0 {
            var array = Array<Article>()
            for object in articles {
                let obj: Article = object as! Article
                array.append(obj)
            }
            return array
        }
        
        return nil
    }
    
    /**
    This method returns the value for a specific key from the custom metadata of the article
    
    :brief: Get value for a specific key from custom meta of an article
    
    :return: an object for the key from the custom metadata (or nil)
    */
    public func getValue(key: NSString) -> AnyObject? {
        
        let testArticle = Article()
        let properties: NSArray = testArticle.objectSchema.properties
        
        var foundProperty = false
        for property: RLMProperty in properties as! [RLMProperty] {
            let propertyName = property.name
            if propertyName == key {
                //This is the property we are looking for
                foundProperty = true
                break
            }
        }
        if (foundProperty) {
            //Get value of this property and return
            return self.valueForKey(key as String)
        }
        else {
            //This is a metadata key
            let metadata: AnyObject? = Helper.jsonFromString(self.metadata)
            if let metadataDict = metadata as? NSDictionary {
                return metadataDict.valueForKey(key as String)
            }
        }
        
        return nil
    }

}
