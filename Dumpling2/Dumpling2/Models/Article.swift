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

//Article object
public class Article: RLMObject {
    dynamic public var globalId = ""
    dynamic public var title = ""
    dynamic public var articleDesc = "" //description
    dynamic public var slug = ""
    dynamic public var dek = ""
    dynamic public var body = ""
    dynamic public var permalink = "" //keeping URLs as string - we might need to append parts to get the final
    dynamic public var url = ""
    dynamic public var sourceURL = ""
    dynamic public var authorName = ""
    dynamic public var authorURL = ""
    dynamic public var section = ""
    dynamic public var articleType = ""
    dynamic public var keywords = ""
    dynamic public var commentary = ""
    dynamic public var date = NSDate()
    dynamic public var metadata = ""
    dynamic public var versionStashed = ""
    dynamic public var placement = 0
    dynamic public var mainImageURL = ""
    dynamic public var thumbImageURL = ""
    dynamic public var isFeatured = false
    dynamic var issueId = "" //globalId of issue, can be blank for independent articles
    
    override public class func primaryKey() -> String {
        return "globalId"
    }
    
    //Add article
    class func createArticle(article: NSDictionary, issue: Issue, placement: Int) {
        let realm = RLMRealm.defaultRealm()
        
        var currentArticle = Article()
        currentArticle.globalId = article.objectForKey("global_id") as String
        currentArticle.title = article.objectForKey("title") as String
        currentArticle.body = article.objectForKey("body") as String
        currentArticle.articleDesc = article.objectForKey("description") as String
        currentArticle.url = article.objectForKey("url") as String
        currentArticle.section = article.objectForKey("section") as String
        currentArticle.authorName = article.objectForKey("author_name") as String
        currentArticle.sourceURL = article.objectForKey("source") as String
        currentArticle.dek = article.objectForKey("dek") as String
        currentArticle.authorURL = article.objectForKey("author_url") as String
        currentArticle.keywords = article.objectForKey("keywords") as String
        currentArticle.commentary = article.objectForKey("commentary") as String
        currentArticle.articleType = article.objectForKey("type") as String
        
        var updateDate = article.objectForKey("date_last_updated") as String
        if updateDate != "" {
            currentArticle.date = Helper.publishedDateFromISO(updateDate)
        }
        
        var metadata: AnyObject! = article.objectForKey("metadata")
        if metadata.isKindOfClass(NSDictionary) {
            currentArticle.metadata = Helper.stringFromJSON(metadata)! //metadata.JSONString()!
        }
        else {
            currentArticle.metadata = metadata as String
        }
        
