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
        } catch let error {
            NSLog("Error creating article: \(error)")
        }
    }
    
    //Get article details from API and create
    class func createArticleForId(articleId: NSString, issue: Issue, placement: Int, delegate: AnyObject?) {
        let realm = RLMRealm.defaultRealm()
        
        let requestURL = "\(baseURL)articles/\(articleId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
                let articleInfo: NSDictionary = allArticles.firstObject as! NSDictionary
                
                let currentArticle = Article()
                currentArticle.globalId = articleId as String
                currentArticle.placement = placement
                currentArticle.issueId = issue.globalId
                currentArticle.title = articleInfo.valueForKey("title") as! String
                currentArticle.body = articleInfo.valueForKey("body") as! String
                currentArticle.articleDesc = articleInfo.valueForKey("description") as! String
                currentArticle.authorName = articleInfo.valueForKey("authorName") as! String
                currentArticle.authorURL = articleInfo.valueForKey("authorUrl") as! String
                currentArticle.url = articleInfo.valueForKey("sharingUrl") as! String
                currentArticle.section = articleInfo.valueForKey("section") as! String
                currentArticle.articleType = articleInfo.valueForKey("type") as! String
                currentArticle.commentary = articleInfo.valueForKey("commentary") as! String
                currentArticle.slug = articleInfo.valueForKey("slug") as! String
                
                if let sku = articleInfo.valueForKey("sku") as? String {
                    currentArticle.appleId = sku
                }
                
                let meta = articleInfo.objectForKey("meta") as! NSDictionary
                let featured = meta.valueForKey("featured") as! NSNumber
                currentArticle.isFeatured = featured.boolValue
                if let published = meta.valueForKey("published") as? NSNumber {
                    currentArticle.isPublished = published.boolValue
                }
                
                if let publishedDate = meta.valueForKey("publishedDate") as? String {
                    currentArticle.date = Helper.publishedDateFromISO2(publishedDate)
                }//For Gothamist
                /*var updated = meta.valueForKey("updated") as! NSDictionary
                if let updateDate: String = updated.valueForKey("date") as? String {
                    currentArticle.date = Helper.publishedDateFromISO(updateDate)
                }*/
                
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
                    for (index, assetDict) in articleMedia.enumerate() {
                        //Download images and create Asset object for issue
                        let assetid = assetDict.valueForKey("id") as! NSString
                        //TODO: TEST
                        /*if delegate != nil {
                            (delegate as! IssueHandler).updateStatusDictionary(issue.volumeId, issueId: issue.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        Asset.downloadAndCreateAsset(assetid, issue: issue, articleId: articleId as String, placement: index+1, delegate: delegate)*/
                        
                        if index == 0 {
                            currentArticle.thumbImageURL = assetid as String
                        }
                    }
                }
                
                //Set thumbnail for article
                if let firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: articleId as String, volumeId: nil) {
                    currentArticle.thumbImageURL = firstAsset.globalId as String
                }
                
                realm.beginWriteTransaction()
                realm.addOrUpdateObject(currentArticle)
                do {
                    try realm.commitWriteTransaction()
                } catch let error {
                    NSLog("Error creating article: \(error)")
                }
                
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
        } catch let error {
            NSLog("Error deleting articles for issues: \(error)")
        }
    }
    
    /**
    This method accepts an article's global id, gets its details from Magnet API and adds it to the database.
    
    :brief: Get Article from API and add to the database
    
    - parameter  articleId: The global id for the article
    
    - parameter delegate: Used to update the status of article download
    */
    class func createIndependentArticle(articleId: String, delegate: AnyObject?) {
        let requestURL = "\(baseURL)articles/\(articleId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
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
    class func createArticle(articleId: String, issueId: String, delegate: AnyObject?) {
        let requestURL = "\(baseURL)articles/\(articleId)"
        
        let networkManager = LRNetworkManager.sharedInstance
        
        networkManager.requestData("GET", urlString: requestURL) {
            (data:AnyObject?, error:NSError?) -> () in
            if data != nil {
                let response: NSDictionary = data as! NSDictionary
                let allArticles: NSArray = response.valueForKey("articles") as! NSArray
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
    class func addArticle(article: NSDictionary, delegate: AnyObject?) {
        let realm = RLMRealm.defaultRealm()
        
        let currentArticle = Article()
        currentArticle.globalId = article.valueForKey("id") as! String
        currentArticle.title = article.valueForKey("title") as! String
        currentArticle.body = article.valueForKey("body") as! String
        currentArticle.articleDesc = article.valueForKey("description") as! String
        currentArticle.authorName = article.valueForKey("authorName") as! String
        currentArticle.authorURL = article.valueForKey("authorUrl") as! String
        currentArticle.url = article.valueForKey("sharingUrl") as! String
        currentArticle.section = article.valueForKey("section") as! String
        currentArticle.articleType = article.valueForKey("type") as! String
        currentArticle.commentary = article.valueForKey("commentary") as! String
        currentArticle.slug = article.valueForKey("slug") as! String
        
        if let sku = article.valueForKey("sku") as? String {
            currentArticle.appleId = sku
        }
        
        let meta = article.objectForKey("meta") as! NSDictionary
        let featured = meta.valueForKey("featured") as! NSNumber
        currentArticle.isFeatured = featured.boolValue
        if let published = meta.valueForKey("published") as? NSNumber {
            currentArticle.isPublished = published.boolValue
        }
        
        if let publishedDate = meta.valueForKey("publishedDate") as? String {
            currentArticle.date = Helper.publishedDateFromISO2(publishedDate)
        } //For Gothamist

        /*var updated = meta.valueForKey("updated") as! NSDictionary
        if let updateDate: String = updated.valueForKey("date") as? String {
            currentArticle.date = Helper.publishedDateFromISO(updateDate)
        }*/
        
        if let metadata: AnyObject = article.objectForKey("customMeta") {
            if metadata.isKindOfClass(NSDictionary) {
                currentArticle.metadata = Helper.stringFromJSON(metadata)!
            }
            else {
                currentArticle.metadata = metadata as! String
            }
        }
        
        let keywords = article.objectForKey("keywords") as! NSArray
        if keywords.count > 0 {
            currentArticle.keywords = Helper.stringFromJSON(keywords)!
        }
        
        let issue = Issue()
        issue.assetFolder = "/Documents"
        
        //Add all assets of the article (will add images and sound)
        let articleMedia = article.objectForKey("media") as! NSArray
        if articleMedia.count > 0 {
            for (index, assetDict) in articleMedia.enumerate() {
                //Download images and create Asset object for issue
                let assetid = assetDict.valueForKey("id") as! NSString
                if delegate != nil {
                    (delegate as! IssueHandler).updateStatusDictionary(nil, issueId: currentArticle.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                }
                Asset.downloadAndCreateAsset(assetDict.valueForKey("id") as! NSString, issue: issue, articleId: currentArticle.globalId, placement: index+1, delegate: delegate)
                
                if index == 0 {
                    currentArticle.thumbImageURL = assetDict.valueForKey("id") as! String
                }
            }
        }
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(currentArticle)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error adding article: \(error)")
        }
        
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
    public class func deleteArticlesFor(issueId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId = %@", issueId)
        let articles = Article.objectsWithPredicate(predicate)
        
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
        } catch let error {
            NSLog("Error deleting articles: \(error)")
        }
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
        _ = RLMRealm.defaultRealm()
        
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
        
        var subPredicates = Array<NSPredicate>()
        
        if issueId != nil {
            let predicate = NSPredicate(format: "issueId = %@", issueId!)
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
        
        let predicate = NSPredicate(format: "issueId = %@ AND isFeatured == true", issueId)
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
        } catch let error {
            NSLog("Error deleting article: \(error)")
        }
    }
    
    
    /**
    This method downloads assets for the article
    */
    public func downloadArticleAssets(delegate: IssueHandler?) {
        let issueId = self.issueId
        var docPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir: NSString = docPaths[0] as NSString
        var assetFolder = docsDir as String
        
        var issue = Issue.getIssue(issueId)
        if issue == nil {
            issue = Issue()
            issue?.assetFolder = assetFolder
        }
        else {
            let folder = issue?.assetFolder
            if folder!.hasPrefix("/Documents") {
            }
            else {
                assetFolder = folder!.stringByReplacingOccurrencesOfString("/\(issue?.appleId)", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
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
                    for (index, assetDict) in articleMedia.enumerate() {
                        //Download images and create Asset object for issue
                        let assetid = assetDict.valueForKey("id") as! NSString
                        
                        if delegate != nil {
                            issueHandler.updateStatusDictionary(nil, issueId: self.issueId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        else {
                            issueHandler.updateStatusDictionary(nil, issueId: self.globalId, url: "\(baseURL)media/\(assetid)", status: 0)
                        }
                        Asset.downloadAndCreateAsset(assetid, issue: issue!, articleId: self.globalId as String, placement: index+1, delegate: issueHandler)
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
    public func saveArticle() {
        let realm = RLMRealm.defaultRealm()
        
        realm.beginWriteTransaction()
        realm.addOrUpdateObject(self)
        do {
            try realm.commitWriteTransaction()
        } catch let error {
            NSLog("Error saving article: \(error)")
        }
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
        
        let predicate = NSPredicate(format: "issueId = %@ AND date > %@", self.issueId, self.date)
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
        
        let predicate = NSPredicate(format: "issueId = %@ AND date < %@", self.issueId, self.date)
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
