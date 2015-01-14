//
//  Article.swift
//  Dumpling2
//
//  Created by Lata Rastogi on 30/12/14.
//  Copyright (c) 2014 29th Street. All rights reserved.
//

import UIKit
import Realm

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
    
    //Is article featured
    class func isArticleFeatured(issue: Issue, placement: Int) -> Bool{
        let globalId = issue.globalId
        //TODO: Needs to be implemented
        return false
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

}
