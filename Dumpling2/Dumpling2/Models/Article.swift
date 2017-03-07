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
open class Article: RLMObject {
    /// Global id of an article - this is unique for each article
    dynamic open var globalId = ""
    /// Article title
    dynamic open var title = ""
    /// Article description
    dynamic open var articleDesc = "" //description
    dynamic open var slug = ""
    dynamic open var dek = ""
    /// Article content
    dynamic open var body = ""
    /// Permanent link to the article
    dynamic open var permalink = "" //keeping URLs as string - we might need to append parts to get the final
    /// Article URL
    dynamic open var url = ""
    /// URL to the article's source
    dynamic open var sourceURL = ""
    /// Article author's name
    dynamic open var authorName = ""
    /// Link to the article author's profile
    dynamic open var authorURL = ""
    /// Article author's bio
    dynamic open var authorBio = ""
    /// Section under which the article falls
    dynamic open var section = ""
    /// Type of article
    dynamic open var articleType = ""
    /// Keywords which the article falls under
    dynamic open var keywords = ""
    /// Article commentary
    dynamic open var commentary = ""
    /// Article published date
    dynamic open var date = Date()
    /// Article metadata
    dynamic open var metadata = ""
    dynamic open var versionStashed = ""
    /// Placement of the article in an issue
    dynamic open var placement = 0
    /// URL for the article's feature image
    dynamic open var mainImageURL = ""
    /// URL for the article's thumbnail image
    dynamic open var thumbImageURL = ""
    /// Status of article (published or not)
    dynamic open var isPublished = false
    /// Whether the article is featured for the given issue or not
    dynamic open var isFeatured = false
    /// Global id for the issue the article belongs to. This can be blank for independent articles
    dynamic open var issueId = ""
    ///SKU/Apple id for the article - will be used when articles are sold individually
    dynamic open var appleId = ""
    
    override open class func primaryKey() -> String {
        return "globalId"
    }
    
    //Required for backward compatibility when upgrading to V 0.96.2
    override open class func requiredProperties() -> Array<String> {
        return ["globalId", "title", "articleDesc", "slug", "dek", "body", "permalink", "url", "sourceURL", "authorName", "authorURL", "authorBio", "section", "articleType", "keywords", "commentary", "date", "metadata", "versionStashed", "placement", "mainImageURL", "thumbImageURL", "isPublished", "isFeatured", "issueId", "appleId"]
    }
    
    //Add article
    class func createArticle(_ article: NSDictionary, issue: Issue, placement: Int) {
        let realm = RLMRealm.default()
        
        let currentArticle = Article()
        currentArticle.globalId = article.object(forKey: "global_id") as! String
        currentArticle.title = article.object(forKey: "title") as! String
        currentArticle.body = article.object(forKey: "body") as! String
        currentArticle.articleDesc = article.object(forKey: "description") as! String
        currentArticle.url = article.object(forKey: "url") as! String
        currentArticle.section = article.object(forKey: "section") as! String
        currentArticle.authorName = article.object(forKey: "author_name") as! String
        currentArticle.sourceURL = article.object(forKey: "source") as! String
        currentArticle.dek = article.object(forKey: "dek") as! String
        currentArticle.authorURL = article.object(forKey: "author_url") as! String
        currentArticle.authorBio = article.object(forKey: "author_bio") as! String
        currentArticle.keywords = article.object(forKey: "keywords") as! String
        currentArticle.commentary = article.object(forKey: "commentary") as! String
        currentArticle.articleType = article.object(forKey: "type") as! String
        
        let updateDate = article.object(forKey: "date_last_updated") as! String
        if updateDate != "" {
            currentArticle.date = Helper.publishedDateFromISO(updateDate)
        }
        
        if let sku = article.object(forKey: "sku") as? String {
            currentArticle.appleId = sku
        }
        
        let meta = article.value(forKey: "meta") as! NSDictionary
        if let published = meta.value(forKey: "published") as? NSNumber {
            currentArticle.isPublished = published.boolValue
        }
        
        let metadata: AnyObject! = article.object(forKey: "customMeta") as AnyObject!
        if metadata is NSDictionary {
            currentArticle.metadata = Helper.stringFromJSON(metadata)! //metadata.JSONString()!
        }
        else {
            currentArticle.metadata = metadata as! String
        }
        
        currentArticle.issueId = issue.globalId
        currentArticle.placement = placement
        let bundleVersion: AnyObject? = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as AnyObject?
        currentArticle.versionStashed = bundleVersion as! String
        
        //Featured or not
        if let featuredDict = article.object(forKey: "featured") as? NSDictionary {
            //If the key doesn't exist, the article is not featured (default value)
            if (featuredDict.object(forKey: issue.globalId) as AnyObject).intValue == 1 {
                currentArticle.isFeatured = true
            }
        }
        