        currentArticle.issueId = issue.globalId
        currentArticle.placement = placement
        currentArticle.versionStashed = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey) as String
        
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
                for (index, imageDict) in enumerate(orderedArray) {
                    Asset.createAsset(imageDict as NSDictionary, issue: issue, articleId: currentArticle.globalId, placement: index+1)
                }
            }
        }
        
        //Set thumbnail for article
        if let firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: currentArticle.globalId) {
            currentArticle.thumbImageURL = firstAsset.squareURL as String
        }
        
        //Insert article sound files
        if let orderedArray = article.objectForKey("sound_files")?.objectForKey("ordered") as? NSArray {
            if orderedArray.count > 0 {
                for (index, soundDict) in enumerate(orderedArray) {
                    Asset.createAsset(soundDict as NSDictionary, issue: issue, articleId: currentArticle.globalId, sound: true, placement: index+1)
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(currentArticle)
        realm.commitWriteTransaction()
    }
    
    //Get article details from API and create
    class func createArticleForId(articleId: NSString, issue: Issue, placement: Int, delegate: AnyObject?) {
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)articles/\(articleId)"
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as NSDictionary
                var allArticles: NSArray = response.valueForKey("articles") as NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as NSDictionary
                
                var currentArticle = Article()
                currentArticle.globalId = articleId
                currentArticle.placement = placement
                currentArticle.issueId = issue.globalId
                currentArticle.title = articleInfo.valueForKey("title") as String
                currentArticle.body = articleInfo.valueForKey("body") as String
                currentArticle.articleDesc = articleInfo.valueForKey("description") as String
                currentArticle.authorName = articleInfo.valueForKey("authorName") as String
                currentArticle.authorURL = articleInfo.valueForKey("authorUrl") as String
                currentArticle.url = articleInfo.valueForKey("sharingUrl") as String
                currentArticle.section = articleInfo.valueForKey("section") as String
                currentArticle.articleType = articleInfo.valueForKey("type") as String
                currentArticle.commentary = articleInfo.valueForKey("commentary") as String
                currentArticle.slug = articleInfo.valueForKey("slug") as String
                
                var meta = articleInfo.objectForKey("meta") as NSDictionary
                var featured = meta.valueForKey("featured") as NSNumber
                currentArticle.isFeatured = featured.boolValue
                
                var updated = meta.valueForKey("updated") as NSDictionary
                if let updateDate: String = updated.valueForKey("date") as? String {
                    currentArticle.date = Helper.publishedDateFromISO(updateDate)
                }
                
                if let metadata: AnyObject = articleInfo.objectForKey("customMeta") {
                    if metadata.isKindOfClass(NSDictionary) {
                        currentArticle.metadata = Helper.stringFromJSON(metadata)!
                    }
                    else {
                        currentArticle.metadata = metadata as String
                    }
                }
                
                var keywords = articleInfo.objectForKey("keywords") as NSArray
                if keywords.count > 0 {
                    currentArticle.keywords = Helper.stringFromJSON(keywords)!
                }
                
                //Add all assets of the article (will add images and sound)
                var articleMedia = articleInfo.objectForKey("media") as NSArray
                if articleMedia.count > 0 {
                    for (index, assetDict) in enumerate(articleMedia) {
                        //Download images and create Asset object for issue
                        Asset.downloadAndCreateAsset(assetDict.valueForKey("id") as NSString, issue: issue, articleId: articleId, placement: index+1, delegate: delegate)
                    }
                }
                
                //Set thumbnail for article
                if let firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: articleId) {
                    currentArticle.thumbImageURL = firstAsset.originalURL as String
                }
                
                realm.beginWriteTransaction()
                realm.addOrUpdateObject(currentArticle)
                realm.commitWriteTransaction()
                
                if delegate != nil {
                    //Mark article as done
                    (delegate as IssueHandler).updateStatusDictionary(issue.globalId, url: requestURL, status: 1)
                }
            }
            else if let err = error {
                println("Error: " + err.description)
                if delegate != nil {
                    //Mark article as done - even if with errors
                    (delegate as IssueHandler).updateStatusDictionary(issue.globalId, url: requestURL, status: 2)
                }
            }
            
        }
    }
    
    // MARK: Public methods
    
    //MARK: Class methods
    
    //Get Article from API and add to Realm
    public class func createIndependentArticle(articleId: String) {
        let requestURL = "\(baseURL)articles/\(articleId)"
        
        var networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                var response: NSDictionary = data as NSDictionary
                var allArticles: NSArray = response.valueForKey("articles") as NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as NSDictionary
                
                self.addArticle(articleInfo)
                
            }
            else if let err = error {
                println("Error: " + err.description)
            }
        }
    }
    
    //Create article not associated with any issue
    //The structure expected for the dictionary is the same as currently used in Magnet
    //Images will be stored in Documents folder by default for such articles
    class func addArticle(article: NSDictionary) {
        let realm = RLMRealm.defaultRealm()
        
        var currentArticle = Article()
        currentArticle.globalId = article.valueForKey("id") as String
        currentArticle.title = article.valueForKey("title") as String
        currentArticle.body = article.valueForKey("body") as String
        currentArticle.articleDesc = article.valueForKey("description") as String
        currentArticle.authorName = article.valueForKey("authorName") as String
        currentArticle.authorURL = article.valueForKey("authorUrl") as String
        currentArticle.url = article.valueForKey("sharingUrl") as String
        currentArticle.section = article.valueForKey("section") as String
        currentArticle.articleType = article.valueForKey("type") as String
        currentArticle.commentary = article.valueForKey("commentary") as String
        currentArticle.slug = article.valueForKey("slug") as String
        
        var meta = article.objectForKey("meta") as NSDictionary
        var featured = meta.valueForKey("featured") as NSNumber
        currentArticle.isFeatured = featured.boolValue
        
        var updated = meta.valueForKey("updated") as NSDictionary
        if let updateDate: String = updated.valueForKey("date") as? String {
            currentArticle.date = Helper.publishedDateFromISO(updateDate)
        }
        
        if let metadata: AnyObject = article.objectForKey("customMeta") {
            if metadata.isKindOfClass(NSDictionary) {
                currentArticle.metadata = Helper.stringFromJSON(metadata)!
            }
            else {
                currentArticle.metadata = metadata as String
            }
        }
        
        var keywords = article.objectForKey("keywords") as NSArray
        if keywords.count > 0 {
            currentArticle.keywords = Helper.stringFromJSON(keywords)!
        }
        
        var issue = Issue()
        
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var cacheDir: NSString = docPaths[0] as NSString
        issue.assetFolder = cacheDir
        
        //Add all assets of the article (will add images and sound)
        var articleMedia = article.objectForKey("media") as NSArray
        if articleMedia.count > 0 {
            for (index, assetDict) in enumerate(articleMedia) {
                //Download images and create Asset object for issue
                Asset.downloadAndCreateAsset(assetDict.valueForKey("id") as NSString, issue: issue, articleId: currentArticle.globalId, placement: index+1, delegate: nil)
            }
        }
        
        //Set thumbnail for article
        if let firstAsset = Asset.getFirstAssetFor("", articleId: currentArticle.globalId) {
            currentArticle.thumbImageURL = firstAsset.originalURL as String
        }
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(currentArticle)
        realm.commitWriteTransaction()
    }
    
    //Delete articles and assets for a specific issue
    public class func deleteArticlesFor(issueId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId = '%@'", issueId)
        var articles = Article.objectsWithPredicate(predicate)
        
        var articleIds = NSMutableArray()
        //go through each article and delete all assets associated with it
        for article in articles {
            let article = article as Article
            articleIds.addObject(article.globalId)
        }
        
        //Asset.deleteAssetsForIssue(issueId)
        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete articles
        realm.beginWriteTransaction()
        realm.deleteObjects(articles)
        realm.commitWriteTransaction()
    }
    
    //Get all articles for any issue (or if nil, all issues)
    //Articles for only a specific type (optional)
    //Articles excluding a specific type (optional) - all params can be used in conjunction
    //At least one of the params is needed
    public class func getArticlesFor(issueId: NSString?, type: String?, excludeType: String?) -> NSArray? {
        let realm = RLMRealm.defaultRealm()
        
        var subPredicates = NSMutableArray()
        
        if issueId != nil {
            var predicate = NSPredicate(format: "issueId = '%@'", issueId!)
            subPredicates.addObject(predicate!)
        }
        
        if type != nil {
            var typePredicate = NSPredicate(format: "articleType = '%@'", type!)
            subPredicates.addObject(typePredicate!)
        }
        if excludeType != nil {
            var excludePredicate = NSPredicate(format: "articleType != '%@'", excludeType!)
            subPredicates.addObject(excludePredicate!)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate.andPredicateWithSubpredicates(subPredicates)
            var articles: RLMResults = Article.objectsWithPredicate(searchPredicate) as RLMResults
            
            if articles.count > 0 {
                var array = NSMutableArray()
                for object in articles {
                    let obj: Article = object as Article
                    array.addObject(obj)
                }
                return array
            }
        }
        
        return nil
    }
    
    //Get all articles for an issue (or if nil, all issues) with specific keywords
    public class func searchArticlesWith(keywords: [String], issueId: String?) -> NSArray? {
        let realm = RLMRealm.defaultRealm()
        
        var subPredicates = NSMutableArray()
        
        for keyword in keywords {
            var subPredicate = NSPredicate(format: "keywords CONTAINS '%@'", keyword)
            subPredicates.addObject(subPredicate!)
        }
        
        var orPredicate = NSCompoundPredicate.orPredicateWithSubpredicates(subPredicates)
        
        subPredicates.removeAllObjects()
        subPredicates.addObject(orPredicate)
        
        if issueId != nil {
            var predicate = NSPredicate(format: "issueId = '%@'", issueId!)
            subPredicates.addObject(predicate!)
        }
        
        if subPredicates.count > 0 {
            let searchPredicate = NSCompoundPredicate.andPredicateWithSubpredicates(subPredicates)
            var articles: RLMResults = Article.objectsWithPredicate(searchPredicate) as RLMResults
            
            if articles.count > 0 {
                var array = NSMutableArray()
                for object in articles {
                    let obj: Article = object as Article
                    array.addObject(obj)
                }
                return array
            }
        }
        
        return nil
    }
    
    //Get all  featured articles for a specific issue
    public class func getFeaturedArticlesFor(issueId: NSString) -> NSArray? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId = '%@' AND isFeatured = true", issueId)
        var articles: RLMResults = Article.objectsWithPredicate(predicate) as RLMResults
        
        if articles.count > 0 {
            var array = NSMutableArray()
            for object in articles {
                let obj: Article = object as Article
                array.addObject(obj)
            }
            return array
        }
        
        return nil
    }
    
    //Change the asset pattern
    public class func setAssetPattern(newPattern: String) {
        assetPattern = newPattern
    }
    
    //MARK: Instance methods
    //Replace asset pattern with actual assets in an Article body
    public func replacePatternsWithAssets() -> NSString {
        //Should work for images, audio, video or any other types of assets
        var regex = NSRegularExpression(pattern: assetPattern, options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
        
        var articleBody = self.body
        var matches = regex?.matchesInString(articleBody, options: nil, range: NSMakeRange(0, articleBody.utf16Count)) as Array<NSTextCheckingResult>
        
        var updatedBody: NSString = articleBody
        
        if matches.count > 0 {
            for match: NSTextCheckingResult in matches {
                let matchRange = match.range
                var range = NSRange(location: matchRange.location, length: matchRange.length)
                var matchedString: NSString = (articleBody as NSString).substringWithRange(range) as NSString
                var originallyMatched = matchedString
                
                //Get global id for the asset
                for patternPart in assetPatternParts {
                    matchedString = matchedString.stringByReplacingOccurrencesOfString(patternPart, withString: "", options: nil, range: NSMakeRange(0, matchedString.length))
                }
                
                //Find asset with the global id
                if let asset = Asset.getAsset(matchedString) {
                    //Use the asset - generate an HTML with the asset file URL (image, audio, video)
                    var originalAssetPath = asset.originalURL
                    var fileURL = NSURL(fileURLWithPath: originalAssetPath)
                    
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
                    if matchRange.location >= 3 && articleBody.utf16Count > 3 {
                        var possibleMatchRange = NSMakeRange(matchRange.location - 3, 3)
                        
                        if updatedBody.substringWithRange(possibleMatchRange) == "<p>" {
                            updatedBody = updatedBody.stringByReplacingCharactersInRange(possibleMatchRange, withString: "")
                            finalHTML += "<p>"
                        }
                    }
                    
                    updatedBody = updatedBody.stringByReplacingOccurrencesOfString(originallyMatched, withString: finalHTML)
                }
            }
        }
        
        return updatedBody
    }
    
    
    //Get all articles newer than a specific article
    public func getNewerArticles() -> NSArray? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId = '%@' AND date > %@", self.issueId, self.date)
        var articles: RLMResults = Article.objectsWithPredicate(predicate) as RLMResults
        
        if articles.count > 0 {
            var array = NSMutableArray()
            for object in articles {
                let obj: Article = object as Article
                array.addObject(obj)
            }
            return array
        }
        
        return nil
    }
    
    //Get all articles older than a specific article
    public func getOlderArticles() -> NSArray? {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId = '%@' AND date < %@", self.issueId, self.date)
        var articles: RLMResults = Article.objectsWithPredicate(predicate) as RLMResults
        
        if articles.count > 0 {
            var array = NSMutableArray()
            for object in articles {
                let obj: Article = object as Article
                array.addObject(obj)
            }
            return array
        }
        
        return nil
    }
    
    //Get details for a specific key from custom meta of an article
    public func getValue(key: NSString) -> AnyObject? {
        
        var metadata: AnyObject? = Helper.jsonFromString(self.metadata)
        if let metadataDict = metadata as? NSDictionary {
            return metadataDict.valueForKey(key)
        }
        
        return nil
    }

}
