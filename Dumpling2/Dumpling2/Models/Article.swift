//
//  Article.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
//import Realm

//Article object
class Article: RLMObject {
    dynamic var globalId = ""
    dynamic var title = ""
    dynamic var articleDesc = "" //description
    dynamic var slug = ""
    dynamic var dek = ""
    dynamic var body = ""
    dynamic var permalink = "" //keeping URLs as string - we might need to append parts to get the final
    dynamic var url = ""
    dynamic var sourceURL = ""
    dynamic var authorName = ""
    dynamic var authorURL = ""
    dynamic var section = ""
    dynamic var articleType = ""
    dynamic var keywords = ""
    dynamic var commentary = ""
    dynamic var metadata = ""
    dynamic var versionStashed = ""
    dynamic var placement = 0
    dynamic var mainImageURL = ""
    dynamic var thumbImageURL = ""
    dynamic var isFeatured = false
    dynamic var issueId = "" //globalId of issue
    
    override class func primaryKey() -> String {
        return "globalId"
    }
    
    //Delete articles and assets for a specific issue
    class func deleteArticlesFor(globalId: NSString) {
        let realm = RLMRealm.defaultRealm()
        
        let predicate = NSPredicate(format: "issueId = '%@'", globalId)
        var articles = Article.objectsWithPredicate(predicate)
        
        var articleIds = NSMutableArray()
        //go through each article and delete all assets associated with it
        for article in articles {
            let article = article as Article
            articleIds.addObject(article.globalId)
        }
        
        Asset.deleteAssetsForIssue(globalId)
        Asset.deleteAssetsForArticles(articleIds)
        
        //Delete articles
        realm.beginWriteTransaction()
        realm.deleteObjects(articles)
        realm.commitWriteTransaction()
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
    class func createArticleForId(articleId: NSString, issue: Issue, placement: Int) {
        let realm = RLMRealm.defaultRealm()
        
        let manager = AFHTTPRequestOperationManager()
        let authorization = "method=apikey,token=\(apiKey)"
        manager.requestSerializer.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        let requestURL = "\(baseURL)articles/\(articleId)"
        
        manager.GET(requestURL,
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                
                var response: NSDictionary = responseObject as NSDictionary
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
                        Asset.downloadAndCreateAsset(assetDict.valueForKey("id") as NSString, issue: issue, articleId: articleId, placement: index+1)
                    }
                }
                
                //Set thumbnail for article
                if let firstAsset = Asset.getFirstAssetFor(issue.globalId, articleId: articleId) {
                    currentArticle.thumbImageURL = firstAsset.originalURL as String
                }
                
                realm.beginWriteTransaction()
                realm.addOrUpdateObject(currentArticle)
                realm.commitWriteTransaction()
                
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                
                println("Error: " + error.localizedDescription)
        })
    }

}