        //Insert article images
        if let orderedArray = (article.object(forKey: "images") as AnyObject).object(forKey: "ordered") as? NSArray {
            if orderedArray.count > 0 {
                for (index, imageDict) in orderedArray.enumerated() {
                    Asset.createAsset(imageDict as! NSDictionary, issue: issue, articleId: currentArticle.globalId, placement: index+1)
                }
            }
        }
        
        //Set thumbnail for article
        if let firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: currentArticle.globalId, volumeId: nil) {
            currentArticle.thumbImageURL = firstAsset.globalId as String
        }
        
        //Insert article sound files
        if let orderedArray = (article.object(forKey: "sound_files") as AnyObject).object(forKey: "ordered") as? NSArray {
            if orderedArray.count > 0 {
                for (index, soundDict) in orderedArray.enumerated() {
                    Asset.createAsset(soundDict as! NSDictionary, issue: issue, articleId: currentArticle.globalId, sound: true, placement: index+1)
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.addOrUpdate(currentArticle)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error creating article: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    //Get article details from API and create
    class func createArticleForId(_ articleId: NSString, issue: Issue, placement: Int, delegate: AnyObject?) {
        let realm = RLMRealm.default()
        
        let requestURL = "\(baseURL)articles/\(articleId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.value(forKey: "articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                
                let currentArticle = Article()
                currentArticle.globalId = articleId as String
                currentArticle.placement = placement
                currentArticle.issueId = issue.globalId
                currentArticle.title = articleInfo.value(forKey: "title") as! String
                currentArticle.body = articleInfo.value(forKey: "body") as! String
                currentArticle.articleDesc = articleInfo.value(forKey: "description") as! String
                currentArticle.authorName = articleInfo.value(forKey: "authorName") as! String
                currentArticle.authorURL = articleInfo.value(forKey: "authorUrl") as! String
                currentArticle.authorBio = articleInfo.value(forKey: "authorBio") as! String
                currentArticle.url = articleInfo.value(forKey: "sharingUrl") as! String
                currentArticle.section = articleInfo.value(forKey: "section") as! String
                currentArticle.articleType = articleInfo.value(forKey: "type") as! String
                currentArticle.commentary = articleInfo.value(forKey: "commentary") as! String
                currentArticle.slug = articleInfo.value(forKey: "slug") as! String
                
                if let sku = articleInfo.value(forKey: "sku") as? String {
                    currentArticle.appleId = sku
                }
                
                let meta = articleInfo.object(forKey: "meta") as! NSDictionary
                let featured = meta.value(forKey: "featured") as! NSNumber
                currentArticle.isFeatured = featured.boolValue
                if let published = meta.value(forKey: "published") as? NSNumber {
                    currentArticle.isPublished = published.boolValue
                }
                
                if let publishedDate = meta.value(forKey: "publishedDate") as? String {
                    currentArticle.date = Helper.publishedDateFromISO2(publishedDate)
                }//For Gothamist
                /*var updated = meta.valueForKey("updated") as! NSDictionary
                if let updateDate: String = updated.valueForKey("date") as? String {
                    currentArticle.date = Helper.publishedDateFromISO(updateDate)
                }*/
                
                if let metadata: Any = articleInfo.object(forKey: "customMeta") {
                    if metadata is NSDictionary {
                        currentArticle.metadata = Helper.stringFromJSON(metadata as AnyObject)!
                    }
                    else {
                        currentArticle.metadata = metadata as! String
                    }
                }
                
                let keywords = articleInfo.object(forKey: "keywords") as! NSArray
                if keywords.count > 0 {
                    currentArticle.keywords = Helper.stringFromJSON(keywords)!
                }
                
                //Add all assets of the article (will add images and sound)
                let articleMedia = articleInfo.object(forKey: "media") as! NSArray
                if articleMedia.count > 0 {
                    var assetList = ""
                    for (index, assetDict) in articleMedia.enumerated() {
                        let assetDictionary = assetDict as! NSDictionary
                        //Download images and create Asset object for issue
                        let assetid = assetDictionary.value(forKey: "id") as! String
                        assetList += assetid
                        if index < (articleMedia.count - 1) {
                            assetList += ","
                        }
                        if delegate != nil {
                            (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        if index == 0 {
                            currentArticle.thumbImageURL = assetid as String
                        }
                    }
                    Asset.downloadAndCreateAssetsForIds(assetList, issue: issue, articleId: articleId as String, delegate: delegate)
                }
                
                /*//Set thumbnail for article
                if let firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: articleId as String, volumeId: nil) {
                    currentArticle.thumbImageURL = firstAsset.globalId as String
                }*/
                
                realm.beginWriteTransaction()
                realm.addOrUpdate(currentArticle)
                do {
                    try realm.commitWriteTransaction()
                } catch let error {
                    NSLog("Error creating article: \(error)")
                }
                //realm.commitWriteTransaction()
                
                if delegate != nil {
                    //Mark article as done
                    (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: requestURL, status: 1)
                }
            }
            else if let err = error {
                print("Error: " + err.description)
                if delegate != nil {
                    //Mark article as done - even if with errors
                    (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: requestURL, status: 2)
                }
            }
            
        }
    }
    
    //Get details for multiple comma-separate article ids from API and create
    class func createArticlesForIds(_ articleIds: String, issue: Issue?, delegate: AnyObject?) {
        let realm = RLMRealm.default()
        
        let requestURL = "\(baseURL)articles/\(articleIds)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.value(forKey: "articles") as! NSArray
                
                for (index, articleInfo) in allArticles.enumerated() {
                    let currentArticle = Article()
                    let articleInfoDictionary = articleInfo as! NSDictionary
                    currentArticle.globalId = articleInfoDictionary.value(forKey: "id") as! String
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
                    currentArticle.title = articleInfoDictionary.value(forKey: "title") as! String
                    currentArticle.body = articleInfoDictionary.value(forKey: "body") as! String
                    currentArticle.articleDesc = articleInfoDictionary.value(forKey: "description") as! String
                    currentArticle.authorName = articleInfoDictionary.value(forKey: "authorName") as! String
                    currentArticle.authorURL = articleInfoDictionary.value(forKey: "authorUrl") as! String
                    currentArticle.authorBio = articleInfoDictionary.value(forKey: "authorBio") as! String
                    currentArticle.url = articleInfoDictionary.value(forKey: "sharingUrl") as! String
                    currentArticle.section = articleInfoDictionary.value(forKey: "section") as! String
                    currentArticle.articleType = articleInfoDictionary.value(forKey: "type") as! String
                    currentArticle.commentary = articleInfoDictionary.value(forKey: "commentary") as! String
                    currentArticle.slug = articleInfoDictionary.value(forKey: "slug") as! String
                    
                    if let sku = articleInfoDictionary.value(forKey: "sku") as? String {
                        currentArticle.appleId = sku
                    }
                    
                    let meta = articleInfoDictionary.object(forKey: "meta") as! NSDictionary
                    let featured = meta.value(forKey: "featured") as! NSNumber
                    currentArticle.isFeatured = featured.boolValue
                    if let published = meta.value(forKey: "published") as? NSNumber {
                        currentArticle.isPublished = published.boolValue
                    }
                    
                    if let publishedDate = meta.value(forKey: "publishedDate") as? String {
                        currentArticle.date = Helper.publishedDateFromISO2(publishedDate)
                    }//For Gothamist
                    /*var updated = meta.valueForKey("updated") as! NSDictionary
                    if let updateDate: String = updated.valueForKey("date") as? String {
                    currentArticle.date = Helper.publishedDateFromISO(updateDate)
                    }*/
                    
                    if let metadata: Any = articleInfoDictionary.object(forKey: "customMeta") {
                        if metadata is NSDictionary {
                            currentArticle.metadata = Helper.stringFromJSON(metadata as AnyObject)!
                        }
                        else {
                            currentArticle.metadata = metadata as! String
                        }
                    }
                    
                    let keywords = articleInfoDictionary.object(forKey: "keywords") as! NSArray
                    if keywords.count > 0 {
                        currentArticle.keywords = Helper.stringFromJSON(keywords)!
                    }
                    
                    //Add all assets of the article (will add images and sound)
                    let articleMedia = articleInfoDictionary.object(forKey: "media") as! NSArray
                    if articleMedia.count > 0 {
                        var assetList = ""
                        for (assetIndex, assetDict) in articleMedia.enumerated() {
                            let assetDictionary = assetDict as! NSDictionary
                            //Download images and create Asset object for issue
                            let assetid = assetDictionary.value(forKey: "id") as! String
                            assetList += assetid
                            if assetIndex < (articleMedia.count - 1) {
                                assetList += ","
                            }
                            if delegate != nil {
                                if let issue = issue {
                                    (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                                }
                                else {
                                    (delegate as! IssueHandler).updateStatusDictionary("", issueId: currentArticle.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                                }
                            }
                            if assetIndex == 0 {
                                currentArticle.thumbImageURL = assetid as String
                            }
                        }
                        Asset.downloadAndCreateAssetsForIds(assetList, issue: Issue.getIssue(currentArticle.issueId), articleId: currentArticle.globalId, delegate: delegate)
                    }
                    
                    /*//Set thumbnail for article
                    if let firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: currentArticle.globalId, volumeId: nil) {
                        currentArticle.thumbImageURL = firstAsset.globalId as String
                    }*/
                    
                    realm.beginWriteTransaction()
                    realm.addOrUpdate(currentArticle)
                    do {
                        try realm.commitWriteTransaction()
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
                    let arr = articleIds.characters.split(separator: ",").map { String($0) }
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
    class func createArticlesForIdsWithThumb(_ articleIds: String, issue: Issue?, delegate: AnyObject?) {
        let realm = RLMRealm.default()
        
        let requestURL = "\(baseURL)articles/\(articleIds)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.value(forKey: "articles") as! NSArray
                
                for (index, articleInfo) in allArticles.enumerated() {
                    let currentArticle = Article()
                    let articleInfoDictionary = articleInfo as! NSDictionary
                    currentArticle.globalId = articleInfoDictionary.value(forKey: "id") as! String
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
                    currentArticle.title = articleInfoDictionary.value(forKey: "title") as! String
                    currentArticle.body = articleInfoDictionary.value(forKey: "body") as! String
                    currentArticle.articleDesc = articleInfoDictionary.value(forKey: "description") as! String
                    currentArticle.authorName = articleInfoDictionary.value(forKey: "authorName") as! String
                    currentArticle.authorURL = articleInfoDictionary.value(forKey: "authorUrl") as! String
                    currentArticle.authorBio = articleInfoDictionary.value(forKey: "authorBio") as! String
                    currentArticle.url = articleInfoDictionary.value(forKey: "sharingUrl") as! String
                    currentArticle.section = articleInfoDictionary.value(forKey: "section") as! String
                    currentArticle.articleType = articleInfoDictionary.value(forKey: "type") as! String
                    currentArticle.commentary = articleInfoDictionary.value(forKey: "commentary") as! String
                    currentArticle.slug = articleInfoDictionary.value(forKey: "slug") as! String
                    
                    if let sku = articleInfoDictionary.value(forKey: "sku") as? String {
                        currentArticle.appleId = sku
                    }
                    
                    let meta = articleInfoDictionary.object(forKey: "meta") as! NSDictionary
                    let featured = meta.value(forKey: "featured") as! NSNumber
                    currentArticle.isFeatured = featured.boolValue
                    if let published = meta.value(forKey: "published") as? NSNumber {
                        currentArticle.isPublished = published.boolValue
                    }
                    
                    if let publishedDate = meta.value(forKey: "publishedDate") as? String {
                        currentArticle.date = Helper.publishedDateFromISO2(publishedDate)
                    }
                    
                    if let metadata: Any = articleInfoDictionary.object(forKey: "customMeta") {
                        if metadata is NSDictionary {
                            currentArticle.metadata = Helper.stringFromJSON(metadata as AnyObject)!
                        }
                        else {
                            currentArticle.metadata = metadata as! String
                        }
                    }
                    
                    let keywords = articleInfoDictionary.object(forKey: "keywords") as! NSArray
                    if keywords.count > 0 {
                        currentArticle.keywords = Helper.stringFromJSON(keywords)!
                    }
                    
                    //Add all assets of the article (will add images and sound)
                    let articleMedia = articleInfoDictionary.object(forKey: "media") as! NSArray
                    if articleMedia.count > 0 {
                        let assetDict = articleMedia.firstObject as! NSDictionary
                        let assetid = assetDict.value(forKey: "id") as! String
                        if delegate != nil {
                            if let issue = issue {
                                (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                            }
                            else {
                                (delegate as! IssueHandler).updateStatusDictionary("", issueId: currentArticle.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                            }
                        }
                        currentArticle.thumbImageURL = assetid as String
                        Asset.downloadAndCreateAssetsForIds(assetid, issue: Issue.getIssue(currentArticle.issueId), articleId: currentArticle.globalId, delegate: delegate)
                    }
                    
                    realm.beginWriteTransaction()
                    realm.addOrUpdate(currentArticle)
                    do {
                        try realm.commitWriteTransaction()
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
                    let arr = articleIds.characters.split(separator: ",").map { String($0) }
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
    
    class func deleteArticlesForIssues(_ issues: NSArray) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "issueId IN %@", issues)
        let articles = Article.objects(in: realm, with: predicate)
        
        let articleIds = NSMutableArray()
        //go through each article and delete all assets associated with it
        for article in articles {
            let article = article as! Article
            articleIds.add(article.globalId)
        }

        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete articles
        realm.beginWriteTransaction()
        realm.deleteObjects(articles)
        do {
            try realm.commitWriteTransaction()
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
    class func createIndependentArticle(_ articleId: String, delegate: AnyObject?) {
        let requestURL = "\(baseURL)articles/\(articleId)"
        lLog("Create independent article")
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.value(forKey: "articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                self.addArticle(articleInfo, delegate: delegate)
                
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
    class func createArticle(_ articleId: String, issueId: String, delegate: AnyObject?) {
        let requestURL = "\(baseURL)articles/\(articleId)"
        lLog("Article \(articleId)")
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.value(forKey: "articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                self.addArticle(articleInfo, delegate: delegate)
                
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
    class func addArticle(_ article: NSDictionary, delegate: AnyObject?) {
        let realm = RLMRealm.default()
        
        let gid = article.value(forKey: "id") as! String
        let meta = article.object(forKey: "meta") as! NSDictionary
        
        if let existingArticle = Article.getArticle(gid, appleId: nil) {
            if let updateDate: String = existingArticle.getValue("updateDate") as? String {
                let lastUpdatedDate = Helper.publishedDateFromISO(updateDate)
                var newUpdatedDate = Date()
                if let updated: Dictionary<String, AnyObject> = meta.object(forKey: "updated") as? Dictionary {
                    if let dt: String = updated["date"] as? String {
                        newUpdatedDate = Helper.publishedDateFromISO(dt)
                    }
                }
                if newUpdatedDate.compare(lastUpdatedDate) != ComparisonResult.orderedDescending {
                    return
                    //Don't download if already downloaded and not updated
                }
            }
        }
        
        let currentArticle = Article()
        currentArticle.globalId = gid
        currentArticle.title = article.value(forKey: "title") as! String
        currentArticle.body = article.value(forKey: "body") as! String
        currentArticle.articleDesc = article.value(forKey: "description") as! String
        currentArticle.authorName = article.value(forKey: "authorName") as! String
        currentArticle.authorURL = article.value(forKey: "authorUrl") as! String
        currentArticle.authorBio = article.value(forKey: "authorBio") as! String
        currentArticle.url = article.value(forKey: "sharingUrl") as! String
        currentArticle.section = article.value(forKey: "section") as! String
        currentArticle.articleType = article.value(forKey: "type") as! String
        currentArticle.commentary = article.value(forKey: "commentary") as! String
        currentArticle.slug = article.value(forKey: "slug") as! String
        
        if let sku = article.value(forKey: "sku") as? String {
            currentArticle.appleId = sku
        }
        
        let featured = meta.value(forKey: "featured") as! NSNumber
        currentArticle.isFeatured = featured.boolValue
        if let published = meta.value(forKey: "published") as? NSNumber {
            currentArticle.isPublished = published.boolValue
        }
        
        if let publishedDate = meta.value(forKey: "publishedDate") as? String {
            currentArticle.date = Helper.publishedDateFromISO2(publishedDate)
        } //For Gothamist

        /*var updated = meta.valueForKey("updated") as! NSDictionary
        if let updateDate: String = updated.valueForKey("date") as? String {
            currentArticle.date = Helper.publishedDateFromISO(updateDate)
        }*/
        
        if let metadata: AnyObject = article.object(forKey: "customMeta") as AnyObject? {
            if metadata is NSDictionary {
                let metadataDict = NSMutableDictionary(dictionary: metadata as! NSDictionary)
                if let updated: Dictionary<String, AnyObject> = meta.object(forKey: "updated") as? Dictionary {
                    if let updateDate: String = updated["date"] as? String {
                        metadataDict.setObject(updateDate, forKey: "updateDate" as NSCopying)
                    }
                }
                currentArticle.metadata = Helper.stringFromJSON(metadataDict)!
            }
            else {
                currentArticle.metadata = metadata as! String
            }
        }
        
        let keywords = article.object(forKey: "keywords") as! NSArray
        if keywords.count > 0 {
            currentArticle.keywords = Helper.stringFromJSON(keywords)!
        }
        
        let issue = Issue()
        issue.assetFolder = "/Documents"
        
        //Add all assets of the article (will add images and sound)
        let articleMedia = article.object(forKey: "media") as! NSArray
        if articleMedia.count > 0 {
            var assetList = ""
            for (index, assetDict) in articleMedia.enumerated() {
                //Download images and create Asset object for issue
                let assetid = (assetDict as AnyObject).value(forKey: "id") as! String
                assetList += assetid
                if index < (articleMedia.count - 1) {
                    assetList += ","
                }
                if delegate != nil {
                    (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: currentArticle.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                }
                
                if index == 0 {
                    currentArticle.thumbImageURL = assetid
                }
            }
            Asset.downloadAndCreateAssetsForIds(assetList, issue: issue, articleId: currentArticle.globalId, delegate: delegate)
        }
        
        realm.beginWriteTransaction()
        realm.addOrUpdate(currentArticle)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error adding article: \(error)")
        }
        //realm.commitWriteTransaction()
        
        //Article downloaded (not necessarily assets)
        if delegate != nil {
            (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: currentArticle.globalId, url: "\(baseURL)articles/\(currentArticle.globalId)", status: 1)
        }
    }
    
    // MARK: Public methods
    
    /**
    This method accepts an issue's global id and deletes all articles from the database which belong to that issue
    
    :brief: Delete articles and assets for a specific issue
    
    - parameter  issueId: The global id of the issue whose articles have to be deleted
    */
    open class func deleteArticlesFor(_ issueId: NSString) {
        let realm = RLMRealm.default()
        
        let predicate = NSPredicate(format: "issueId = %@", issueId)
        let articles = Article.objects(with: predicate)
        
        let articleIds = NSMutableArray()
        //go through each article and delete all assets associated with it
        for article in articles {
            let article = article as! Article
            articleIds.add(article.globalId)
        }
        
        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete articles
        realm.beginWriteTransaction()
        realm.deleteObjects(articles)
        do {
            try realm.commitWriteTransaction()
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
    open class func getArticlesFor(_ issueId: NSString?, type: String?, excludeType: String?, count: Int, page: Int) -> Array<Article>? {
        _ = RLMRealm.default()
        
        var subPredicates = Array<NSPredicate>()
        
        if issueId != nil {
            let predicate = NSPredicate(format: "issueId = %@", issueId!)
            subPredicates.append(predicate)
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
            var articles: RLMResults<RLMObject>
            
            articles = Article.objects(with: searchPredicate).sortedResults(usingProperty: "date", ascending: false) as RLMResults
            
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
    This method accepts an issue's global id and the key and value for article search. It retrieves all articles which meet these conditions and returns them in an array.
    
    The key and value are needed. Other articles are optional. To ignore pagination, pass the count as 0
    
    - parameter  issueId: The global id of the issue whose articles have to be searched
    
    - parameter key: The key whose values need to be searched. Please ensure this has the same name as the properties available. The value can be any of the Article properties, keywords or customMeta keys
    
    - parameter value: The value of the key for the articles to be retrieved. If sending multiple keywords, use a comma-separated string with no spaces e.g. keyword1,keyword2,keyword3
    
    - parameter count: Number of articles to be returned
    
    - parameter page: Page number (will be used with count)
    
    :return: an array of articles fulfiling the conditions sorted by date
    */
    open class func getArticlesFor(_ issueId: NSString?, key: String, value: String, count: Int, page: Int) -> Array<Article>? {
        _ = RLMRealm.default()
        
        lLog("Articles for \(key) = \(value)")
        var subPredicates = Array<NSPredicate>()
        
        if issueId != nil {
            let predicate = NSPredicate(format: "issueId = %@", issueId!)
            subPredicates.append(predicate)
        }
        let testArticle = Article()
        let properties: NSArray = testArticle.objectSchema.properties as NSArray
        
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
                let keywords: [String] = value.components(separatedBy: ",")
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
            var articles: RLMResults<RLMObject>
            
            articles = Article.objects(with: searchPredicate).sortedResults(usingProperty: "date", ascending: false) as RLMResults
            
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
    open class func getArticle(_ articleId: String?, appleId: String?) -> Article? {
        _ = RLMRealm.default()
        
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

        let articles = Article.objects(with: predicate)
        
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
    open class func searchArticlesWith(_ keywords: [String], issueId: String?) -> Array<Article>? {
        _ = RLMRealm.default()
        
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
            let predicate = NSPredicate(format: "issueId = %@", issueId!)
            subPredicates.append(predicate)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            let articles: RLMResults = Article.objects(with: searchPredicate) as RLMResults
            
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
    open class func getFeaturedArticlesFor(_ issueId: NSString) -> Array<Article>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "issueId = %@ AND isFeatured == true", issueId)
        let articles: RLMResults = Article.objects(with: predicate) as RLMResults
        
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
    This method accepts a regular expression which should be used to identify placeholders for assets in an article body.
    The default asset pattern is `<!-- \\[ASSET: .+\\] -->`
    
    :brief: Change the asset pattern
    
    - parameter newPattern: The regex to identify pattern for asset placeholders
    */
    open class func setAssetPattern(_ newPattern: String) {
        assetPattern = newPattern
    }
    
    /**
    This method returns all articles whose publish date is before the published date provided
    
    - parameter date: The date to compare publish dates with
    
    :return: an array of articles older than the given date
    */
    open class func getOlderArticles(_ date: Date) -> Array<Article>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "date < %@", date as CVarArg)
        let articles: RLMResults = Article.objects(with: predicate) as RLMResults
        
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
    open class func getNewerArticles(_ date: Date) -> Array<Article>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "date > %@", date as CVarArg)
        let articles: RLMResults = Article.objects(with: predicate) as RLMResults
        
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
    open func refreshArticle(_ handler: IssueHandler?) {
        let realm = RLMRealm.default()
        let requestURL = "\(baseURL)articles/\(self.globalId)"
        let networkManager = LRNetworkManager.sharedInstance
        
        if handler != nil {
            if !self.issueId.isEmpty {
                handler!.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: "\(baseURL)issues/\(self.issueId)" as NSCopying), forKey: self.issueId as NSCopying)
                handler!.updateStatusDictionary("", issueId: self.issueId, url: requestURL, status: 0)
            }
            else {
                handler!.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: self.globalId as NSCopying)
                handler!.updateStatusDictionary("", issueId: self.globalId, url: requestURL, status: 0)
            }
        }
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.value(forKey: "articles") as! NSArray
                
                realm.beginWriteTransaction()
                
                let articleInfo = allArticles.firstObject as! NSDictionary
                //self.globalId = articleInfo.valueForKey("id") as! String
                self.title = articleInfo.value(forKey: "title") as! String
                self.body = articleInfo.value(forKey: "body") as! String
                self.articleDesc = articleInfo.value(forKey: "description") as! String
                self.authorName = articleInfo.value(forKey: "authorName") as! String
                self.authorURL = articleInfo.value(forKey: "authorUrl") as! String
                self.authorBio = articleInfo.value(forKey: "authorBio") as! String
                self.url = articleInfo.value(forKey: "sharingUrl") as! String
                self.section = articleInfo.value(forKey: "section") as! String
                self.articleType = articleInfo.value(forKey: "type") as! String
                self.commentary = articleInfo.value(forKey: "commentary") as! String
                self.slug = articleInfo.value(forKey: "slug") as! String
                
                let meta = articleInfo.object(forKey: "meta") as! NSDictionary
                let featured = meta.value(forKey: "featured") as! NSNumber
                self.isFeatured = featured.boolValue
                if let published = meta.value(forKey: "published") as? NSNumber {
                    self.isPublished = published.boolValue
                }
                
                if let publishedDate = meta.value(forKey: "publishedDate") as? String {
                    self.date = Helper.publishedDateFromISO2(publishedDate)
                }
                
                if let metadata: Any = articleInfo.object(forKey: "customMeta") {
                    if metadata is NSDictionary {
                        self.metadata = Helper.stringFromJSON(metadata as AnyObject)!
                    }
                    else {
                        self.metadata = metadata as! String
                    }
                }
                
                let keywords = articleInfo.object(forKey: "keywords") as! NSArray
                if keywords.count > 0 {
                    self.keywords = Helper.stringFromJSON(keywords)!
                }
                
                realm.addOrUpdate(self)
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
    
    open func deleteArticle() {
        let realm = RLMRealm.default()
        
        //Delete all assets for the article
        let articleIds = NSMutableArray()
        articleIds.add(self.globalId)
        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete article
        realm.beginWriteTransaction()
        realm.delete(self)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error deleting article: \(error)")
        }
        //realm.commitWriteTransaction()
    }
    
    
    /**
    This method downloads assets for the article
    */
    open func downloadArticleAssets(_ delegate: IssueHandler?) {
        lLog("Download assets for \(self.globalId)")
        let issueId = self.issueId
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        var assetFolder = docsDir as String
        
        var issue = Issue.getIssue(issueId)
        if issue == nil {
            issue = Issue()
            issue?.assetFolder = "/Documents"
        }
        else {
            let folder = issue?.assetFolder
            if folder!.hasPrefix("/Documents") {
            }
            else {
                assetFolder = folder!.replacingOccurrences(of: "/\(issue?.appleId)", with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
            }
        }
        
        let requestURL = "\(baseURL)articles/\(self.globalId)"
        
        var issueHandler: IssueHandler
        if delegate != nil {
            issueHandler = delegate!
        }
        else {
            issueHandler = IssueHandler(folder: assetFolder as NSString)!
            //issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: requestURL, status: 0)
            issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: self.globalId as NSCopying)
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.value(forKey: "articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                
                //Add all assets of the article
                let articleMedia = articleInfo.object(forKey: "media") as! NSArray
                if articleMedia.count > 0 {
                    var assetList = ""
                    for (index, assetDict) in articleMedia.enumerated() {
                        let assetDictionary = assetDict as! NSDictionary
                        //Download images and create Asset object for issue
                        let assetid = assetDictionary.value(forKey: "id") as! String
                        assetList += assetid
                        if index < (articleMedia.count - 1) {
                            assetList += ","
                        }
                        if delegate != nil {
                            issueHandler.updateStatusDictionary(nil, issueId: self.issueId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        else {
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                    }
                    Asset.downloadAndCreateAssetsForIds(assetList, issue: issue!, articleId: self.globalId, delegate: issueHandler)
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
    open func downloadFirstAsset(_ delegate: IssueHandler?) {
        lLog("Download first asset for \(self.globalId)")
        let issueId = self.issueId
        var docPaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        var assetFolder = docsDir as String
        
        var issue = Issue.getIssue(issueId)
        if issue == nil {
            issue = Issue()
            issue?.assetFolder = "/Documents"
        }
        else {
            let folder = issue?.assetFolder
            if folder!.hasPrefix("/Documents") {
            }
            else {
                assetFolder = folder!.replacingOccurrences(of: "/\(issue?.appleId)", with: "", options: NSString.CompareOptions.caseInsensitive, range: nil)
            }
        }
        
        let requestURL = "\(baseURL)articles/\(self.globalId)"
        
        var issueHandler: IssueHandler
        if delegate != nil {
            issueHandler = delegate!
        }
        else {
            issueHandler = IssueHandler(folder: assetFolder as NSString)!
            //issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: requestURL, status: 0)
            issueHandler.activeDownloads.setObject(NSDictionary(object: NSNumber(value: false as Bool) , forKey: requestURL as NSCopying), forKey: self.globalId as NSCopying)
        }
        
        if !self.thumbImageURL.isEmpty {
            if delegate != nil {
                issueHandler.updateStatusDictionary(nil, issueId: self.issueId, url: "\(baseURL)media/\(self.thumbImageURL)", status: 0)
            }
            else {
                issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(self.thumbImageURL)", status: 0)
            }
            Asset.downloadAndCreateAsset(self.thumbImageURL as NSString, issue: issue!, articleId: self.globalId as String, placement: 1, delegate: issueHandler)
            return
        }
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.value(forKey: "articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                
                //Add all assets of the article
                let articleMedia = articleInfo.object(forKey: "media") as! NSArray
                if articleMedia.count > 0 {
                    if let assetDict = articleMedia.firstObject {
                        let assetDictionary = assetDict as! NSDictionary
                        let assetid = assetDictionary.value(forKey: "id") as! String
                        
                        if delegate != nil {
                            issueHandler.updateStatusDictionary(nil, issueId: self.issueId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        else {
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        Asset.downloadAndCreateAsset(assetid as NSString, issue: issue!, articleId: self.globalId as String, placement: 1, delegate: issueHandler)
                    }
                }
                //issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)articles/\(self.globalId)", status: 1)
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
    open func saveArticle() {
        let realm = RLMRealm.default()
        
        realm.beginWriteTransaction()
        realm.addOrUpdate(self)
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
    open func replacePatternsWithAssets() -> NSString {
        //Should work for images, audio, video or any other types of assets
        let regex = try? NSRegularExpression(pattern: assetPattern, options: NSRegularExpression.Options.caseInsensitive)
        
        let articleBody = self.body
        
        var updatedBody: NSString = articleBody as NSString
        
        if let matches: [NSTextCheckingResult] = regex?.matches(in: articleBody, options: [], range: NSMakeRange(0, articleBody.characters.count)) {
            if matches.count > 0 {
                for match: NSTextCheckingResult in matches {
                    let matchRange = match.range
                    let range = NSRange(location: matchRange.location, length: matchRange.length)
                    var matchedString: NSString = (articleBody as NSString).substring(with: range) as NSString
                    let originallyMatched = matchedString
                    
                    //Get global id for the asset
                    for patternPart in assetPatternParts {
                        matchedString = matchedString.replacingOccurrences(of: patternPart, with: "", options: [], range: NSMakeRange(0, matchedString.length)) as NSString
                    }
                    
                    //Find asset with the global id
                    if let asset = Asset.getAsset(matchedString as String) {
                        //Use the asset - generate an HTML with the asset file URL (image, audio, video)
                        let originalAssetPath = asset.getAssetPath()
                        let fileURL: URL! = URL(fileURLWithPath: originalAssetPath!)
                        
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
                            
                            if updatedBody.substring(with: possibleMatchRange) == "<p>" {
                                updatedBody = updatedBody.replacingCharacters(in: possibleMatchRange, with: "") as NSString
                                finalHTML += "<p>"
                            }
                        }
                        
                        updatedBody = updatedBody.replacingOccurrences(of: originallyMatched as String, with: finalHTML) as NSString
                    }
                    else {
                        //Asset hasn't been downloaded yet (or record created)
                        updatedBody = updatedBody.replacingOccurrences(of: originallyMatched as String, with: "") as NSString
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
    open func getNewerArticles() -> Array<Article>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "issueId = %@ AND date > %@", self.issueId, self.date as CVarArg)
        let articles: RLMResults = Article.objects(with: predicate) as RLMResults
        
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
    open func getOlderArticles() -> Array<Article>? {
        _ = RLMRealm.default()
        
        let predicate = NSPredicate(format: "issueId = %@ AND date < %@", self.issueId, self.date as CVarArg)
        let articles: RLMResults = Article.objects(with: predicate) as RLMResults
        
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
    open func getValue(_ key: NSString) -> AnyObject? {
        
        let testArticle = Article()
        let properties: NSArray = testArticle.objectSchema.properties as NSArray
        
        var foundProperty = false
        for property: RLMProperty in properties as! [RLMProperty] {
            let propertyName = property.name
            if propertyName == key as String {
                //This is the property we are looking for
                foundProperty = true
                break
            }
        }
        if (foundProperty) {
            //Get value of this property and return
            return self.value(forKey: key as String) as AnyObject?
        }
        else {
            //This is a metadata key
            let metadata: AnyObject? = Helper.jsonFromString(self.metadata)
            if let metadataDict = metadata as? NSDictionary {
                return metadataDict.value(forKey: key as String) as AnyObject?
            }
        }
        
        return nil
    }

}
